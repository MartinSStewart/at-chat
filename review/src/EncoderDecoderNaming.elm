module EncoderDecoderNaming exposing (rule)

{-| Enforces that encoder/decoder functions are named `encodeTypeName` and `decodeTypeName`
rather than `typeNameEncoder` and `typeNameDecoder`. Fixes all usages across the project.
-}

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Exposing exposing (Exposing(..), TopLevelExpose(..))
import Elm.Syntax.Expression exposing (Expression(..))
import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.Module as Module
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Range exposing (Range)
import Review.Fix as Fix
import Review.ModuleNameLookupTable as ModuleNameLookupTable exposing (ModuleNameLookupTable)
import Review.Rule as Rule exposing (ModuleKey, Rule)


rule : Rule
rule =
    Rule.newProjectRuleSchema "EncoderDecoderNaming" initialProjectContext
        |> Rule.withModuleVisitor moduleVisitor
        |> Rule.withModuleContextUsingContextCreator conversion
        |> Rule.withFinalProjectEvaluation finalProjectEvaluation
        |> Rule.fromProjectRuleSchema


type alias ProjectContext =
    { renames : List Rename
    , usages : List Usage
    , exposingFixes : List ExposingFix
    }


type alias ExposingFix =
    { moduleKey : ModuleKey
    , moduleName : ModuleName
    , oldName : String
    , range : Range
    , referencedModule : Maybe ModuleName
    }


type alias Rename =
    { moduleName : ModuleName
    , moduleKey : ModuleKey
    , oldName : String
    , newName : String
    , nameRange : Range
    , signatureRange : Maybe Range
    , message : String
    , detail : String
    }


type alias Usage =
    { moduleKey : ModuleKey
    , moduleName : ModuleName
    , referencedModule : ModuleName
    , oldName : String
    , range : Range
    , nameRange : Range
    }


type alias ModuleContext =
    { moduleName : ModuleName
    , moduleKey : ModuleKey
    , lookupTable : ModuleNameLookupTable
    , renames : List Rename
    , usages : List Usage
    , exposingFixes : List ExposingFix
    }


initialProjectContext : ProjectContext
initialProjectContext =
    { renames = []
    , usages = []
    , exposingFixes = []
    }


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
                , renames = []
                , usages = []
                , exposingFixes = []
                }
            )
            |> Rule.withModuleName
            |> Rule.withModuleKey
            |> Rule.withModuleNameLookupTable
    , fromModuleToProject =
        Rule.initContextCreator
            (\moduleContext ->
                { renames = moduleContext.renames
                , usages = moduleContext.usages
                , exposingFixes = moduleContext.exposingFixes
                }
            )
    , foldProjectContexts =
        \l r ->
            { renames = l.renames ++ r.renames
            , usages = l.usages ++ r.usages
            , exposingFixes = l.exposingFixes ++ r.exposingFixes
            }
    }


moduleVisitor :
    Rule.ModuleRuleSchema {} ModuleContext
    -> Rule.ModuleRuleSchema { hasAtLeastOneVisitor : () } ModuleContext
moduleVisitor schema =
    schema
        |> Rule.withModuleDefinitionVisitor moduleDefinitionVisitor
        |> Rule.withImportVisitor importVisitor
        |> Rule.withDeclarationEnterVisitor declarationVisitor
        |> Rule.withExpressionEnterVisitor expressionVisitor


moduleDefinitionVisitor : Node Module.Module -> ModuleContext -> ( List (Rule.Error {}), ModuleContext )
moduleDefinitionVisitor moduleNode context =
    let
        fixes =
            collectExposingFixes context.moduleKey context.moduleName Nothing (Module.exposingList (Node.value moduleNode))
    in
    ( [], { context | exposingFixes = fixes ++ context.exposingFixes } )


importVisitor : Node Import -> ModuleContext -> ( List (Rule.Error {}), ModuleContext )
importVisitor (Node _ import_) context =
    case import_.exposingList of
        Just (Node _ exposing_) ->
            let
                importModuleName =
                    Node.value import_.moduleName

                fixes =
                    collectExposingFixes context.moduleKey context.moduleName (Just importModuleName) exposing_
            in
            ( [], { context | exposingFixes = fixes ++ context.exposingFixes } )

        Nothing ->
            ( [], context )


collectExposingFixes : ModuleKey -> ModuleName -> Maybe ModuleName -> Exposing -> List ExposingFix
collectExposingFixes moduleKey moduleName referencedModule exposing_ =
    case exposing_ of
        All _ ->
            []

        Explicit exposes ->
            List.filterMap
                (\(Node range expose) ->
                    case expose of
                        FunctionExpose name ->
                            if needsRename name then
                                Just
                                    { moduleKey = moduleKey
                                    , moduleName = moduleName
                                    , oldName = name
                                    , range = range
                                    , referencedModule = referencedModule
                                    }

                            else
                                Nothing

                        _ ->
                            Nothing
                )
                exposes


declarationVisitor : Node Declaration -> ModuleContext -> ( List (Rule.Error {}), ModuleContext )
declarationVisitor (Node _ declaration) context =
    case declaration of
        FunctionDeclaration function ->
            let
                nameNode : Node String
                nameNode =
                    Node.value function.declaration |> .name

                name : String
                name =
                    Node.value nameNode

                signatureRange : Maybe Range
                signatureRange =
                    function.signature
                        |> Maybe.map (\(Node _ sig) -> Node.range sig.name)
            in
            case checkName name of
                Just { newName, message, detail } ->
                    ( []
                    , { context
                        | renames =
                            { moduleName = context.moduleName
                            , moduleKey = context.moduleKey
                            , oldName = name
                            , newName = newName
                            , nameRange = Node.range nameNode
                            , signatureRange = signatureRange
                            , message = message
                            , detail = detail
                            }
                                :: context.renames
                      }
                    )

                Nothing ->
                    ( [], context )

        _ ->
            ( [], context )


expressionVisitor : Node Expression -> ModuleContext -> ( List (Rule.Error {}), ModuleContext )
expressionVisitor (Node range expression) context =
    case expression of
        FunctionOrValue moduleParts name ->
            case ModuleNameLookupTable.moduleNameAt context.lookupTable range of
                Just referencedModule ->
                    if needsRename name then
                        let
                            nameRange : Range
                            nameRange =
                                { start =
                                    { row = range.end.row
                                    , column = range.end.column - String.length name
                                    }
                                , end = range.end
                                }
                        in
                        ( []
                        , { context
                            | usages =
                                { moduleKey = context.moduleKey
                                , moduleName = context.moduleName
                                , referencedModule = referencedModule
                                , oldName = name
                                , range = range
                                , nameRange = nameRange
                                }
                                    :: context.usages
                          }
                        )

                    else
                        ( [], context )

                Nothing ->
                    ( [], context )

        _ ->
            ( [], context )


needsRename : String -> Bool
needsRename name =
    (String.endsWith "Encoder" name && String.length name > 7)
        || (String.endsWith "Decoder" name && String.length name > 7)
        || (String.endsWith "Encode" name && String.length name > 6)
        || (String.endsWith "Decode" name && String.length name > 6)


type alias RenameInfo =
    { newName : String
    , message : String
    , detail : String
    }


checkName : String -> Maybe RenameInfo
checkName name =
    if String.endsWith "Encoder" name && String.length name > 7 then
        Just
            { newName = "encode" ++ capitalize (String.dropRight 7 name)
            , message = name ++ " should be named " ++ "encode" ++ capitalize (String.dropRight 7 name)
            , detail = "Encoders should be named `encodeTypeName` instead of `typeNameEncoder` for consistency."
            }

    else if String.endsWith "Decoder" name && String.length name > 7 then
        Just
            { newName = "decode" ++ capitalize (String.dropRight 7 name)
            , message = name ++ " should be named " ++ "decode" ++ capitalize (String.dropRight 7 name)
            , detail = "Decoders should be named `decodeTypeName` instead of `typeNameDecoder` for consistency."
            }

    else if String.endsWith "Encode" name && String.length name > 6 then
        Just
            { newName = "encode" ++ capitalize (String.dropRight 6 name)
            , message = name ++ " should be named " ++ "encode" ++ capitalize (String.dropRight 6 name)
            , detail = "Encoders should be named `encodeTypeName` instead of `typeNameEncode` for consistency."
            }

    else if String.endsWith "Decode" name && String.length name > 6 then
        Just
            { newName = "decode" ++ capitalize (String.dropRight 6 name)
            , message = name ++ " should be named " ++ "decode" ++ capitalize (String.dropRight 6 name)
            , detail = "Decoders should be named `decodeTypeName` instead of `typeNameDecode` for consistency."
            }

    else
        Nothing


finalProjectEvaluation : ProjectContext -> List (Rule.Error { useErrorForModule : () })
finalProjectEvaluation context =
    let
        renameErrors : List (Rule.Error { useErrorForModule : () })
        renameErrors =
            List.map
                (\rename ->
                    let
                        signatureFix : List Fix.Fix
                        signatureFix =
                            case rename.signatureRange of
                                Just sigRange ->
                                    [ Fix.replaceRangeBy sigRange rename.newName ]

                                Nothing ->
                                    []

                        sameModuleUsageFixes : List Fix.Fix
                        sameModuleUsageFixes =
                            context.usages
                                |> List.filterMap
                                    (\usage ->
                                        if
                                            (usage.referencedModule == rename.moduleName || usage.referencedModule == [])
                                                && (usage.oldName == rename.oldName)
                                                && (usage.moduleName == rename.moduleName)
                                        then
                                            Just (Fix.replaceRangeBy usage.nameRange rename.newName)

                                        else
                                            Nothing
                                    )

                        sameModuleExposingFixes : List Fix.Fix
                        sameModuleExposingFixes =
                            context.exposingFixes
                                |> List.filterMap
                                    (\ef ->
                                        if
                                            (ef.moduleName == rename.moduleName)
                                                && (ef.oldName == rename.oldName)
                                                && (ef.referencedModule == Nothing)
                                        then
                                            Just (Fix.replaceRangeBy ef.range rename.newName)

                                        else
                                            Nothing
                                    )
                    in
                    Rule.errorForModuleWithFix
                        rename.moduleKey
                        { message = rename.message
                        , details = [ rename.detail ]
                        }
                        rename.nameRange
                        (Fix.replaceRangeBy rename.nameRange rename.newName
                            :: signatureFix
                            ++ sameModuleUsageFixes
                            ++ sameModuleExposingFixes
                        )
                )
                context.renames

        crossModuleUsageErrors : List (Rule.Error { useErrorForModule : () })
        crossModuleUsageErrors =
            context.usages
                |> List.filterMap
                    (\usage ->
                        let
                            matchingRename =
                                context.renames
                                    |> List.filter
                                        (\rename ->
                                            (rename.moduleName == usage.referencedModule)
                                                && (rename.oldName == usage.oldName)
                                        )
                                    |> List.head
                        in
                        case matchingRename of
                            Just rename ->
                                if usage.moduleName /= rename.moduleName then
                                    let
                                        importExposingFixes =
                                            context.exposingFixes
                                                |> List.filterMap
                                                    (\ef ->
                                                        if
                                                            (ef.moduleName == usage.moduleName)
                                                                && (ef.oldName == rename.oldName)
                                                                && (ef.referencedModule == Just rename.moduleName)
                                                        then
                                                            Just (Fix.replaceRangeBy ef.range rename.newName)

                                                        else
                                                            Nothing
                                                    )
                                    in
                                    Just
                                        (Rule.errorForModuleWithFix
                                            usage.moduleKey
                                            { message = usage.oldName ++ " should be named " ++ rename.newName
                                            , details = [ rename.detail ]
                                            }
                                            usage.range
                                            (Fix.replaceRangeBy usage.nameRange rename.newName
                                                :: importExposingFixes
                                            )
                                        )

                                else
                                    Nothing

                            Nothing ->
                                Nothing
                    )

        importOnlyExposingErrors : List (Rule.Error { useErrorForModule : () })
        importOnlyExposingErrors =
            context.exposingFixes
                |> List.filterMap
                    (\ef ->
                        case ef.referencedModule of
                            Just refMod ->
                                let
                                    matchingRename =
                                        context.renames
                                            |> List.filter
                                                (\rename ->
                                                    (rename.moduleName == refMod)
                                                        && (rename.oldName == ef.oldName)
                                                )
                                            |> List.head

                                    hasUsageInSameModule =
                                        context.usages
                                            |> List.any
                                                (\usage ->
                                                    (usage.moduleName == ef.moduleName)
                                                        && (usage.referencedModule == refMod)
                                                        && (usage.oldName == ef.oldName)
                                                )
                                in
                                case matchingRename of
                                    Just rename ->
                                        if not hasUsageInSameModule then
                                            Just
                                                (Rule.errorForModuleWithFix
                                                    ef.moduleKey
                                                    { message = ef.oldName ++ " should be named " ++ rename.newName
                                                    , details = [ rename.detail ]
                                                    }
                                                    ef.range
                                                    [ Fix.replaceRangeBy ef.range rename.newName ]
                                                )

                                        else
                                            Nothing

                                    Nothing ->
                                        Nothing

                            Nothing ->
                                Nothing
                    )
    in
    renameErrors ++ crossModuleUsageErrors ++ importOnlyExposingErrors


capitalize : String -> String
capitalize str =
    case String.uncons str of
        Just ( first, rest ) ->
            String.fromChar (Char.toUpper first) ++ rest

        Nothing ->
            str
