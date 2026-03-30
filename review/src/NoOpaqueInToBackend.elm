module NoOpaqueInToBackend exposing (rule)

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Range exposing (Range)
import Elm.Syntax.Type exposing (ValueConstructor)
import Elm.Syntax.TypeAnnotation exposing (TypeAnnotation(..))
import Review.ModuleNameLookupTable as ModuleNameLookupTable exposing (ModuleNameLookupTable)
import Review.Rule as Rule exposing (ModuleKey, Rule)
import Set exposing (Set)


rule : Rule
rule =
    Rule.newProjectRuleSchema "NoOpaqueInToBackend" initialProjectContext
        |> Rule.withModuleVisitor moduleVisitor
        |> Rule.withFinalProjectEvaluation finalProjectEvaluation
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



-- RESOLVED TYPE


type ResolvedType
    = RNamed Range ModuleName String (List ResolvedType)
    | ROther (List ResolvedType)


resolveTypeAnnotation : ModuleContext -> Node TypeAnnotation -> ResolvedType
resolveTypeAnnotation context (Node _ typeAnnotation) =
    case typeAnnotation of
        Typed (Node range ( _, name )) args ->
            let
                moduleName : ModuleName
                moduleName =
                    resolveModuleName context range
                        |> Maybe.withDefault context.moduleName
            in
            RNamed range moduleName name (List.map (resolveTypeAnnotation context) args)

        Tupled nodes ->
            ROther (List.map (resolveTypeAnnotation context) nodes)

        Record fields ->
            ROther (List.map (\(Node _ ( _, field )) -> resolveTypeAnnotation context field) fields)

        GenericRecord _ (Node _ fields) ->
            ROther (List.map (\(Node _ ( _, field )) -> resolveTypeAnnotation context field) fields)

        FunctionTypeAnnotation a b ->
            ROther [ resolveTypeAnnotation context a, resolveTypeAnnotation context b ]

        _ ->
            ROther []


resolveModuleName : ModuleContext -> Range -> Maybe ModuleName
resolveModuleName context range =
    case ModuleNameLookupTable.moduleNameAt context.lookupTable range of
        Just [] ->
            Just context.moduleName

        result ->
            result



-- CONTEXTS


type alias TypeDefEntry =
    { moduleKey : ModuleKey
    , moduleName : ModuleName
    , typeName : String
    , contents : List ResolvedType
    }


type alias ToBackendEntry =
    { moduleKey : ModuleKey
    , args : List ResolvedType
    }


type alias ProjectContext =
    { opaqueTypes : Set ( ModuleName, String )
    , phantomTypeParams : Set ( ModuleName, String, Int )
    , typeDefinitions : List TypeDefEntry
    , toBackendModules : List ToBackendEntry
    }


type alias ModuleContext =
    { opaqueTypes : Set ( ModuleName, String )
    , phantomTypeParams : Set ( ModuleName, String, Int )
    , moduleName : ModuleName
    , moduleKey : ModuleKey
    , lookupTable : ModuleNameLookupTable
    , allTypeDefinitions : List TypeDefEntry
    , myTypeDefinitions : List TypeDefEntry
    , allToBackendModules : List ToBackendEntry
    , myToBackendModules : List ToBackendEntry
    , comments : List (Node String)
    }


initialProjectContext : ProjectContext
initialProjectContext =
    { opaqueTypes = Set.empty
    , phantomTypeParams = Set.empty
    , typeDefinitions = []
    , toBackendModules = []
    }


initModuleContext : ModuleName -> ModuleKey -> ModuleNameLookupTable -> ProjectContext -> ModuleContext
initModuleContext moduleName moduleKey lookupTable projectContext =
    { opaqueTypes = projectContext.opaqueTypes
    , phantomTypeParams = projectContext.phantomTypeParams
    , moduleName = moduleName
    , moduleKey = moduleKey
    , lookupTable = lookupTable
    , allTypeDefinitions = projectContext.typeDefinitions
    , myTypeDefinitions = []
    , allToBackendModules = projectContext.toBackendModules
    , myToBackendModules = []
    , comments = []
    }


fromModuleToProject : ModuleContext -> ProjectContext
fromModuleToProject moduleContext =
    { opaqueTypes = moduleContext.opaqueTypes
    , phantomTypeParams = moduleContext.phantomTypeParams
    , typeDefinitions = moduleContext.myTypeDefinitions
    , toBackendModules = moduleContext.myToBackendModules
    }


foldProjectContexts : ProjectContext -> ProjectContext -> ProjectContext
foldProjectContexts a b =
    { opaqueTypes = Set.union a.opaqueTypes b.opaqueTypes
    , phantomTypeParams = Set.union a.phantomTypeParams b.phantomTypeParams
    , typeDefinitions = a.typeDefinitions ++ b.typeDefinitions
    , toBackendModules = a.toBackendModules ++ b.toBackendModules
    }



-- VISITORS


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

                resolvedContents : List ResolvedType
                resolvedContents =
                    List.concatMap
                        (\(Node _ constructor) ->
                            List.map (resolveTypeAnnotation context) constructor.arguments
                        )
                        customType.constructors

                typeDef : TypeDefEntry
                typeDef =
                    { moduleKey = context.moduleKey
                    , moduleName = context.moduleName
                    , typeName = Node.value customType.name
                    , contents = resolvedContents
                    }

                updatedContext =
                    { context
                        | opaqueTypes =
                            if hasOpaqueComment then
                                Set.insert ( context.moduleName, Node.value customType.name ) context.opaqueTypes

                            else
                                context.opaqueTypes
                        , phantomTypeParams =
                            Set.union context.phantomTypeParams
                                (Set.fromList
                                    (List.map
                                        (\i -> ( context.moduleName, Node.value customType.name, i ))
                                        (Set.toList phantomIndices)
                                    )
                                )
                        , allTypeDefinitions = typeDef :: context.allTypeDefinitions
                        , myTypeDefinitions = typeDef :: context.myTypeDefinitions
                        , allToBackendModules =
                            if Node.value customType.name == "ToBackend" then
                                { moduleKey = context.moduleKey
                                , args = resolvedContents
                                }
                                    :: context.allToBackendModules

                            else
                                context.allToBackendModules
                        , myToBackendModules =
                            if Node.value customType.name == "ToBackend" then
                                { moduleKey = context.moduleKey
                                , args = resolvedContents
                                }
                                    :: context.myToBackendModules

                            else
                                context.myToBackendModules
                    }
            in
            ( [], updatedContext )

        AliasDeclaration typeAlias ->
            let
                hasOpaqueComment =
                    hasOpaqueDocComment declRange context.comments
                        || hasOpaqueDocField typeAlias.documentation

                resolvedContents : List ResolvedType
                resolvedContents =
                    [ resolveTypeAnnotation context typeAlias.typeAnnotation ]

                typeDef : TypeDefEntry
                typeDef =
                    { moduleKey = context.moduleKey
                    , moduleName = context.moduleName
                    , typeName = Node.value typeAlias.name
                    , contents = resolvedContents
                    }
            in
            ( []
            , { context
                | opaqueTypes =
                    if hasOpaqueComment then
                        Set.insert ( context.moduleName, Node.value typeAlias.name ) context.opaqueTypes

                    else
                        context.opaqueTypes
                , allTypeDefinitions = typeDef :: context.allTypeDefinitions
                , myTypeDefinitions = typeDef :: context.myTypeDefinitions
              }
            )

        _ ->
            ( [], context )



-- FINAL EVALUATION


finalProjectEvaluation : ProjectContext -> List (Rule.Error { useErrorForModule : () })
finalProjectEvaluation context =
    List.concatMap
        (\entry ->
            List.concatMap
                (checkResolved context Set.empty entry.moduleKey)
                entry.args
        )
        context.toBackendModules


checkResolved : ProjectContext -> Set ( ModuleName, String ) -> ModuleKey -> ResolvedType -> List (Rule.Error { useErrorForModule : () })
checkResolved context visited moduleKey resolvedType =
    case resolvedType of
        RNamed range moduleName name args ->
            if name == "Untrusted" then
                []

            else if Set.member ( moduleName, name ) context.opaqueTypes then
                [ Rule.errorForModule moduleKey
                    { message = name ++ " is an opaque type and must be wrapped in Untrusted when used in ToBackend."
                    , details = [ "Opaque types sent from the frontend could be tampered with. Wrap this type in Untrusted to ensure it gets validated on the backend." ]
                    }
                    range
                ]

            else if name == "ToBackend" then
                -- Skip: ToBackend types are checked by their own entry
                []

            else if Set.member ( moduleName, name ) visited then
                []

            else
                let
                    newVisited : Set ( ModuleName, String )
                    newVisited =
                        Set.insert ( moduleName, name ) visited

                    argErrors : List (Rule.Error { useErrorForModule : () })
                    argErrors =
                        checkArgsWithPhantom context newVisited moduleKey ( moduleName, name ) args

                    defErrors : List (Rule.Error { useErrorForModule : () })
                    defErrors =
                        lookupAndCheck context newVisited ( moduleName, name )
                in
                argErrors ++ defErrors

        ROther children ->
            List.concatMap (checkResolved context visited moduleKey) children


checkArgsWithPhantom : ProjectContext -> Set ( ModuleName, String ) -> ModuleKey -> ( ModuleName, String ) -> List ResolvedType -> List (Rule.Error { useErrorForModule : () })
checkArgsWithPhantom context visited moduleKey ( moduleName, typeName ) args =
    args
        |> List.indexedMap
            (\i arg ->
                if Set.member ( moduleName, typeName, i ) context.phantomTypeParams then
                    []

                else
                    checkResolved context visited moduleKey arg
            )
        |> List.concat


lookupAndCheck : ProjectContext -> Set ( ModuleName, String ) -> ( ModuleName, String ) -> List (Rule.Error { useErrorForModule : () })
lookupAndCheck context visited ( moduleName, typeName ) =
    context.typeDefinitions
        |> List.concatMap
            (\entry ->
                if entry.moduleName == moduleName && entry.typeName == typeName then
                    List.concatMap (checkResolved context visited entry.moduleKey) entry.contents

                else
                    []
            )



-- HELPERS


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
