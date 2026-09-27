module NoUnhandledFileHashes exposing (rule)

{-| Makes sure every place `BackendModel` can hold a `FileHash` has been looked at by whoever
decides which uploaded files are still in use.

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


{-| Reports every path from `Types.BackendModel` to `FileStatus.FileHash` that isn't listed in
`handled` or `excluded`.

    config =
        [ NoUnhandledFileHashes.rule
            { handled = [ "users.icon", "guilds.channels.messages.UserTextMessage.content.attachedFiles.fileHash" ]
            , excluded = [ "files" ]
            }
        ]

A type argument the type doesn't use, like the `a` in `type EncryptedData a = EncryptedData Bytes`,
isn't followed, since nothing of that type is actually stored.

A path is the record fields and constructors passed through on the way to the `FileHash`,
joined with dots. Containers such as `SeqDict`, `Maybe` and tuples don't add anything to it, so
`users : NonemptyDict (Id UserId) BackendUser` followed by `icon : Maybe FileHash` is
`users.icon`.

A listed path also covers every path it is the start of, so `"toBackendLogs"` covers whatever
the logs hold. Listing a path that no longer leads to a `FileHash` is reported too, so the lists
don't keep entries for things that have been removed.

`handled` and `excluded` are treated the same. The split is there so the config says which
paths were accounted for and which were deliberately left out.

-}
rule : { handled : List String, excluded : List String } -> Rule
rule config =
    let
        listed : List (List String)
        listed =
            List.map (String.split ".") (config.handled ++ config.excluded)
    in
    Rule.newProjectRuleSchema "NoUnhandledFileHashes" initialContext
        |> Rule.withModuleVisitor moduleVisitor
        |> Rule.withModuleContextUsingContextCreator conversion
        |> Rule.withFinalProjectEvaluation (finalProjectEvaluation listed)
        |> Rule.fromProjectRuleSchema


type alias TypeKey =
    ( ModuleName, String )


{-| One way out of a type: the fields and constructors passed through, the type reached and
where the first of them is written. `argumentOf` is which type arguments it was found in, as the
type it was passed to and the argument's position.
-}
type alias Edge =
    { steps : List String
    , target : TypeKey
    , range : Range
    , argumentOf : List ( TypeKey, Int )
    }


type alias TypeInfo =
    { edges : List Edge
    , unusedParameters : Set Int
    , key : ModuleKey
    }


type alias ProjectContext =
    { types : Dict TypeKey TypeInfo
    }


type alias ModuleContext =
    { moduleName : ModuleName
    , moduleKey : ModuleKey
    , lookupTable : ModuleNameLookupTable
    , types : Dict TypeKey TypeInfo
    }


root : TypeKey
root =
    ( [ "Types" ], "BackendModel" )


fileHash : TypeKey
fileHash =
    ( [ "FileStatus" ], "FileHash" )


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
            ( []
            , insertType
                customType.name
                (unusedParameters
                    customType.generics
                    (List.concatMap (\(Node _ constructor) -> constructor.arguments) customType.constructors)
                )
                (List.concatMap
                    (\(Node _ constructor) ->
                        List.concatMap
                            (collectEdges context [ Node.value constructor.name ] (Node.range constructor.name) [])
                            constructor.arguments
                    )
                    customType.constructors
                )
                context
            )

        Declaration.AliasDeclaration typeAlias ->
            ( []
            , insertType
                typeAlias.name
                (unusedParameters typeAlias.generics [ typeAlias.typeAnnotation ])
                (collectEdges context [] (Node.range typeAlias.name) [] typeAlias.typeAnnotation)
                context
            )

        _ ->
            ( [], context )


insertType : Node String -> Set Int -> List Edge -> ModuleContext -> ModuleContext
insertType (Node _ name) unusedParameters2 edges context =
    { context
        | types =
            Dict.insert
                ( context.moduleName, name )
                { edges = edges, unusedParameters = unusedParameters2, key = context.moduleKey }
                context.types
    }


unusedParameters : List (Node String) -> List (Node TypeAnnotation) -> Set Int
unusedParameters parameters body =
    let
        used : Set String
        used =
            Set.fromList (List.concatMap typeVariables body)
    in
    List.indexedMap Tuple.pair parameters
        |> List.filter (\( _, Node _ parameter ) -> not (Set.member parameter used))
        |> List.map Tuple.first
        |> Set.fromList


typeVariables : Node TypeAnnotation -> List String
typeVariables node =
    case Node.value node of
        TypeAnnotation.GenericType name ->
            [ name ]

        TypeAnnotation.Typed _ arguments ->
            List.concatMap typeVariables arguments

        TypeAnnotation.Unit ->
            []

        TypeAnnotation.Tupled nodes ->
            List.concatMap typeVariables nodes

        TypeAnnotation.Record fields ->
            List.concatMap (\(Node _ ( _, field )) -> typeVariables field) fields

        TypeAnnotation.GenericRecord (Node _ name) (Node _ fields) ->
            name :: List.concatMap (\(Node _ ( _, field )) -> typeVariables field) fields

        TypeAnnotation.FunctionTypeAnnotation a b ->
            typeVariables a ++ typeVariables b


{-| Every type a type annotation mentions, along with the record fields passed through to get
to it. Type arguments count as mentioned, so `SeqDict (Id UserId) BackendUser` leads to `SeqDict`,
`Id`, `UserId` and `BackendUser` alike.
-}
collectEdges : ModuleContext -> List String -> Range -> List ( TypeKey, Int ) -> Node TypeAnnotation -> List Edge
collectEdges context steps range argumentOf node =
    case Node.value node of
        TypeAnnotation.GenericType _ ->
            []

        TypeAnnotation.Typed (Node typeRange ( rawModuleName, name )) arguments ->
            let
                target : TypeKey
                target =
                    case ModuleNameLookupTable.moduleNameAt context.lookupTable typeRange of
                        Just [] ->
                            ( context.moduleName, name )

                        Just moduleName ->
                            ( moduleName, name )

                        Nothing ->
                            ( rawModuleName, name )
            in
            { steps = steps, target = target, range = range, argumentOf = argumentOf }
                :: List.concat
                    (List.indexedMap
                        (\index -> collectEdges context steps range (( target, index ) :: argumentOf))
                        arguments
                    )

        TypeAnnotation.Unit ->
            []

        TypeAnnotation.Tupled nodes ->
            List.concatMap (collectEdges context steps range argumentOf) nodes

        TypeAnnotation.Record fields ->
            List.concatMap (fieldEdges context steps range argumentOf) fields

        TypeAnnotation.GenericRecord _ (Node _ fields) ->
            List.concatMap (fieldEdges context steps range argumentOf) fields

        TypeAnnotation.FunctionTypeAnnotation a b ->
            collectEdges context steps range argumentOf a ++ collectEdges context steps range argumentOf b


{-| A field of a type's own record starts the path, so it's where errors about that path point.
Fields of records further in only add to the path.
-}
fieldEdges : ModuleContext -> List String -> Range -> List ( TypeKey, Int ) -> Node ( Node String, Node TypeAnnotation ) -> List Edge
fieldEdges context steps range argumentOf (Node _ ( Node fieldRange fieldName, field )) =
    collectEdges
        context
        (steps ++ [ fieldName ])
        (if List.isEmpty steps then
            fieldRange

         else
            range
        )
        argumentOf
        field


finalProjectEvaluation : List (List String) -> ProjectContext -> List (Rule.Error { useErrorForModule : () })
finalProjectEvaluation listed context =
    let
        types : Dict TypeKey TypeInfo
        types =
            Dict.map
                (\_ info -> { info | edges = List.filter (\edge -> not (isUnusedArgument context.types edge)) info.edges })
                context.types
    in
    case Dict.get root types of
        Just rootInfo ->
            let
                reachesFileHash : Set TypeKey
                reachesFileHash =
                    canReachFileHash types

                result : SearchResult
                result =
                    List.foldl
                        (\edge result2 -> follow listed types reachesFileHash edge [] (Set.singleton root) result2)
                        { unlisted = [], used = Set.empty }
                        rootInfo.edges
            in
            List.map (unlistedError rootInfo.key) (List.reverse result.unlisted)
                ++ List.filterMap
                    (\path ->
                        if Set.member path result.used then
                            Nothing

                        else
                            Just (staleError path)
                    )
                    listed

        Nothing ->
            []


isUnusedArgument : Dict TypeKey TypeInfo -> Edge -> Bool
isUnusedArgument types edge =
    List.any
        (\( typeKey, index ) ->
            case Dict.get typeKey types of
                Just info ->
                    Set.member index info.unusedParameters

                Nothing ->
                    False
        )
        edge.argumentOf


type alias SearchResult =
    { unlisted : List ( List String, Range )
    , used : Set (List String)
    }


{-| Walks every path through `edge` that ends in a `FileHash`, stopping early wherever the config
already lists the path so far. A type already on the path isn't entered again, so recursive types
don't go on forever.
-}
follow :
    List (List String)
    -> Dict TypeKey TypeInfo
    -> Set TypeKey
    -> Edge
    -> List String
    -> Set TypeKey
    -> SearchResult
    -> SearchResult
follow listed types reachesFileHash edge stepsSoFar visited result =
    let
        steps : List String
        steps =
            stepsSoFar ++ edge.steps
    in
    if edge.target /= fileHash && not (Set.member edge.target reachesFileHash) then
        result

    else
        case List.filter (\path -> isPrefixOf path steps) listed of
            [] ->
                if edge.target == fileHash then
                    { result | unlisted = ( steps, edge.range ) :: result.unlisted }

                else if Set.member edge.target visited then
                    result

                else
                    case Dict.get edge.target types of
                        Just info ->
                            List.foldl
                                (\next result2 ->
                                    follow listed types reachesFileHash { next | range = edge.range } steps (Set.insert edge.target visited) result2
                                )
                                result
                                info.edges

                        Nothing ->
                            result

            covering ->
                { result | used = List.foldl Set.insert result.used covering }


isPrefixOf : List String -> List String -> Bool
isPrefixOf prefix list =
    List.take (List.length prefix) list == prefix


{-| Every type that has some way of leading to a `FileHash`. Nothing else needs to be walked.
-}
canReachFileHash : Dict TypeKey TypeInfo -> Set TypeKey
canReachFileHash types =
    let
        referencedBy : Dict TypeKey (List TypeKey)
        referencedBy =
            Dict.foldl
                (\key info dict ->
                    List.foldl
                        (\edge dict2 -> Dict.update edge.target (\list -> Just (key :: Maybe.withDefault [] list)) dict2)
                        dict
                        info.edges
                )
                Dict.empty
                types
    in
    reachableFrom referencedBy [ fileHash ] (Set.singleton fileHash)


reachableFrom : Dict TypeKey (List TypeKey) -> List TypeKey -> Set TypeKey -> Set TypeKey
reachableFrom referencedBy queue found =
    case queue of
        [] ->
            found

        key :: rest ->
            let
                new : List TypeKey
                new =
                    Dict.get key referencedBy
                        |> Maybe.withDefault []
                        |> List.filter (\next -> not (Set.member next found))
            in
            reachableFrom referencedBy (new ++ rest) (List.foldl Set.insert found new)


unlistedError : ModuleKey -> ( List String, Range ) -> Rule.Error { useErrorForModule : () }
unlistedError moduleKey ( steps, range ) =
    Rule.errorForModule moduleKey
        { message = "BackendModel holds a FileHash at " ++ String.join "." steps ++ " that nothing has accounted for"
        , details =
            [ "BackendExtra.orphanedFiles treats every file that nothing refers to as unused. If it doesn't know about this path, files only referred to from here would be listed as orphaned."
            , "Handle the path in BackendExtra.usedFiles and add \"" ++ String.join "." steps ++ "\" to `handled` in this rule's config, or add it to `excluded` if files referred to from here don't count as in use."
            ]
        }
        range


staleError : List String -> Rule.Error scope
staleError path =
    Rule.globalError
        { message = "\"" ++ String.join "." path ++ "\" doesn't lead to a FileHash"
        , details =
            [ "This path is listed in NoUnhandledFileHashes' config, but no path from BackendModel to a FileHash starts with it, or a shorter listed path already covers it."
            , "Remove it from the config, or correct it if a field or constructor has been renamed."
            ]
        }
