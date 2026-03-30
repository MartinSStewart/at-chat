module NoOpaqueInToBackend exposing (rule)

import Dict exposing (Dict)
import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Range exposing (Range)
import Elm.Syntax.Type exposing (ValueConstructor)
import Elm.Syntax.TypeAnnotation exposing (TypeAnnotation(..))
import Review.ModuleNameLookupTable as ModuleNameLookupTable exposing (ModuleNameLookupTable)
import Review.Rule as Rule exposing (ModuleKey, Rule)
import Set exposing (Set)


type alias Config =
    { exemptions : Set ( ModuleName, String )
    }


rule : { exemptions : List ( ModuleName, String ) } -> Rule
rule config =
    let
        cfg =
            { exemptions = Set.fromList config.exemptions }
    in
    Rule.newProjectRuleSchema "NoOpaqueInToBackend" initialProjectContext
        |> Rule.withModuleVisitor moduleVisitor
        |> Rule.withFinalProjectEvaluation (finalProjectEvaluation cfg)
        |> Rule.withContextFromImportedModules
        |> Rule.withModuleContextUsingContextCreator
            { fromProjectToModule =
                Rule.initContextCreator initModuleContext
                    |> Rule.withModuleName
                    |> Rule.withModuleKey
                    |> Rule.withModuleNameLookupTable
            , fromModuleToProject =
                Rule.initContextCreator fromModuleToProject
            , foldProjectContexts = foldProjectContexts
            }
        |> Rule.fromProjectRuleSchema


type alias ProjectContext =
    { opaqueTypes : Set ( ModuleName, String )
    , phantomTypeParams : Set ( ModuleName, String, Int )
    , typeDefinitions : List ( ( ModuleName, String ), TypeDefInfo )
    }


type alias TypeDefInfo =
    { args : List (Node TypeAnnotation)
    , lookupTable : ModuleNameLookupTable
    , moduleName : ModuleName
    , moduleKey : ModuleKey
    }


type alias ModuleContext =
    { opaqueTypes : Set ( ModuleName, String )
    , phantomTypeParams : Set ( ModuleName, String, Int )
    , moduleName : ModuleName
    , moduleKey : ModuleKey
    , lookupTable : ModuleNameLookupTable
    , typeDefinitions : List ( ( ModuleName, String ), TypeDefInfo )
    , comments : List (Node String)
    }


initialProjectContext : ProjectContext
initialProjectContext =
    { opaqueTypes = Set.empty
    , phantomTypeParams = Set.empty
    , typeDefinitions = []
    }


initModuleContext : ModuleName -> ModuleKey -> ModuleNameLookupTable -> ProjectContext -> ModuleContext
initModuleContext moduleName moduleKey lookupTable projectContext =
    { opaqueTypes = projectContext.opaqueTypes
    , phantomTypeParams = projectContext.phantomTypeParams
    , moduleName = moduleName
    , moduleKey = moduleKey
    , lookupTable = lookupTable
    , typeDefinitions = []
    , comments = []
    }


fromModuleToProject : ModuleContext -> ProjectContext
fromModuleToProject moduleContext =
    { opaqueTypes = moduleContext.opaqueTypes
    , phantomTypeParams = moduleContext.phantomTypeParams
    , typeDefinitions = moduleContext.typeDefinitions
    }


foldProjectContexts : ProjectContext -> ProjectContext -> ProjectContext
foldProjectContexts a b =
    { opaqueTypes = Set.union a.opaqueTypes b.opaqueTypes
    , phantomTypeParams = Set.union a.phantomTypeParams b.phantomTypeParams
    , typeDefinitions = a.typeDefinitions ++ b.typeDefinitions
    }


moduleVisitor :
    Rule.ModuleRuleSchema {} ModuleContext
    -> Rule.ModuleRuleSchema { hasAtLeastOneVisitor : () } ModuleContext
moduleVisitor visitor =
    visitor
        |> Rule.withCommentsVisitor commentsVisitor
        |> Rule.withDeclarationEnterVisitor declarationVisitor


commentsVisitor : List (Node String) -> ModuleContext -> ( List (Rule.Error {}), ModuleContext )
commentsVisitor comments context =
    ( [], { context | comments = comments } )


declarationVisitor : Node Declaration -> ModuleContext -> ( List (Rule.Error {}), ModuleContext )
declarationVisitor node context =
    let
        (Node declRange declaration) =
            node
    in
    case declaration of
        CustomTypeDeclaration customType ->
            let
                hasOpaqueComment =
                    hasOpaqueDocComment declRange context.comments
                        || hasOpaqueDocField customType.documentation

                phantomIndices =
                    getPhantomTypeParamIndices customType.generics customType.constructors

                allArgs =
                    List.concatMap
                        (\(Node _ constructor) -> constructor.arguments)
                        customType.constructors

                typeDef =
                    { args = allArgs
                    , lookupTable = context.lookupTable
                    , moduleName = context.moduleName
                    , moduleKey = context.moduleKey
                    }

                withPhantom =
                    { context
                        | phantomTypeParams =
                            Set.union context.phantomTypeParams
                                (Set.map
                                    (\i -> ( context.moduleName, Node.value customType.name, i ))
                                    phantomIndices
                                )
                    }

                withOpaque =
                    if hasOpaqueComment then
                        { withPhantom
                            | opaqueTypes =
                                Set.insert ( context.moduleName, Node.value customType.name ) withPhantom.opaqueTypes
                        }

                    else
                        withPhantom

                withTypeDef =
                    { withOpaque
                        | typeDefinitions =
                            ( ( context.moduleName, Node.value customType.name ), typeDef ) :: withOpaque.typeDefinitions
                    }
            in
            ( [], withTypeDef )

        AliasDeclaration typeAlias ->
            let
                hasOpaqueComment =
                    hasOpaqueDocComment declRange context.comments
                        || hasOpaqueDocField typeAlias.documentation

                typeDef =
                    { args = [ typeAlias.typeAnnotation ]
                    , lookupTable = context.lookupTable
                    , moduleName = context.moduleName
                    , moduleKey = context.moduleKey
                    }

                withOpaque =
                    if hasOpaqueComment then
                        { context
                            | opaqueTypes =
                                Set.insert ( context.moduleName, Node.value typeAlias.name ) context.opaqueTypes
                        }

                    else
                        context

                withTypeDef =
                    { withOpaque
                        | typeDefinitions =
                            ( ( context.moduleName, Node.value typeAlias.name ), typeDef ) :: withOpaque.typeDefinitions
                    }
            in
            ( [], withTypeDef )

        _ ->
            ( [], context )


getPhantomTypeParamIndices : List (Node String) -> List (Node ValueConstructor) -> Set Int
getPhantomTypeParamIndices generics constructors =
    let
        usedVars : Set String
        usedVars =
            constructors
                |> List.concatMap (\(Node _ c) -> c.arguments)
                |> List.foldl (\arg acc -> Set.union (collectTypeVars arg) acc) Set.empty
    in
    generics
        |> List.indexedMap
            (\i (Node _ name) ->
                if Set.member name usedVars then
                    Nothing

                else
                    Just i
            )
        |> List.filterMap identity
        |> Set.fromList


collectTypeVars : Node TypeAnnotation -> Set String
collectTypeVars (Node _ typeAnnotation) =
    case typeAnnotation of
        GenericType name ->
            Set.singleton name

        Typed _ args ->
            List.foldl (\arg acc -> Set.union (collectTypeVars arg) acc) Set.empty args

        Unit ->
            Set.empty

        Tupled nodes ->
            List.foldl (\n acc -> Set.union (collectTypeVars n) acc) Set.empty nodes

        Record fields ->
            List.foldl (\(Node _ ( _, field )) acc -> Set.union (collectTypeVars field) acc) Set.empty fields

        GenericRecord _ (Node _ fields) ->
            List.foldl (\(Node _ ( _, field )) acc -> Set.union (collectTypeVars field) acc) Set.empty fields

        FunctionTypeAnnotation a b ->
            Set.union (collectTypeVars a) (collectTypeVars b)


hasOpaqueDocField : Maybe (Node String) -> Bool
hasOpaqueDocField documentation =
    case documentation of
        Just (Node _ text) ->
            isOpaqueDoc text

        Nothing ->
            False


hasOpaqueDocComment : Range -> List (Node String) -> Bool
hasOpaqueDocComment declRange comments =
    List.any
        (\(Node commentRange commentText) ->
            isOpaqueDoc commentText
                && commentRange.end.row
                == declRange.start.row
                - 1
        )
        comments


isOpaqueDoc : String -> Bool
isOpaqueDoc text =
    let
        trimmed : String
        trimmed =
            stringDropPrefix "{-|" text |> String.trim
    in
    String.startsWith "OpaqueVariants" trimmed || String.startsWith "Opaque" trimmed


stringDropPrefix : String -> String -> String
stringDropPrefix prefix text =
    if String.startsWith prefix text then
        String.dropLeft (String.length prefix) text

    else
        text


finalProjectEvaluation : Config -> ProjectContext -> List (Rule.Error { useErrorForModule : () })
finalProjectEvaluation config context =
    let
        typeDefDict : Dict ( ModuleName, String ) TypeDefInfo
        typeDefDict =
            Dict.fromList context.typeDefinitions
    in
    case Dict.get ( [ "Types" ], "ToBackend" ) typeDefDict of
        Just toBackendDef ->
            checkTypeDefRecursively config context typeDefDict (Set.singleton ( [ "Types" ], "ToBackend" )) [ "ToBackend" ] toBackendDef

        Nothing ->
            []


resolveModuleNameWith : TypeDefInfo -> Range -> Maybe ModuleName
resolveModuleNameWith typeDef range =
    case ModuleNameLookupTable.moduleNameAt typeDef.lookupTable range of
        Just [] ->
            Just typeDef.moduleName

        result ->
            result


checkTypeDefRecursively :
    Config
    -> ProjectContext
    -> Dict ( ModuleName, String ) TypeDefInfo
    -> Set ( ModuleName, String )
    -> List String
    -> TypeDefInfo
    -> List (Rule.Error { useErrorForModule : () })
checkTypeDefRecursively config context typeDefDict visited chain typeDef =
    List.concatMap (checkTypeAnnotationRecursive config context typeDefDict visited chain typeDef) typeDef.args


formatChain : List String -> String -> String
formatChain chain opaqueName =
    String.join " -> " (List.reverse chain ++ [ opaqueName ])


checkTypeAnnotationRecursive :
    Config
    -> ProjectContext
    -> Dict ( ModuleName, String ) TypeDefInfo
    -> Set ( ModuleName, String )
    -> List String
    -> TypeDefInfo
    -> Node TypeAnnotation
    -> List (Rule.Error { useErrorForModule : () })
checkTypeAnnotationRecursive config context typeDefDict visited chain typeDef typeAnnotation =
    case Node.value typeAnnotation of
        Typed (Node range ( _, name )) args ->
            if name == "Untrusted" then
                []

            else
                case resolveModuleNameWith typeDef range of
                    Just actualModuleName ->
                        if Set.member ( actualModuleName, name ) context.opaqueTypes && not (Set.member ( actualModuleName, name ) config.exemptions) then
                            [ Rule.errorForModule typeDef.moduleKey
                                { message = name ++ " is an opaque type and must be wrapped in Untrusted when used in ToBackend."
                                , details = [ "Opaque types sent from the frontend could be tampered with. Wrap this type in Untrusted to ensure it gets validated on the backend. Referenced via " ++ formatChain chain name ]
                                }
                                range
                            ]

                        else
                            let
                                argErrors =
                                    checkArgsWithPhantomRecursive config context typeDefDict visited chain typeDef ( actualModuleName, name ) args

                                recursiveErrors =
                                    if Set.member ( actualModuleName, name ) visited then
                                        []

                                    else
                                        case Dict.get ( actualModuleName, name ) typeDefDict of
                                            Just referencedTypeDef ->
                                                checkTypeDefRecursively config
                                                    context
                                                    typeDefDict
                                                    (Set.insert ( actualModuleName, name ) visited)
                                                    (name :: chain)
                                                    referencedTypeDef

                                            Nothing ->
                                                []
                            in
                            argErrors ++ recursiveErrors

                    Nothing ->
                        List.concatMap (checkTypeAnnotationRecursive config context typeDefDict visited chain typeDef) args

        Tupled nodes ->
            List.concatMap (checkTypeAnnotationRecursive config context typeDefDict visited chain typeDef) nodes

        Record fields ->
            List.concatMap (\(Node _ ( _, field )) -> checkTypeAnnotationRecursive config context typeDefDict visited chain typeDef field) fields

        GenericRecord _ (Node _ fields) ->
            List.concatMap (\(Node _ ( _, field )) -> checkTypeAnnotationRecursive config context typeDefDict visited chain typeDef field) fields

        FunctionTypeAnnotation a b ->
            checkTypeAnnotationRecursive config context typeDefDict visited chain typeDef a
                ++ checkTypeAnnotationRecursive config context typeDefDict visited chain typeDef b

        _ ->
            []


checkArgsWithPhantomRecursive :
    Config
    -> ProjectContext
    -> Dict ( ModuleName, String ) TypeDefInfo
    -> Set ( ModuleName, String )
    -> List String
    -> TypeDefInfo
    -> ( ModuleName, String )
    -> List (Node TypeAnnotation)
    -> List (Rule.Error { useErrorForModule : () })
checkArgsWithPhantomRecursive config context typeDefDict visited chain typeDef ( moduleName, typeName ) args =
    args
        |> List.indexedMap
            (\i arg ->
                if Set.member ( moduleName, typeName, i ) context.phantomTypeParams then
                    []

                else
                    checkTypeAnnotationRecursive config context typeDefDict visited chain typeDef arg
            )
        |> List.concat
