module NoInvalidTypesInToBackend exposing (rule)

{-| Forbids `ToBackend` from referencing a set of disallowed types, either
directly or indirectly through other types.

@docs rule

-}

import Dict exposing (Dict)
import Elm.Syntax.Declaration as Declaration exposing (Declaration)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Range exposing (Range)
import Elm.Syntax.TypeAnnotation as TypeAnnotation exposing (TypeAnnotation)
import Review.ModuleNameLookupTable as ModuleNameLookupTable exposing (ModuleNameLookupTable)
import Review.Rule as Rule exposing (ModuleKey, Rule)
import Set exposing (Set)


{-| Reports when the `ToBackend` type references one of the `disallowed` types,
directly or through any chain of other types.

    config =
        [ NoInvalidTypesInToBackend.rule
            { disallowed = [ ( [ "Basics" ], "Float" ) ]
            , exempt = []
            }
        ]

Types are identified by their canonical module name and name. For example
`Float` lives in `Basics`, so it is `( [ "Basics" ], "Float" )`, and a project
type `Coord` defined in `Geometry` is `( [ "Geometry" ], "Coord" )`.

`exempt` is a list of types that are skipped during the traversal. When the
traversal reaches an exempt type it stops, so a disallowed type only reachable
through that type is ignored:

    config =
        [ NoInvalidTypesInToBackend.rule
            { disallowed = [ ( [ "Basics" ], "Float" ) ]
            , exempt = [ ( [ "SafeJson" ], "SafeJson" ) ]
            }
        ]

When a disallowed type is found the error shows the path that leads to it, for
example `ToBackend -> ServerChange -> Coord -> Float`.

-}
rule :
    { disallowed : List ( ModuleName, String )
    , unlessWrappedIn : List ( ModuleName, String )
    }
    -> Rule
rule config =
    let
        disallowed : Set ( ModuleName, String )
        disallowed =
            Set.fromList config.disallowed

        exempt : Set ( ModuleName, String )
        exempt =
            Set.fromList config.unlessWrappedIn
    in
    Rule.newProjectRuleSchema "NoInvalidTypesInToBackend" initialContext
        |> Rule.withModuleVisitor moduleVisitor
        |> Rule.withModuleContextUsingContextCreator conversion
        |> Rule.withFinalProjectEvaluation (finalProjectEvaluation disallowed exempt)
        |> Rule.fromProjectRuleSchema


type alias TypeInfo =
    { references : List ( ModuleName, String )
    , range : Range
    , key : ModuleKey
    }


type alias ProjectContext =
    { types : Dict ( ModuleName, String ) TypeInfo
    }


type alias ModuleContext =
    { moduleName : ModuleName
    , moduleKey : ModuleKey
    , lookupTable : ModuleNameLookupTable
    , types : Dict ( ModuleName, String ) TypeInfo
    }


initialContext : ProjectContext
initialContext =
    { types = Dict.empty }


conversion :
    { fromProjectToModule : Rule.ContextCreator ProjectContext ModuleContext
    , fromModuleToProject : Rule.ContextCreator ModuleContext ProjectContext
    , foldProjectContexts : ProjectContext -> ProjectContext -> ProjectContext
    }
conversion =
    { fromProjectToModule =
        Rule.initContextCreator
            (\moduleName moduleKey lookupTable _ ->
                { moduleName = moduleName
                , moduleKey = moduleKey
                , lookupTable = lookupTable
                , types = Dict.empty
                }
            )
            |> Rule.withModuleName
            |> Rule.withModuleKey
            |> Rule.withModuleNameLookupTable
    , fromModuleToProject =
        Rule.initContextCreator (\moduleContext -> { types = moduleContext.types })
    , foldProjectContexts =
        \l r -> { types = Dict.union l.types r.types }
    }


moduleVisitor :
    Rule.ModuleRuleSchema {} ModuleContext
    -> Rule.ModuleRuleSchema { hasAtLeastOneVisitor : () } ModuleContext
moduleVisitor visitor =
    visitor
        |> Rule.withDeclarationEnterVisitor declarationVisitor


declarationVisitor : Node Declaration -> ModuleContext -> ( List (Rule.Error {}), ModuleContext )
declarationVisitor (Node _ declaration) context =
    case declaration of
        Declaration.CustomTypeDeclaration customType ->
            let
                references : List ( ModuleName, String )
                references =
                    customType.constructors
                        |> List.concatMap
                            (\(Node _ constructor) ->
                                List.concatMap (collectTargets context) constructor.arguments
                            )
            in
            ( [], insertType customType.name references context )

        Declaration.AliasDeclaration typeAlias ->
            ( []
            , insertType
                typeAlias.name
                (collectTargets context typeAlias.typeAnnotation)
                context
            )

        _ ->
            ( [], context )


insertType : Node String -> List ( ModuleName, String ) -> ModuleContext -> ModuleContext
insertType (Node nameRange name) references context =
    { context
        | types =
            Dict.insert
                ( context.moduleName, name )
                { references = references, range = nameRange, key = context.moduleKey }
                context.types
    }


{-| Collects the canonical name of every type referenced by a type annotation.
Type arguments are flattened in, so `List Coord` references both `List` and
`Coord`.
-}
collectTargets : ModuleContext -> Node TypeAnnotation -> List ( ModuleName, String )
collectTargets context node =
    case Node.value node of
        TypeAnnotation.GenericType _ ->
            []

        TypeAnnotation.Typed (Node range ( rawModuleName, name )) arguments ->
            let
                target : ( ModuleName, String )
                target =
                    case ModuleNameLookupTable.moduleNameAt context.lookupTable range of
                        -- An empty module name means the type is defined in the current module.
                        Just [] ->
                            ( context.moduleName, name )

                        Just moduleName ->
                            ( moduleName, name )

                        Nothing ->
                            ( rawModuleName, name )
            in
            target :: List.concatMap (collectTargets context) arguments

        TypeAnnotation.Unit ->
            []

        TypeAnnotation.Tupled nodes ->
            List.concatMap (collectTargets context) nodes

        TypeAnnotation.Record fields ->
            List.concatMap (\(Node _ ( _, field )) -> collectTargets context field) fields

        TypeAnnotation.GenericRecord _ (Node _ fields) ->
            List.concatMap (\(Node _ ( _, field )) -> collectTargets context field) fields

        TypeAnnotation.FunctionTypeAnnotation a b ->
            collectTargets context a ++ collectTargets context b


finalProjectEvaluation :
    Set ( ModuleName, String )
    -> Set ( ModuleName, String )
    -> ProjectContext
    -> List (Rule.Error { useErrorForModule : () })
finalProjectEvaluation disallowed exempt context =
    context.types
        |> Dict.toList
        |> List.filterMap
            (\( key, info ) ->
                if Tuple.second key == "ToBackend" then
                    findDisallowedPath disallowed exempt context.types key
                        |> Maybe.map (\path -> toError info path)

                else
                    Nothing
            )


toError : TypeInfo -> List String -> Rule.Error { useErrorForModule : () }
toError info path =
    Rule.errorForModule info.key
        { message = "Found a disallowed type referenced by ToBackend"
        , details =
            [ "ToBackend references a type that this rule disallows, either directly or indirectly through other types."
            , "Path: " ++ String.join " -> " path
            ]
        }
        info.range


{-| Breadth first search from `ToBackend` to the nearest disallowed type.
Returns the path of type names leading to it (ending with the disallowed type),
e.g. `[ "ToBackend", "ServerChange", "Coord", "Float" ]`.
-}
findDisallowedPath :
    Set ( ModuleName, String )
    -> Set ( ModuleName, String )
    -> Dict ( ModuleName, String ) TypeInfo
    -> ( ModuleName, String )
    -> Maybe (List String)
findDisallowedPath disallowed exempt types start =
    if Set.member start exempt then
        Nothing

    else
        bfs disallowed exempt types [ ( start, [ Tuple.second start ] ) ] (Set.singleton start)


bfs :
    Set ( ModuleName, String )
    -> Set ( ModuleName, String )
    -> Dict ( ModuleName, String ) TypeInfo
    -> List ( ( ModuleName, String ), List String )
    -> Set ( ModuleName, String )
    -> Maybe (List String)
bfs disallowed exempt types queue visited =
    case queue of
        [] ->
            Nothing

        ( key, path ) :: rest ->
            case Dict.get key types of
                Nothing ->
                    bfs disallowed exempt types rest visited

                Just info ->
                    case disallowedHit disallowed exempt info.references of
                        Just hit ->
                            Just (path ++ [ Tuple.second hit ])

                        Nothing ->
                            let
                                ( newQueue, newVisited ) =
                                    info.references
                                        |> List.foldl
                                            (\next ( q, v ) ->
                                                if Set.member next v || Set.member next exempt then
                                                    ( q, v )

                                                else
                                                    ( q ++ [ ( next, path ++ [ Tuple.second next ] ) ]
                                                    , Set.insert next v
                                                    )
                                            )
                                            ( rest, visited )
                            in
                            bfs disallowed exempt types newQueue newVisited


{-| Finds the first reference that is disallowed and not exempt. Exempt wins, so
a type that is both disallowed and exempt is ignored.
-}
disallowedHit :
    Set ( ModuleName, String )
    -> Set ( ModuleName, String )
    -> List ( ModuleName, String )
    -> Maybe ( ModuleName, String )
disallowedHit disallowed exempt references =
    references
        |> List.filter (\target -> Set.member target disallowed && not (Set.member target exempt))
        |> List.head
