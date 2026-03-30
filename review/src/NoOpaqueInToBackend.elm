module NoOpaqueInToBackend exposing (rule)

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Range exposing (Range)
import Elm.Syntax.Type exposing (ValueConstructor)
import Elm.Syntax.TypeAnnotation exposing (TypeAnnotation(..))
import Review.ModuleNameLookupTable as ModuleNameLookupTable exposing (ModuleNameLookupTable)
import Review.Rule as Rule exposing (Rule)
import Set exposing (Set)


type alias Config =
    { exemptions : Set ( ModuleName, String )
    }


rule : { exemptions : List ( ModuleName, String ) } -> Rule
rule config =
    Rule.newProjectRuleSchema "NoOpaqueInToBackend" initialProjectContext
        |> Rule.withModuleVisitor (moduleVisitor { exemptions = Set.fromList config.exemptions })
        |> Rule.withContextFromImportedModules
        |> Rule.withModuleContextUsingContextCreator
            { fromProjectToModule =
                Rule.initContextCreator initModuleContext
                    |> Rule.withModuleName
                    |> Rule.withModuleNameLookupTable
            , fromModuleToProject =
                Rule.initContextCreator fromModuleToProject
            , foldProjectContexts = foldProjectContexts
            }
        |> Rule.fromProjectRuleSchema


type alias ProjectContext =
    { opaqueTypes : Set ( ModuleName, String )
    , phantomTypeParams : Set ( ModuleName, String, Int )
    }


type alias ModuleContext =
    { opaqueTypes : Set ( ModuleName, String )
    , phantomTypeParams : Set ( ModuleName, String, Int )
    , moduleName : ModuleName
    , lookupTable : ModuleNameLookupTable
    , toBackendArgs : List (Node TypeAnnotation)
    , comments : List (Node String)
    }


initialProjectContext : ProjectContext
initialProjectContext =
    { opaqueTypes = Set.empty
    , phantomTypeParams = Set.empty
    }


initModuleContext : ModuleName -> ModuleNameLookupTable -> ProjectContext -> ModuleContext
initModuleContext moduleName lookupTable projectContext =
    { opaqueTypes = projectContext.opaqueTypes
    , phantomTypeParams = projectContext.phantomTypeParams
    , moduleName = moduleName
    , lookupTable = lookupTable
    , toBackendArgs = []
    , comments = []
    }


fromModuleToProject : ModuleContext -> ProjectContext
fromModuleToProject moduleContext =
    { opaqueTypes = moduleContext.opaqueTypes
    , phantomTypeParams = moduleContext.phantomTypeParams
    }


foldProjectContexts : ProjectContext -> ProjectContext -> ProjectContext
foldProjectContexts a b =
    { opaqueTypes = Set.union a.opaqueTypes b.opaqueTypes
    , phantomTypeParams = Set.union a.phantomTypeParams b.phantomTypeParams
    }


moduleVisitor :
    Config
    -> Rule.ModuleRuleSchema {} ModuleContext
    -> Rule.ModuleRuleSchema { hasAtLeastOneVisitor : () } ModuleContext
moduleVisitor config visitor =
    visitor
        |> Rule.withCommentsVisitor commentsVisitor
        |> Rule.withDeclarationEnterVisitor declarationVisitor
        |> Rule.withFinalModuleEvaluation (finalEvaluation config)


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

                withPhantom =
                    { context
                        | phantomTypeParams =
                            Set.union context.phantomTypeParams
                                (Set.map
                                    (\i -> ( context.moduleName, Node.value customType.name, i ))
                                    phantomIndices
                                )
                    }

                updatedContext =
                    if hasOpaqueComment then
                        { withPhantom
                            | opaqueTypes =
                                Set.insert ( context.moduleName, Node.value customType.name ) withPhantom.opaqueTypes
                        }

                    else
                        withPhantom

                withToBackend =
                    if Node.value customType.name == "ToBackend" then
                        { updatedContext
                            | toBackendArgs =
                                updatedContext.toBackendArgs
                                    ++ List.concatMap
                                        (\(Node _ constructor) -> constructor.arguments)
                                        customType.constructors
                        }

                    else
                        updatedContext
            in
            ( [], withToBackend )

        AliasDeclaration typeAlias ->
            let
                hasOpaqueComment =
                    hasOpaqueDocComment declRange context.comments
                        || hasOpaqueDocField typeAlias.documentation
            in
            if hasOpaqueComment then
                ( []
                , { context
                    | opaqueTypes =
                        Set.insert ( context.moduleName, Node.value typeAlias.name ) context.opaqueTypes
                  }
                )

            else
                ( [], context )

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


finalEvaluation : Config -> ModuleContext -> List (Rule.Error {})
finalEvaluation config context =
    List.concatMap (checkTypeAnnotation config context) context.toBackendArgs


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


resolveModuleName : ModuleContext -> Range -> Maybe ModuleName
resolveModuleName context range =
    case ModuleNameLookupTable.moduleNameAt context.lookupTable range of
        Just [] ->
            Just context.moduleName

        result ->
            result


checkTypeAnnotation : Config -> ModuleContext -> Node TypeAnnotation -> List (Rule.Error {})
checkTypeAnnotation config context typeAnnotation =
    case Node.value typeAnnotation of
        Typed (Node range ( _, name )) args ->
            if name == "Untrusted" then
                []

            else
                case resolveModuleName context range of
                    Just actualModuleName ->
                        if Set.member ( actualModuleName, name ) context.opaqueTypes && not (Set.member ( actualModuleName, name ) config.exemptions) then
                            [ Rule.error
                                { message = name ++ " is an opaque type and must be wrapped in Untrusted when used in ToBackend."
                                , details = [ "Opaque types sent from the frontend could be tampered with. Wrap this type in Untrusted to ensure it gets validated on the backend." ]
                                }
                                range
                            ]

                        else
                            checkArgsWithPhantom config context ( actualModuleName, name ) args

                    Nothing ->
                        List.concatMap (checkTypeAnnotation config context) args

        Tupled nodes ->
            List.concatMap (checkTypeAnnotation config context) nodes

        Record fields ->
            List.concatMap (\(Node _ ( _, field )) -> checkTypeAnnotation config context field) fields

        GenericRecord _ (Node _ fields) ->
            List.concatMap (\(Node _ ( _, field )) -> checkTypeAnnotation config context field) fields

        FunctionTypeAnnotation a b ->
            checkTypeAnnotation config context a ++ checkTypeAnnotation config context b

        _ ->
            []


checkArgsWithPhantom : Config -> ModuleContext -> ( ModuleName, String ) -> List (Node TypeAnnotation) -> List (Rule.Error {})
checkArgsWithPhantom config context ( moduleName, typeName ) args =
    args
        |> List.indexedMap
            (\i arg ->
                if Set.member ( moduleName, typeName, i ) context.phantomTypeParams then
                    []

                else
                    checkTypeAnnotation config context arg
            )
        |> List.concat
