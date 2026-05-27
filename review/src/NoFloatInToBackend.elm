module NoFloatInToBackend exposing (rule)

{-| Forbids `ToBackend` from referencing `Float`, either directly or indirectly
through other types.

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


{-| Reports when the `ToBackend` type references a `Float`, directly or through
any chain of other types.

    config =
        [ NoFloatInToBackend.rule []
        ]

`Float` values sent from the frontend can't be trusted and floating point
serialization is lossy, so they shouldn't appear in messages sent to the
backend.

The argument is a list of types that are exempt from the check. When the
traversal reaches an exempt type it stops, so any `Float` only reachable
through that type is ignored. Types are identified by their canonical module
name and name, for example:

    config =
        [ NoFloatInToBackend.rule [ ( [ "Geometry" ], "Coord" ) ]
        ]

When a `Float` is found the error shows the path that leads to it, for example
`ToBackend -> ServerChange -> Coord`.

-}
rule : List ( ModuleName, String ) -> Rule
rule exemptList =
    let
        exempt : Set ( ModuleName, String )
        exempt =
            Set.fromList exemptList
    in
    Rule.newProjectRuleSchema "NoFloatInToBackend" initialContext
        |> Rule.withModuleVisitor moduleVisitor
        |> Rule.withModuleContextUsingContextCreator conversion
        |> Rule.withFinalProjectEvaluation (finalProjectEvaluation exempt)
        |> Rule.fromProjectRuleSchema


type Target
    = ToType ( ModuleName, String )
    | ToFloat


type alias TypeInfo =
    { references : List Target
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
                references : List Target
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


insertType : Node String -> List Target -> ModuleContext -> ModuleContext
insertType (Node nameRange name) references context =
    { context
        | types =
            Dict.insert
                ( context.moduleName, name )
                { references = references, range = nameRange, key = context.moduleKey }
                context.types
    }


{-| Collects every type referenced by a type annotation. Type arguments are
flattened in, so `List Coord` references both `List` and `Coord`.
-}
collectTargets : ModuleContext -> Node TypeAnnotation -> List Target
collectTargets context node =
    case Node.value node of
        TypeAnnotation.GenericType _ ->
            []

        TypeAnnotation.Typed (Node range ( rawModuleName, name )) arguments ->
            let
                resolved : Maybe ModuleName
                resolved =
                    ModuleNameLookupTable.moduleNameAt context.lookupTable range

                target : Target
                target =
                    if resolved == Just [ "Basics" ] && name == "Float" then
                        ToFloat

                    else
                        case resolved of
                            -- An empty module name means the type is defined in the current module.
                            Just [] ->
                                ToType ( context.moduleName, name )

                            Just moduleName ->
                                ToType ( moduleName, name )

                            Nothing ->
                                ToType ( rawModuleName, name )
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


finalProjectEvaluation : Set ( ModuleName, String ) -> ProjectContext -> List (Rule.Error { useErrorForModule : () })
finalProjectEvaluation exempt context =
    context.types
        |> Dict.toList
        |> List.filterMap
            (\( key, info ) ->
                if Tuple.second key == "ToBackend" then
                    findFloatPath exempt context.types key
                        |> Maybe.map (\path -> toError info path)

                else
                    Nothing
            )


toError : TypeInfo -> List String -> Rule.Error { useErrorForModule : () }
toError info path =
    Rule.errorForModule info.key
        { message = "Found a Float referenced by ToBackend"
        , details =
            [ "Floats sent from the frontend can't be trusted and floating point serialization is lossy, so ToBackend shouldn't reference Float (even indirectly through other types)."
            , "Path: " ++ String.join " -> " path
            ]
        }
        info.range


{-| Breadth first search from `ToBackend` to the nearest type that directly
references a `Float`. Returns the path of type names leading to it, e.g.
`[ "ToBackend", "ServerChange", "Coord" ]`.
-}
findFloatPath :
    Set ( ModuleName, String )
    -> Dict ( ModuleName, String ) TypeInfo
    -> ( ModuleName, String )
    -> Maybe (List String)
findFloatPath exempt types start =
    if Set.member start exempt then
        Nothing

    else
        bfs exempt types [ ( start, [ Tuple.second start ] ) ] (Set.singleton start)


bfs :
    Set ( ModuleName, String )
    -> Dict ( ModuleName, String ) TypeInfo
    -> List ( ( ModuleName, String ), List String )
    -> Set ( ModuleName, String )
    -> Maybe (List String)
bfs exempt types queue visited =
    case queue of
        [] ->
            Nothing

        ( key, path ) :: rest ->
            case Dict.get key types of
                Nothing ->
                    bfs exempt types rest visited

                Just info ->
                    if List.member ToFloat info.references then
                        Just path

                    else
                        let
                            ( newQueue, newVisited ) =
                                info.references
                                    |> List.filterMap
                                        (\target ->
                                            case target of
                                                ToType next ->
                                                    Just next

                                                ToFloat ->
                                                    Nothing
                                        )
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
                        bfs exempt types newQueue newVisited
