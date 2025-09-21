module ReviewConfig exposing (config)

{-| Do not rename the ReviewConfig module or the config function, because
`elm-review` will look for these.

To add packages that contain rules, add them to this review project using

    `elm install author/packagename`

when inside the directory containing this file.

-}

import BackendOnly
import Derive
import Docs.ReviewAtDocs
import ExposeAllRecordFields
import NoBrokenParserFunctions
import NoConfusingPrefixOperator
import NoDebug.TodoOrToString
import NoExposingEverything
import NoImportingEverything
import NoInconsistentAliases
import NoMissingTypeAnnotation
import NoMissingTypeConstructor
import NoMissingTypeExpose
import NoModuleOnExposedNames
import NoSimpleLetBody
import NoStaleReferences
import NoUnused.CustomTypeConstructors
import NoUnused.Dependencies
import NoUnused.Exports
import NoUnused.Modules
import NoUnused.Parameters
import NoUnused.Patterns
import NoUnused.Variables
import NoUnusedFields
import OpaqueTypes
import Review.Rule exposing (Rule)
import ReviewPipelineStyles
import ReviewPipelineStyles.Fixes
import RunUnsafeAtStartup
import Simplify



--config : List Rule
--config =
--    [ Derive.rule False [] ]
--


config : List Rule
config =
    [ ExposeAllRecordFields.rule |> defaultIgnore
    , OpaqueTypes.rule
    , RunUnsafeAtStartup.rule
    , NoStaleReferences.rule
        |> defaultIgnore

    --, NoUnusedFields.rule |> defaultIgnore
    , NoUnused.CustomTypeConstructors.rule [] |> defaultIgnore
    , NoUnused.Patterns.rule |> defaultIgnore
    , Docs.ReviewAtDocs.rule |> defaultIgnore
    , NoConfusingPrefixOperator.rule |> defaultIgnore
    , NoDebug.TodoOrToString.rule
        |> Review.Rule.ignoreErrorsForDirectories [ "tests/" ]
        |> defaultIgnore
    , NoExposingEverything.rule |> Review.Rule.ignoreErrorsForFiles [ "src/Env.elm" ] |> defaultIgnore
    , NoImportingEverything.rule [] |> defaultIgnore
    , NoMissingTypeAnnotation.rule |> defaultIgnore
    , NoMissingTypeExpose.rule |> defaultIgnore
    , NoSimpleLetBody.rule |> defaultIgnore
    , NoUnused.Dependencies.rule |> defaultIgnore
    , NoUnused.Exports.rule |> defaultIgnore
    , NoUnused.Modules.rule |> defaultIgnore
    , NoUnused.Parameters.rule |> Review.Rule.ignoreErrorsForFiles [ "src/Unsafe.elm" ] |> defaultIgnore
    , ReviewPipelineStyles.rule
        [ ReviewPipelineStyles.forbid ReviewPipelineStyles.leftPizzaPipelines
            |> ReviewPipelineStyles.andTryToFixThemBy ReviewPipelineStyles.Fixes.convertingToParentheticalApplication
            |> ReviewPipelineStyles.andCallThem "forbidden <| pipeline"
        , ReviewPipelineStyles.forbid ReviewPipelineStyles.leftCompositionPipelines
            |> ReviewPipelineStyles.andCallThem "forbidden << composition"
        , ReviewPipelineStyles.forbid ReviewPipelineStyles.rightCompositionPipelines
            |> ReviewPipelineStyles.andCallThem "forbidden >> composition"
        ]
        |> Review.Rule.ignoreErrorsForDirectories [ "tests" ]
        |> defaultIgnore
    , Simplify.rule Simplify.defaults |> defaultIgnore
    , NoInconsistentAliases.config
        [ ( "Effect.Browser.Dom", "Dom" )
        , ( "Effect.Browser.Navigation", "BrowserNavigation" )
        , ( "Effect.Command", "Command" )
        , ( "Effect.Http", "Http" )
        , ( "Effect.Lamdera", "Lamdera" )
        , ( "Effect.Subscription", "Subscription" )
        , ( "Effect.Task", "Task" )
        , ( "Effect.Test", "T" )
        , ( "Effect.Time", "Time" )
        , ( "Effect.WebGL.Settings.Blend", "Blend" )
        , ( "Lamdera", "LamderaCore" )
        ]
        |> NoInconsistentAliases.rule
        |> defaultIgnore
    , NoModuleOnExposedNames.rule |> defaultIgnore
    , NoMissingTypeConstructor.rule |> defaultIgnore
    , NoUnused.Variables.rule
        |> Review.Rule.ignoreErrorsForDirectories
            (List.map
                (\v -> "src/Evergreen/V" ++ String.fromInt v)
                (List.range 1 1000)
            )
        |> Review.Rule.ignoreErrorsForFiles
            [ "src/Coord.elm"
            , "src/NonemptyDict.elm"
            , "src/NonemptySet.elm"
            , "src/LamderaRPC.elm"
            ]
        |> Review.Rule.ignoreErrorsForDirectories [ "vendored" ]
    , NoBrokenParserFunctions.rule
    , BackendOnly.rule
        { functions =
            []
        , modules =
            [ [ "Backend" ]
            , [ "EmailViewer" ]
            , [ "TwoFactorAuthentication" ]
            ]
        }
    ]


defaultIgnore : Rule -> Rule
defaultIgnore rule =
    Review.Rule.ignoreErrorsForFiles
        [ "src/Coord.elm"
        , "src/NonemptyDict.elm"
        , "src/NonemptySet.elm"
        , "src/LamderaRPC.elm"
        , "src/OneToOne.elm"
        , "src/RPC.elm"
        , "src/Discord.elm"
        , "src/Discord/Id.elm"
        ]
        rule
        |> Review.Rule.ignoreErrorsForDirectories [ "vendored", "src/Evergreen" ]
