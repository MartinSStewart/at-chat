module NoUnusedFields exposing (rule)

import Dict exposing (Dict)
import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Expression exposing (Expression(..), LetDeclaration(..), RecordSetter)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Pattern exposing (Pattern(..))
import Elm.Syntax.Range exposing (Location, Range)
import Elm.Syntax.TypeAnnotation exposing (TypeAnnotation(..))
import Review.Fix
import Review.Rule as Rule exposing (ModuleKey, Rule)
import Set exposing (Set)


rule : Rule
rule =
    Rule.newProjectRuleSchema "NoUnusedFields" initialContext
        |> Rule.withModuleVisitor moduleVisitor
        |> Rule.withFinalProjectEvaluation finalModuleEvaluation
        |> Rule.withModuleContextUsingContextCreator conversion
        |> Rule.fromProjectRuleSchema


initModuleContext : ModuleKey -> Bool -> ProjectContext -> ModuleContext
initModuleContext moduleKey isFileIgnored _ =
    { definedFields = []
    , inRecordAssignment = []
    , recordAssignmentRanges = Dict.empty
    , recordAssignments = Dict.empty
    , usedFields = Set.empty
    , moduleKey = moduleKey
    , skipModule = isFileIgnored
    }


conversion :
    { fromProjectToModule : Rule.ContextCreator ProjectContext ModuleContext
    , fromModuleToProject : Rule.ContextCreator ModuleContext ProjectContext
    , foldProjectContexts : ProjectContext -> ProjectContext -> ProjectContext
    }
conversion =
    { fromProjectToModule =
        Rule.initContextCreator initModuleContext
            |> Rule.withModuleKey
            |> Rule.withIsFileIgnored
    , fromModuleToProject = Rule.initContextCreator fromModuleToProject
    , foldProjectContexts = foldProjectContexts
    }


foldProjectContexts : ProjectContext -> ProjectContext -> ProjectContext
foldProjectContexts l r =
    { definedFields = l.definedFields ++ r.definedFields
    , usedFields = Set.union l.usedFields r.usedFields
    , recordAssignments =
        Dict.foldl
            (\field ranges dict ->
                Dict.update
                    field
                    (\maybe -> Maybe.withDefault [] maybe |> (\list -> ranges ++ list) |> Just)
                    dict
            )
            r.recordAssignments
            l.recordAssignments
    }


fromModuleToProject : ModuleContext -> ProjectContext
fromModuleToProject moduleContext =
    { definedFields =
        List.map
            (\( range, name ) -> ( moduleContext.moduleKey, range, name ))
            moduleContext.definedFields
    , usedFields = moduleContext.usedFields
    , recordAssignments = moduleContext.recordAssignments
    }


moduleVisitor :
    Rule.ModuleRuleSchema {} ModuleContext
    -> Rule.ModuleRuleSchema { hasAtLeastOneVisitor : () } ModuleContext
moduleVisitor visitor =
    visitor
        |> Rule.withExpressionEnterVisitor (\expression context -> ( [], expressionVisitor expression context ))
        |> Rule.withExpressionExitVisitor (\expression context -> ( [], expressionVisitorExit expression context ))
        |> Rule.withDeclarationExitVisitor declarationVisitor


type alias ProjectContext =
    { definedFields : List ( ModuleKey, Range, String )
    , usedFields : Set String
    , recordAssignments : Dict String (List Range)
    }


type alias ModuleContext =
    { definedFields : List ( Range, String )
    , inRecordAssignment : List String
    , recordAssignmentRanges : Dict ( ( Int, Int ), ( Int, Int ) ) String
    , recordAssignments : Dict String (List Range)
    , usedFields : Set String
    , skipModule : Bool
    , moduleKey : ModuleKey
    }


rangeAsTuple : Range -> ( ( Int, Int ), ( Int, Int ) )
rangeAsTuple range =
    ( ( range.start.row
      , range.start.column
      )
    , ( range.end.row
      , range.end.column
      )
    )


tupleAsRange : ( ( Int, Int ), ( Int, Int ) ) -> Range
tupleAsRange ( ( startRow, startColumn ), ( endRow, endColumn ) ) =
    { start = { row = startRow, column = startColumn }
    , end = { row = endRow, column = endColumn }
    }


initialContext : ProjectContext
initialContext =
    { definedFields = []
    , usedFields = Set.empty
    , recordAssignments = Dict.empty
    }


declarationVisitor : Node Declaration -> ModuleContext -> ( List (Rule.Error {}), ModuleContext )
declarationVisitor declaration context =
    if context.skipModule then
        ( [], context )

    else
        ( []
        , case Node.value declaration of
            AliasDeclaration typeAlias ->
                case Node.value typeAlias.typeAnnotation of
                    Record items ->
                        List.foldl
                            (\(Node range ( Node _ field, _ )) ( previousRange, context2 ) ->
                                ( Just range
                                , { context2
                                    | definedFields =
                                        ( { range
                                            | start =
                                                case previousRange of
                                                    Just { end } ->
                                                        end

                                                    Nothing ->
                                                        range.start
                                          }
                                        , field
                                        )
                                            :: context2.definedFields
                                  }
                                )
                            )
                            ( Nothing, context )
                            items
                            |> Tuple.second

                    GenericType string ->
                        context

                    Typed node nodes ->
                        context

                    Unit ->
                        context

                    Tupled nodes ->
                        context

                    GenericRecord _ (Node _ items) ->
                        List.foldl
                            (\(Node range ( Node _ field, _ )) ( previousRange, context2 ) ->
                                ( Just range
                                , { context2
                                    | definedFields =
                                        ( { range
                                            | start =
                                                case previousRange of
                                                    Just { end } ->
                                                        end

                                                    Nothing ->
                                                        range.start
                                          }
                                        , field
                                        )
                                            :: context2.definedFields
                                  }
                                )
                            )
                            ( Nothing, context )
                            items
                            |> Tuple.second

                    FunctionTypeAnnotation node _ ->
                        context

            Destructuring pattern _ ->
                patternVisitor pattern context

            FunctionDeclaration function ->
                Node.value function.declaration
                    |> .arguments
                    |> List.foldl patternVisitor context

            CustomTypeDeclaration _ ->
                context

            PortDeclaration _ ->
                context

            InfixDeclaration _ ->
                context
        )


patternVisitor : Node Pattern -> ModuleContext -> ModuleContext
patternVisitor pattern context =
    case Node.value pattern of
        RecordPattern fields ->
            { context
                | usedFields =
                    List.foldl
                        (\(Node _ name) acc ->
                            markFieldAsUsed context.inRecordAssignment name acc
                        )
                        context.usedFields
                        fields
            }

        TuplePattern nodes ->
            List.foldl patternVisitor context nodes

        UnConsPattern a b ->
            patternVisitor a (patternVisitor b context)

        ListPattern nodes ->
            List.foldl patternVisitor context nodes

        NamedPattern _ nodes ->
            List.foldl patternVisitor context nodes

        AsPattern node _ ->
            patternVisitor node context

        ParenthesizedPattern node ->
            patternVisitor node context

        AllPattern ->
            context

        UnitPattern ->
            context

        CharPattern _ ->
            context

        StringPattern _ ->
            context

        IntPattern _ ->
            context

        HexPattern _ ->
            context

        FloatPattern _ ->
            context

        VarPattern _ ->
            context


markFieldAsUsed : List String -> String -> Set String -> Set String
markFieldAsUsed inRecordAssignment name usedFields =
    if List.member name inRecordAssignment then
        usedFields

    else
        Set.insert name usedFields


expressionVisitor : Node Expression -> ModuleContext -> ModuleContext
expressionVisitor expression context =
    if context.skipModule then
        context

    else
        case Dict.get (rangeAsTuple (Node.range expression)) context.recordAssignmentRanges of
            Just field ->
                expressionVisitorHelp expression
                    { context
                        | inRecordAssignment =
                            field :: context.inRecordAssignment
                    }

            Nothing ->
                expressionVisitorHelp expression context


expressionVisitorHelp : Node Expression -> ModuleContext -> ModuleContext
expressionVisitorHelp expression context =
    if context.skipModule then
        context

    else
        case Node.value expression of
            CaseExpression caseBlock ->
                List.foldl (\( pattern, _ ) context2 -> patternVisitor pattern context2) context caseBlock.cases

            LambdaExpression lambda ->
                List.foldl patternVisitor context lambda.args

            RecordAccess _ (Node _ field) ->
                { context | usedFields = markFieldAsUsed context.inRecordAssignment field context.usedFields }

            RecordAccessFunction field ->
                { context | usedFields = markFieldAsUsed context.inRecordAssignment (field |> String.replace "." "") context.usedFields }

            LetExpression { declarations } ->
                List.foldl
                    (\declaration context2 ->
                        case Node.value declaration of
                            LetDestructuring pattern2 _ ->
                                patternVisitor pattern2 context2

                            LetFunction function ->
                                Node.value function.declaration
                                    |> .arguments
                                    |> List.foldl patternVisitor context2
                    )
                    context
                    declarations

            RecordExpr assignments ->
                saveRecordAssignments assignments context

            RecordUpdateExpression _ assignments ->
                saveRecordAssignments assignments context

            GLSLExpression text ->
                let
                    text2 : String
                    text2 =
                        String.replace "\n" " " text
                            |> String.replace "\u{000D}" " "

                    getValues : String -> List String
                    getValues valueName =
                        String.split valueName text2
                            |> List.filterMap
                                (\text3 ->
                                    case String.split " " (String.trim text3) of
                                        _ :: name :: _ ->
                                            String.replace ";" "" name |> Just

                                        _ ->
                                            Nothing
                                )
                in
                { context
                    | usedFields =
                        List.foldl
                            (markFieldAsUsed context.inRecordAssignment)
                            context.usedFields
                            (getValues "attribute"
                                ++ getValues "uniform"
                                ++ getValues "varying"
                            )
                }

            _ ->
                context


expressionVisitorExit : Node Expression -> ModuleContext -> ModuleContext
expressionVisitorExit expression context =
    if context.skipModule then
        context

    else
        let
            range =
                rangeAsTuple (Node.range expression)
        in
        if Dict.member range context.recordAssignmentRanges then
            { context
                | inRecordAssignment = List.drop 1 context.inRecordAssignment
                , recordAssignmentRanges = Dict.remove range context.recordAssignmentRanges
            }

        else
            context


saveRecordAssignments : List (Node RecordSetter) -> ModuleContext -> ModuleContext
saveRecordAssignments assignments context =
    let
        recordAssignmentRanges : Dict ( ( Int, Int ), ( Int, Int ) ) String
        recordAssignmentRanges =
            List.foldl
                (\(Node _ ( Node _ fieldName, Node range _ )) acc ->
                    Dict.insert (rangeAsTuple range) fieldName acc
                )
                context.recordAssignmentRanges
                assignments
    in
    { context
        | recordAssignmentRanges = recordAssignmentRanges
        , recordAssignments =
            List.foldl
                (\(Node range ( Node _ fieldName, _ )) ( previousRange, acc ) ->
                    ( Just range
                    , Dict.update
                        fieldName
                        (\maybe ->
                            Maybe.withDefault [] maybe
                                |> (\list ->
                                        (case previousRange of
                                            Just { end } ->
                                                { range | start = end }

                                            Nothing ->
                                                range
                                        )
                                            :: list
                                   )
                                |> Just
                        )
                        acc
                    )
                )
                ( Nothing, context.recordAssignments )
                assignments
                |> Tuple.second
    }


finalModuleEvaluation : ProjectContext -> List (Rule.Error { useErrorForModule : () })
finalModuleEvaluation context =
    List.filterMap
        (\( key, range, field ) ->
            if Set.member field context.usedFields then
                Nothing

            else
                Rule.errorForModuleWithFix
                    key
                    { message = "This record field is defined but is never read from. You should use it or remove it."
                    , details = []
                    }
                    range
                    (Review.Fix.removeRange range
                        :: (case Dict.get field context.recordAssignments of
                                Just list ->
                                    List.map Review.Fix.removeRange list

                                Nothing ->
                                    []
                           )
                    )
                    |> Just
        )
        context.definedFields
