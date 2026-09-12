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
            , unlessWrappedIn = []
            }
        ]

Types are identified by their canonical module name and name. For example
`Float` lives in `Basics`, so it is `( [ "Basics" ], "Float" )`, and a project
type `Coord` defined in `Geometry` is `( [ "Geometry" ], "Coord" )`.

`unlessWrappedIn` is a list of types that are skipped during the traversal. An
exempt type and everything it wraps is invisible to the rule, so a disallowed
type only reachable through that type is ignored:

    config =
        [ NoInvalidTypesInToBackend.rule
            { disallowed = [ ( [ "Basics" ], "Float" ) ]
            , unlessWrappedIn = [ ( [ "SafeJson" ], "SafeJson" ) ]
            }
        ]

That includes the type arguments an exempt type is applied to. With
`ToBeFilledInByBackend` exempt, `ToBeFilledInByBackend Float` doesn't count the
`Float`.

When a disallowed type is found the error shows the path that leads to it, for
example `Types.ToBackend -> Types.ServerChange -> Geometry.Coord -> Basics.Float`.

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
        |> Rule.withModuleVisitor (moduleVisitor exempt)
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
    Set ( ModuleName, String )
    -> Rule.ModuleRuleSchema {} ModuleContext
    -> Rule.ModuleRuleSchema { hasAtLeastOneVisitor : () } ModuleContext
moduleVisitor exempt visitor =
    visitor
        |> Rule.withDeclarationEnterVisitor (declarationVisitor exempt)


declarationVisitor :
    Set ( ModuleName, String )
    -> Node Declaration
    -> ModuleContext
    -> ( List (Rule.Error {}), ModuleContext )
declarationVisitor exempt (Node _ declaration) context =
    case declaration of
        Declaration.CustomTypeDeclaration customType ->
            let
                references : List ( ModuleName, String )
                references =
                    customType.constructors
                        |> List.concatMap
                            (\(Node _ constructor) ->
                                List.concatMap (collectTargets exempt context) constructor.arguments
                            )
            in
            ( [], insertType customType.name references context )

        Declaration.AliasDeclaration typeAlias ->
            ( []
            , insertType
                typeAlias.name
                (collectTargets exempt context typeAlias.typeAnnotation)
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

An exempt type is left out along with the arguments it is applied to, so
`ToBeFilledInByBackend Float` references neither of them when
`ToBeFilledInByBackend` is exempt. That's the only place exemptions are applied:
once a type is left out here, nothing that follows can reach it.

-}
collectTargets :
    Set ( ModuleName, String )
    -> ModuleContext
    -> Node TypeAnnotation
    -> List ( ModuleName, String )
collectTargets exempt context node =
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
            if Set.member target exempt then
                []

            else
                target :: List.concatMap (collectTargets exempt context) arguments

        TypeAnnotation.Unit ->
            []

        TypeAnnotation.Tupled nodes ->
            List.concatMap (collectTargets exempt context) nodes

        TypeAnnotation.Record fields ->
            List.concatMap (\(Node _ ( _, field )) -> collectTargets exempt context field) fields

        TypeAnnotation.GenericRecord _ (Node _ fields) ->
            List.concatMap (\(Node _ ( _, field )) -> collectTargets exempt context field) fields

        TypeAnnotation.FunctionTypeAnnotation a b ->
            collectTargets exempt context a ++ collectTargets exempt context b


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
                if Tuple.second key == "ToBackend" && not (Set.member key exempt) then
                    findDisallowedPath disallowed context.types key
                        |> Maybe.map (\path -> toError info path)

                else
                    Nothing
            )


toError : TypeInfo -> List ( ModuleName, String ) -> Rule.Error { useErrorForModule : () }
toError info path =
    Rule.errorForModule info.key
        { message = "Found a disallowed type referenced by ToBackend"
        , details =
            [ "ToBackend references a type that this rule disallows, either directly or indirectly through other types."
            , "Path: " ++ String.join " -> " (List.map (\( moduleName, typeName ) -> String.join "." moduleName ++ "." ++ typeName) path)
            ]
        }
        info.range


{-| Breadth first search from `ToBackend` to the nearest disallowed type.
Returns the path of types leading to it (ending with the disallowed type), e.g.
`[ ToBackend, ServerChange, Coord, Float ]`.
-}
findDisallowedPath :
    Set ( ModuleName, String )
    -> Dict ( ModuleName, String ) TypeInfo
    -> ( ModuleName, String )
    -> Maybe (List ( ModuleName, String ))
findDisallowedPath disallowed types start =
    bfs disallowed types [ ( start, [ start ] ) ] (Set.singleton start)


bfs :
    Set ( ModuleName, String )
    -> Dict ( ModuleName, String ) TypeInfo
    -> List ( ( ModuleName, String ), List ( ModuleName, String ) )
    -> Set ( ModuleName, String )
    -> Maybe (List ( ModuleName, String ))
bfs disallowed types queue visited =
    case queue of
        [] ->
            Nothing

        ( key, path ) :: rest ->
            case Dict.get key types of
                Nothing ->
                    bfs disallowed types rest visited

                Just info ->
                    case disallowedHit disallowed info.references of
                        Just hit ->
                            Just (path ++ [ hit ])

                        Nothing ->
                            let
                                ( newQueue, newVisited ) =
                                    info.references
                                        |> List.foldl
                                            (\next ( q, v ) ->
                                                if Set.member next v then
                                                    ( q, v )

                                                else
                                                    ( q ++ [ ( next, path ++ [ next ] ) ]
                                                    , Set.insert next v
                                                    )
                                            )
                                            ( rest, visited )
                            in
                            bfs disallowed types newQueue newVisited


{-| Finds the first reference that is disallowed.
-}
disallowedHit :
    Set ( ModuleName, String )
    -> List ( ModuleName, String )
    -> Maybe ( ModuleName, String )
disallowedHit disallowed references =
    references
        |> List.filter (\target -> Set.member target disallowed)
        |> List.head
