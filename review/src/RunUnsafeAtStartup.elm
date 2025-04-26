module RunUnsafeAtStartup exposing (rule)

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Expression exposing (Expression(..), LetBlock, LetDeclaration(..))
import Elm.Syntax.Node as Node exposing (Node(..))
import Review.ModuleNameLookupTable exposing (ModuleNameLookupTable)
import Review.Rule as Rule exposing (Rule)


rule : Rule
rule =
    Rule.newModuleRuleSchemaUsingContextCreator "RunUnsafeAtStartup" initialContext
        |> Rule.withDeclarationEnterVisitor declarationEnterVisitor
        |> Rule.withDeclarationExitVisitor declarationExitVisitor
        |> Rule.withExpressionEnterVisitor expressionEnterVisitor
        |> Rule.withExpressionExitVisitor expressionExitVisitor
        |> Rule.withLetDeclarationEnterVisitor letEnterVisitor
        |> Rule.withLetDeclarationExitVisitor letExitVisitor
        |> Rule.fromModuleRuleSchema


letEnterVisitor : Node LetBlock -> Node LetDeclaration -> Context -> ( List (Rule.Error {}), Context )
letEnterVisitor _ letDeclaration context =
    case Node.value letDeclaration of
        LetFunction function ->
            let
                isConstant =
                    function.declaration |> Node.value |> .arguments |> List.isEmpty
            in
            ( []
            , { context
                | currentDeclarationIsConstantStack =
                    isConstant :: context.currentDeclarationIsConstantStack
              }
            )

        LetDestructuring _ _ ->
            ( [], context )


letExitVisitor : Node LetBlock -> Node LetDeclaration -> Context -> ( List (Rule.Error {}), Context )
letExitVisitor _ letDeclaration context =
    case Node.value letDeclaration of
        LetFunction _ ->
            ( []
            , { context
                | currentDeclarationIsConstantStack =
                    List.drop 1 context.currentDeclarationIsConstantStack
              }
            )

        LetDestructuring _ _ ->
            ( [], context )


type alias Context =
    { currentDeclarationIsConstantStack : List Bool
    , lookupTable : ModuleNameLookupTable
    }


declarationExitVisitor : a -> Context -> ( List (Rule.Error {}), Context )
declarationExitVisitor _ context =
    ( [], { context | currentDeclarationIsConstantStack = [] } )


declarationEnterVisitor : Node Declaration -> Context -> ( List (Rule.Error {}), Context )
declarationEnterVisitor declaration context =
    ( []
    , case Node.value declaration of
        FunctionDeclaration function ->
            { context
                | currentDeclarationIsConstantStack =
                    function.declaration
                        |> Node.value
                        |> .arguments
                        |> List.isEmpty
                        |> (\a -> a :: context.currentDeclarationIsConstantStack)
            }

        AliasDeclaration _ ->
            context

        CustomTypeDeclaration _ ->
            context

        PortDeclaration _ ->
            context

        InfixDeclaration _ ->
            context

        Destructuring _ _ ->
            context
    )


initialContext : Rule.ContextCreator () Context
initialContext =
    Rule.initContextCreator
        (\lookupTable () ->
            { currentDeclarationIsConstantStack = []
            , lookupTable = lookupTable
            }
        )
        |> Rule.withModuleNameLookupTable


isValid : Context -> Bool
isValid context =
    List.all identity context.currentDeclarationIsConstantStack


expressionExitVisitor : Node Expression -> Context -> ( List (Rule.Error {}), Context )
expressionExitVisitor expression context =
    case Node.value expression of
        LambdaExpression _ ->
            ( []
            , { context
                | currentDeclarationIsConstantStack =
                    List.drop 1 context.currentDeclarationIsConstantStack
              }
            )

        _ ->
            ( [], context )


expressionEnterVisitor : Node Expression -> Context -> ( List (Rule.Error {}), Context )
expressionEnterVisitor expression context =
    case Node.value expression of
        LambdaExpression _ ->
            ( []
            , { context
                | currentDeclarationIsConstantStack =
                    False
                        :: context.currentDeclarationIsConstantStack
              }
            )

        FunctionOrValue _ _ ->
            case Review.ModuleNameLookupTable.moduleNameFor context.lookupTable expression of
                Just actualModuleName ->
                    if not (isValid context) && actualModuleName == [ "Unsafe" ] then
                        ( [ Rule.error
                                { message = "Only use Unsafe functions in places where they will be evaluated at app startup (aka constant functions and not inside lambdas)"
                                , details =
                                    [ "If you use an Unsafe function in a function that isn't evaluated at program start, you won't know if it will crash until potentially much later (if you're especially unlucky, that could be in production)."
                                    ]
                                }
                                (Node.range expression)
                          ]
                        , context
                        )

                    else
                        ( [], context )

                Nothing ->
                    ( [], context )

        _ ->
            ( [], context )
