module ExposeAllRecordFields exposing (rule)

{-|

@docs rule

-}

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Expression exposing (Function)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Pattern exposing (Pattern(..))
import Elm.Syntax.Range as Range
import Elm.Syntax.TypeAnnotation exposing (TypeAnnotation(..))
import Review.ModuleNameLookupTable exposing (ModuleNameLookupTable)
import Review.Rule as Rule exposing (ModuleKey, Rule)
import Set exposing (Set)


{-| Reports when a function parameter uses record destructuring but doesn't destructure all fields.

When destructuring record fields from function parameters, you should destructure all available fields
to make the function signature more explicit and catch potential issues when the record type changes.

    config =
        [ ExposeAllRecordFields.rule
        ]


## Fail

    -- Assuming Person has fields: name, age, email
    greet : Person -> String
    greet { name } =
        "Hello " ++ name


## Success

    greet : Person -> String
    greet { name, age, email } =
        "Hello " ++ name

    -- Or use the entire record
    greet : Person -> String
    greet person =
        "Hello " ++ person.name


## When (not) to enable this rule

This rule is useful when you want to ensure all record fields are explicitly handled in function parameters.
This rule is not useful when you frequently work with large records where destructuring all fields would be verbose.


## Try it out

You can try this rule out by running the following command:

```bash
elm-review --template undefined/example --rules ExposeAllRecordFields
```

-}
rule : Rule
rule =
    Rule.newProjectRuleSchema "ExposeAllRecordFields" initialProjectContext
        |> Rule.withModuleVisitor moduleVisitor
        |> Rule.withContextFromImportedModules
        |> Rule.withModuleContextUsingContextCreator
            { fromProjectToModule = fromProjectToModule
            , fromModuleToProject = fromModuleToProject
            , foldProjectContexts = foldProjectContexts
            }
        |> Rule.fromProjectRuleSchema


type alias ProjectContext =
    { typeDeclarations : List ( ModuleName, String, Set String )
    }


type alias ModuleContext =
    { typeDeclarations : List ( String, Set String )
    , moduleName : ModuleName
    , lookupTable : ModuleNameLookupTable
    , projectContext : ProjectContext
    }


initialProjectContext : ProjectContext
initialProjectContext =
    { typeDeclarations = []
    }


fromProjectToModule : Rule.ContextCreator ProjectContext ModuleContext
fromProjectToModule =
    Rule.initContextCreator
        (\moduleName lookupTable projectContext ->
            { typeDeclarations = []
            , moduleName = moduleName
            , lookupTable = lookupTable
            , projectContext = projectContext
            }
        )
        |> Rule.withModuleName
        |> Rule.withModuleNameLookupTable


fromModuleToProject : Rule.ContextCreator ModuleContext ProjectContext
fromModuleToProject =
    Rule.initContextCreator
        (\moduleContext ->
            { typeDeclarations =
                moduleContext.typeDeclarations
                    |> List.map (\( typeName, fields ) -> ( moduleContext.moduleName, typeName, fields ))
            }
        )


foldProjectContexts : ProjectContext -> ProjectContext -> ProjectContext
foldProjectContexts left right =
    { typeDeclarations = left.typeDeclarations ++ right.typeDeclarations
    }


moduleVisitor :
    Rule.ModuleRuleSchema {} ModuleContext
    -> Rule.ModuleRuleSchema { hasAtLeastOneVisitor : () } ModuleContext
moduleVisitor schema =
    schema
        |> Rule.withDeclarationEnterVisitor declarationVisitor


declarationVisitor : Node Declaration -> ModuleContext -> ( List (Rule.Error {}), ModuleContext )
declarationVisitor node context =
    case Node.value node of
        AliasDeclaration typeAlias ->
            let
                typeName =
                    Node.value typeAlias.name

                fields =
                    extractRecordFields (Node.value typeAlias.typeAnnotation)
            in
            ( [], { context | typeDeclarations = ( typeName, fields ) :: context.typeDeclarations } )

        FunctionDeclaration function ->
            checkFunctionDeclaration function context

        _ ->
            ( [], context )


extractRecordFields : TypeAnnotation -> Set String
extractRecordFields typeAnnotation =
    case typeAnnotation of
        Record fields ->
            fields
                |> List.map (\(Node _ ( Node _ fieldName, _ )) -> fieldName)
                |> Set.fromList

        GenericRecord _ (Node _ fields) ->
            fields
                |> List.map (\(Node _ ( Node _ fieldName, _ )) -> fieldName)
                |> Set.fromList

        _ ->
            Set.empty


checkFunctionDeclaration : Function -> ModuleContext -> ( List (Rule.Error {}), ModuleContext )
checkFunctionDeclaration function context =
    case function.signature of
        Just (Node _ signature) ->
            let
                typeAnnotation =
                    Node.value signature.typeAnnotation

                parameterTypes =
                    extractParameterTypes typeAnnotation

                patterns =
                    Node.value function.declaration |> .arguments
            in
            checkPatterns patterns parameterTypes context

        Nothing ->
            ( [], context )


extractParameterTypes : TypeAnnotation -> List TypeAnnotation
extractParameterTypes typeAnnotation =
    case typeAnnotation of
        FunctionTypeAnnotation (Node _ paramType) (Node _ returnType) ->
            paramType :: extractParameterTypes returnType

        _ ->
            []


checkPatterns : List (Node Pattern) -> List TypeAnnotation -> ModuleContext -> ( List (Rule.Error {}), ModuleContext )
checkPatterns patterns parameterTypes context =
    List.map2 (\pattern paramType -> checkPattern pattern paramType context)
        patterns
        parameterTypes
        |> List.foldl
            (\( errors, _ ) ( accErrors, accContext ) -> ( errors ++ accErrors, accContext ))
            ( [], context )


checkPattern : Node Pattern -> TypeAnnotation -> ModuleContext -> ( List (Rule.Error {}), ModuleContext )
checkPattern (Node range pattern) parameterType context =
    case pattern of
        RecordPattern fields ->
            let
                destructuredFields =
                    fields |> List.map Node.value |> Set.fromList

                expectedFields =
                    getExpectedRecordFields parameterType context
            in
            if Set.size destructuredFields > 0 && Set.size destructuredFields < Set.size expectedFields then
                let
                    missingFields =
                        Set.diff expectedFields destructuredFields |> Set.toList
                in
                ( [ Rule.error
                        { message = "Record destructuring should include all fields"
                        , details =
                            [ "This function parameter destructures some but not all record fields."
                            , "Consider destructuring all fields: " ++ String.join ", " (Set.toList expectedFields)
                            , "Missing fields: " ++ String.join ", " missingFields
                            ]
                        }
                        range
                  ]
                , context
                )

            else
                ( [], context )

        _ ->
            ( [], context )


getExpectedRecordFields : TypeAnnotation -> ModuleContext -> Set String
getExpectedRecordFields typeAnnotation context =
    case typeAnnotation of
        Typed (Node range ( moduleName, typeName )) _ ->
            -- Handle qualified type names
            case moduleName of
                [] ->
                    -- Check local types first
                    case List.filter (\( name, _ ) -> name == typeName) context.typeDeclarations |> List.head of
                        Just ( _, fields ) ->
                            fields

                        Nothing ->
                            -- Check project-wide types
                            context.projectContext.typeDeclarations
                                |> List.filter (\( _, name, _ ) -> name == typeName)
                                |> List.head
                                |> Maybe.map (\( _, _, fields ) -> fields)
                                |> Maybe.withDefault Set.empty

                _ ->
                    -- External qualified type - look up in project context using the range
                    let
                        resolvedModuleName =
                            Review.ModuleNameLookupTable.moduleNameAt context.lookupTable range
                                |> Maybe.withDefault moduleName
                    in
                    context.projectContext.typeDeclarations
                        |> List.filter (\( modName, name, _ ) -> modName == resolvedModuleName && name == typeName)
                        |> List.head
                        |> Maybe.map (\( _, _, fields ) -> fields)
                        |> Maybe.withDefault Set.empty

        Record _ ->
            extractRecordFields typeAnnotation

        GenericRecord _ _ ->
            extractRecordFields typeAnnotation

        _ ->
            Set.empty
