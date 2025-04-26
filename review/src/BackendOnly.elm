module BackendOnly exposing (rule)

import Elm.Syntax.Declaration as Declaration exposing (Declaration)
import Elm.Syntax.Expression as Expression exposing (Expression)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Range exposing (Range)
import FastDict as Dict exposing (Dict)
import FastSet as Set exposing (Set)
import List.Extra
import Review.ModuleNameLookupTable as ModuleNameLookupTable exposing (ModuleNameLookupTable)
import Review.Rule as Rule exposing (ModuleKey, Rule)


rule :
    { modules : List ModuleName
    , functions : List ( ModuleName, String )
    }
    -> Rule
rule config =
    Rule.newProjectRuleSchema "BackendOnly" (initialContext config)
        |> Rule.withModuleVisitor moduleVisitor
        |> Rule.withFinalProjectEvaluation finalProjectEvaluation
        |> Rule.withContextFromImportedModules
        |> Rule.withModuleContextUsingContextCreator conversion
        |> Rule.fromProjectRuleSchema


fromModuleToProject : Rule.ContextCreator ModuleContext ProjectContext
fromModuleToProject =
    Rule.initContextCreator
        (\moduleContext ->
            { config = moduleContext.config
            , forbidden =
                moduleContext.forbidden
                    |> Dict.union (findAdditionalForbidden moduleContext.forbidden moduleContext.calls)
            , accountedForModules =
                if Set.member moduleContext.moduleName moduleContext.config.modules then
                    Set.singleton moduleContext.moduleName

                else
                    Set.empty
            , accountedForFunctions = moduleContext.functionDeclarations
            }
        )


conversion :
    { fromProjectToModule : Rule.ContextCreator ProjectContext ModuleContext
    , fromModuleToProject : Rule.ContextCreator ModuleContext ProjectContext
    , foldProjectContexts : ProjectContext -> ProjectContext -> ProjectContext
    }
conversion =
    { fromProjectToModule =
        Rule.initContextCreator
            (\moduleName moduleKey moduleNameLookupTable { config, forbidden } ->
                { config = config
                , moduleName = moduleName
                , moduleKey = moduleKey
                , forbidden = forbidden
                , backendOnly = Set.member moduleName config.modules
                , moduleNameLookupTable = moduleNameLookupTable
                , currentFunction = Nothing
                , calls = Dict.empty
                , functionDeclarations = Set.empty
                }
            )
            |> Rule.withModuleName
            |> Rule.withModuleKey
            |> Rule.withModuleNameLookupTable
    , fromModuleToProject = fromModuleToProject
    , foldProjectContexts =
        \l r ->
            { config = l.config
            , forbidden = Dict.union l.forbidden r.forbidden
            , accountedForModules = Set.union l.accountedForModules r.accountedForModules
            , accountedForFunctions = Set.union l.accountedForFunctions r.accountedForFunctions
            }
    }


findAdditionalForbidden :
    Dict
        ( ModuleName, String )
        { key : ModuleKey
        , range : Range
        , trace : List ( ModuleName, String )
        }
    ->
        Dict
            ( ModuleName, String )
            { key : ModuleKey
            , range : Range
            , targets : List ( ModuleName, String )
            }
    ->
        Dict
            ( ModuleName, String )
            { key : ModuleKey
            , range : Range
            , trace : List ( ModuleName, String )
            }
findAdditionalForbidden forbidden calls =
    let
        cleanCalls :
            Dict
                ( ModuleName, String )
                { key : ModuleKey
                , range : Range
                , targets : List ( ModuleName, String )
                }
        cleanCalls =
            -- If it's already forbidden we don't need to deal with it
            Dict.diff calls forbidden

        newForbidden :
            Dict
                ( ModuleName, String )
                { key : ModuleKey
                , range : Range
                , trace : List ( ModuleName, String )
                }
        newForbidden =
            cleanCalls
                |> Dict.toList
                |> List.filterMap
                    (\( name, { key, range, targets } ) ->
                        List.Extra.findMap
                            (\target ->
                                Dict.get target forbidden
                                    |> Maybe.map
                                        (\{ trace } ->
                                            ( name
                                            , { key = key
                                              , range = range
                                              , trace = target :: trace
                                              }
                                            )
                                        )
                            )
                            targets
                    )
                |> Dict.fromList
    in
    if Dict.isEmpty newForbidden then
        forbidden

    else
        findAdditionalForbidden (Dict.union forbidden newForbidden) cleanCalls


type alias Config =
    { modules : Set ModuleName
    , functions : Set ( ModuleName, String )
    }


type alias ProjectContext =
    { config : Config
    , forbidden :
        Dict
            ( ModuleName, String )
            { key : ModuleKey
            , range : Range
            , trace : List ( ModuleName, String )
            }
    , accountedForModules : Set ModuleName
    , accountedForFunctions : Set ( ModuleName, String )
    }


type alias ModuleContext =
    { config : Config
    , moduleName : ModuleName
    , moduleKey : ModuleKey
    , moduleNameLookupTable : ModuleNameLookupTable
    , backendOnly : Bool
    , forbidden :
        Dict
            ( ModuleName, String )
            { key : ModuleKey
            , range : Range
            , trace : List ( ModuleName, String )
            }
    , currentFunction : Maybe (Node String)

    -- Internal calls: key is fully qualified function name, targets is list of called same-module functions
    , calls :
        Dict
            ( ModuleName, String )
            { key : ModuleKey
            , range : Range
            , targets : List ( ModuleName, String )
            }
    , functionDeclarations : Set ( ModuleName, String )
    }


initialContext :
    { modules : List ModuleName
    , functions : List ( ModuleName, String )
    }
    -> ProjectContext
initialContext config =
    { config =
        { modules = Set.fromList config.modules
        , functions = Set.fromList config.functions
        }
    , forbidden = Dict.empty
    , accountedForModules = Set.empty
    , accountedForFunctions = Set.empty
    }


listToText : List String -> String
listToText list =
    case List.reverse list of
        [] ->
            ""

        [ single ] ->
            single

        [ one, two ] ->
            two ++ " and " ++ one

        one :: many ->
            String.join ", " (List.reverse many) ++ ", and " ++ one


moduleNameToString : ModuleName -> String
moduleNameToString moduleName =
    String.join "." moduleName


functionToString : ( ModuleName, String ) -> String
functionToString ( moduleName, function ) =
    moduleNameToString moduleName ++ "." ++ function


finalProjectEvaluation : ProjectContext -> List (Rule.Error { useErrorForModule : () })
finalProjectEvaluation context =
    let
        missingModulesOrFunctions =
            case Set.diff context.config.modules context.accountedForModules |> Set.toList of
                [] ->
                    case Set.diff context.config.functions context.accountedForFunctions |> Set.toList of
                        [] ->
                            []

                        [ function ] ->
                            [ Rule.globalError
                                { message = "Function " ++ functionToString function ++ " not found"
                                , details = [ functionToString function ++ " is a function you told me to check for but I can't find it. Did you rename or delete it?" ]
                                }
                            ]

                        many ->
                            [ Rule.globalError
                                { message = "Some functions not found"
                                , details =
                                    [ listToText (List.map functionToString many)
                                        ++ " are functions you told me to check for but I can't find them. Did you rename or delete them?"
                                    ]
                                }
                            ]

                [ moduleName ] ->
                    [ Rule.globalError
                        { message = "Module " ++ moduleNameToString moduleName ++ " not found"
                        , details = [ moduleNameToString moduleName ++ " is a module you told me to check for but I can't find it. Did you rename or delete it?" ]
                        }
                    ]

                many ->
                    [ Rule.globalError
                        { message = "Some modules not found"
                        , details =
                            [ listToText (List.map moduleNameToString many)
                                ++ " are modules you told me to check for but I can't find them. Did you rename or delete them?"
                            ]
                        }
                    ]
    in
    missingModulesOrFunctions
        ++ (case Dict.get ( [ "Frontend" ], "app" ) context.forbidden of
                Nothing ->
                    []

                Just app ->
                    [ Rule.errorForModule app.key
                        { message = "Found usage of forbidden functions"
                        , details =
                            [ String.join " -> " ("Frontend.app" :: List.map functionToString app.trace) ]
                        }
                        app.range
                    ]
           )


moduleVisitor :
    Rule.ModuleRuleSchema {} ModuleContext
    -> Rule.ModuleRuleSchema { hasAtLeastOneVisitor : () } ModuleContext
moduleVisitor visitor =
    visitor
        |> Rule.withDeclarationListVisitor declarationListVisitor
        |> Rule.withDeclarationEnterVisitor declarationEnterVisitor
        |> Rule.withExpressionEnterVisitor expressionVisitor


declarationListVisitor : List (Node Declaration) -> ModuleContext -> ( List (Rule.Error {}), ModuleContext )
declarationListVisitor declarations context =
    ( []
    , { context
        | forbidden =
            Dict.union context.forbidden
                (declarations
                    |> List.filterMap
                        (\(Node _ declaration) ->
                            case declaration of
                                Declaration.FunctionDeclaration function ->
                                    let
                                        (Node functionRange functionName) =
                                            functionToName function

                                        fullName =
                                            ( context.moduleName, functionName )
                                    in
                                    if context.backendOnly || Set.member fullName context.config.functions then
                                        ( fullName
                                        , { key = context.moduleKey
                                          , range = functionRange
                                          , trace = []
                                          }
                                        )
                                            |> Just

                                    else
                                        Nothing

                                _ ->
                                    Nothing
                        )
                    |> Dict.fromList
                )
      }
    )


functionToName : Expression.Function -> Node String
functionToName function =
    (Node.value function.declaration).name


declarationEnterVisitor : Node Declaration -> ModuleContext -> ( List (Rule.Error {}), ModuleContext )
declarationEnterVisitor (Node _ declaration) context =
    case declaration of
        Declaration.FunctionDeclaration function ->
            ( []
            , { context
                | currentFunction = Just (functionToName function)
                , functionDeclarations =
                    Set.insert
                        ( context.moduleName, Node.value (functionToName function) )
                        context.functionDeclarations
              }
            )

        _ ->
            ( [], context )


expressionVisitor : Node Expression -> ModuleContext -> ( List (Rule.Error {}), ModuleContext )
expressionVisitor (Node range expression) context =
    case context.currentFunction of
        Just (Node currentFunctionRange currentFunction) ->
            case expression of
                Expression.FunctionOrValue _ name ->
                    case ModuleNameLookupTable.moduleNameAt context.moduleNameLookupTable range of
                        Just [] ->
                            let
                                key : ( ModuleName, String )
                                key =
                                    ( context.moduleName, currentFunction )

                                value =
                                    ( context.moduleName, name )

                                newValue =
                                    case Dict.get key context.calls of
                                        Just existing ->
                                            { existing | targets = value :: existing.targets }

                                        Nothing ->
                                            { key = context.moduleKey
                                            , range = currentFunctionRange
                                            , targets = [ value ]
                                            }
                            in
                            ( []
                            , { context | calls = Dict.insert key newValue context.calls }
                            )

                        Just moduleName ->
                            let
                                target : ( ModuleName, String )
                                target =
                                    ( moduleName, name )
                            in
                            case Dict.get target context.forbidden of
                                Just { trace } ->
                                    ( []
                                    , { context
                                        | forbidden =
                                            Dict.insert
                                                ( context.moduleName, currentFunction )
                                                { key = context.moduleKey
                                                , range = currentFunctionRange
                                                , trace = target :: trace
                                                }
                                                context.forbidden
                                      }
                                    )

                                Nothing ->
                                    ( [], context )

                        Nothing ->
                            ( [], context )

                _ ->
                    ( [], context )

        Nothing ->
            ( [], context )
