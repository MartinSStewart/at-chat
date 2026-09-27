module ReviewConfig exposing (config)

{-| Do not rename the ReviewConfig module or the config function, because
`elm-review` will look for these.

To add packages that contain rules, add them to this review project using

    `elm install author/packagename`

when inside the directory containing this file.

-}

import BackendOnly
import Docs.ReviewAtDocs
import EncoderDecoderNaming
import ExposeAllRecordFields
import NoBrokenParserFunctions
import NoConfusingPrefixOperator
import NoDebug.TodoOrToString
import NoExposingEverything
import NoImportingEverything
import NoInconsistentAliases
import NoInvalidTypesInToBackend
import NoMissingTypeAnnotation
import NoMissingTypeConstructor
import NoMissingTypeExpose
import NoModuleOnExposedNames
import NoRedundantUiAttributes
import NoSimpleLetBody
import NoStaleReferences
import NoUnhandledFileHashes
import NoUnused.CustomTypeConstructors
import NoUnused.Dependencies
import NoUnused.Exports
import NoUnused.Modules
import NoUnused.Parameters
import NoUnused.Patterns
import NoUnused.Variables
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
        |> Review.Rule.ignoreErrorsForFiles
            [ "tests/E2ETests.elm"
            , "src/E2EEncryption.elm"
            , "src/E2EHelper.elm"
            , "src/E2EDiscord.elm"
            ]
    , RunUnsafeAtStartup.rule
    , NoRedundantUiAttributes.rule
        |> defaultIgnore
    , NoStaleReferences.rule
        |> -- X25519's numbers are limb and coordinate indices rather than successive
           -- versions of a value, and they are named the way RFC 7748 and TweetNaCl
           -- name them so the two can be read side by side.
           Review.Rule.ignoreErrorsForFiles [ "src/X25519.elm" ]
        |> defaultIgnore

    --, NoUnusedFields.rule |> defaultIgnore
    , NoUnused.CustomTypeConstructors.rule [] |> defaultIgnore
    , NoUnused.Patterns.rule |> defaultIgnore
    , Docs.ReviewAtDocs.rule |> defaultIgnore
    , NoConfusingPrefixOperator.rule |> defaultIgnore
    , NoDebug.TodoOrToString.rule
        |> Review.Rule.ignoreErrorsForDirectories [ "tests/" ]
        |> Review.Rule.ignoreErrorsForFiles
            [ "tests/E2ETests.elm"
            , "src/E2EHelper.elm"
            , "src/E2EDiscord.elm"
            , "src/E2EMisc.elm"
            ]
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
        |> NoInconsistentAliases.noMissingAliases
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
    , EncoderDecoderNaming.rule
        |> Review.Rule.ignoreErrorsForFiles [ "src/LamderaRPC.elm" ]
        |> Review.Rule.ignoreErrorsForDirectories [ "src/Evergreen", "vendored/mdgriffith" ]
    , NoBrokenParserFunctions.rule
    , NoUnhandledFileHashes.rule
        { handled =
            [ "customEmojis.url.CustomEmojiInternal"
            , "deletedGuilds.guild.channels.games.GameData_SheepGame.answers.attachedFiles.fileHash"
            , "deletedGuilds.guild.channels.games.GameData_SheepGame.change.ChangedNotes.attachedFiles.fileHash"
            , "deletedGuilds.guild.channels.games.GameData_SheepGame.change.SubmittedAnswer.attachedFiles.fileHash"
            , "deletedGuilds.guild.channels.games.GameData_SheepGame.notes.attachedFiles.fileHash"
            , "deletedGuilds.guild.channels.games.GameData_SheepGame.questions.attachedFiles.fileHash"
            , "deletedGuilds.guild.channels.messages.EncryptedUserTextMessage.fileHashes"
            , "deletedGuilds.guild.channels.messages.UserTextMessage.content.attachedFiles.fileHash"
            , "deletedGuilds.guild.channels.threads.messages.EncryptedUserTextMessage.fileHashes"
            , "deletedGuilds.guild.channels.threads.messages.UserTextMessage.content.attachedFiles.fileHash"
            , "deletedGuilds.guild.icon"
            , "discordDmChannels.messages.EncryptedUserTextMessage.fileHashes"
            , "discordDmChannels.messages.UserTextMessage.content.attachedFiles.fileHash"
            , "discordGuilds.channels.messages.EncryptedUserTextMessage.fileHashes"
            , "discordGuilds.channels.messages.UserTextMessage.content.attachedFiles.fileHash"
            , "discordGuilds.channels.threads.messages.EncryptedUserTextMessage.fileHashes"
            , "discordGuilds.channels.threads.messages.UserTextMessage.content.attachedFiles.fileHash"
            , "discordGuilds.icon"
            , "discordUsers.BasicData.icon"
            , "discordUsers.FullData.icon"
            , "discordUsers.NeedsAuthAgain.icon"
            , "dmChannels.games.GameData_SheepGame.answers.attachedFiles.fileHash"
            , "dmChannels.games.GameData_SheepGame.change.ChangedNotes.attachedFiles.fileHash"
            , "dmChannels.games.GameData_SheepGame.change.SubmittedAnswer.attachedFiles.fileHash"
            , "dmChannels.games.GameData_SheepGame.notes.attachedFiles.fileHash"
            , "dmChannels.games.GameData_SheepGame.questions.attachedFiles.fileHash"
            , "dmChannels.messages.EncryptedUserTextMessage.fileHashes"
            , "dmChannels.messages.UserTextMessage.content.attachedFiles.fileHash"
            , "dmChannels.threads.messages.EncryptedUserTextMessage.fileHashes"
            , "dmChannels.threads.messages.UserTextMessage.content.attachedFiles.fileHash"
            , "guilds.channels.games.GameData_SheepGame.answers.attachedFiles.fileHash"
            , "guilds.channels.games.GameData_SheepGame.change.ChangedNotes.attachedFiles.fileHash"
            , "guilds.channels.games.GameData_SheepGame.change.SubmittedAnswer.attachedFiles.fileHash"
            , "guilds.channels.games.GameData_SheepGame.notes.attachedFiles.fileHash"
            , "guilds.channels.games.GameData_SheepGame.questions.attachedFiles.fileHash"
            , "guilds.channels.messages.EncryptedUserTextMessage.fileHashes"
            , "guilds.channels.messages.UserTextMessage.content.attachedFiles.fileHash"
            , "guilds.channels.threads.messages.EncryptedUserTextMessage.fileHashes"
            , "guilds.channels.threads.messages.UserTextMessage.content.attachedFiles.fileHash"
            , "guilds.icon"
            , "sessions.savedSheepGameQuestions.attachedFiles.FileUploaded.fileHash"
            , "stickers.url.StickerInternal"
            , "users.icon"
            ]
        , excluded =
            [ "files"

            -- Orphaned files waiting an hour before they're deleted
            , "orphanedFilesLastHour"

            -- Only remembers which Discord attachments have already been uploaded
            , "discordAttachments"

            -- Copies of channels taken while an export is running
            , "exportState"
            , "scheduledExportState"
            ]
        }
    , NoInvalidTypesInToBackend.rule
        { disallowed =
            [ ( [ "Basics" ], "Float" )
            , ( [ "Duration" ], "Duration" )
            ]
        , unlessWrappedIn =
            [ ( [ "SafeFloat" ], "SafeFloat" )
            , ( [ "UserSession" ], "ToBeFilledInByBackend" )
            , ( [ "FileStatus" ], "VideoMetadata" )
            , ( [ "Go" ], "TimeControl" )
            ]
        }
        |> Review.Rule.ignoreErrorsForDirectories [ "vendored", "src/Evergreen" ]
    , BackendOnly.rule
        { functions =
            []
        , modules =
            [ [ "Backend" ]
            , [ "BackendExtra" ]
            , [ "UiViewer" ]
            , [ "WireHelper" ]
            , [ "DiscordSync" ]
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
        ]
        rule
        |> Review.Rule.ignoreErrorsForDirectories [ "vendored", "src/Evergreen" ]
