module EncoderDecoderNaming exposing (rule)

{-| Enforces that encoder/decoder functions are named `encodeTypeName` and `decodeTypeName`
rather than `typeNameEncoder` and `typeNameDecoder`. Fixes all usages across the project.
-}

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Expression exposing (Expression(..))
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
    }


initialProjectContext : ProjectContext
initialProjectContext =
    { renames = []
    , usages = []
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
                }
            )
    , foldProjectContexts =
        \l r ->
            { renames = l.renames ++ r.renames
            , usages = l.usages ++ r.usages
            }
    }


moduleVisitor :
    Rule.ModuleRuleSchema {} ModuleContext
    -> Rule.ModuleRuleSchema { hasAtLeastOneVisitor : () } ModuleContext
moduleVisitor schema =
    schema
        |> Rule.withDeclarationEnterVisitor declarationVisitor
        |> Rule.withExpressionEnterVisitor expressionVisitor


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
                                            (usage.referencedModule == rename.moduleName)
                                                && (usage.oldName == rename.oldName)
                                                && (usage.moduleName == rename.moduleName)
                                        then
                                            Just (Fix.replaceRangeBy usage.nameRange rename.newName)

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
                                    Just
                                        (Rule.errorForModuleWithFix
                                            usage.moduleKey
                                            { message = usage.oldName ++ " should be named " ++ rename.newName
                                            , details = [ rename.detail ]
                                            }
                                            usage.range
                                            [ Fix.replaceRangeBy usage.nameRange rename.newName ]
                                        )

                                else
                                    Nothing

                            Nothing ->
                                Nothing
                    )
    in
    renameErrors ++ crossModuleUsageErrors


capitalize : String -> String
capitalize str =
    case String.uncons str of
        Just ( first, rest ) ->
            String.fromChar (Char.toUpper first) ++ rest

        Nothing ->
            str
