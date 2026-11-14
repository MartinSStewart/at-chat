port module BackupDiff exposing (Flags, Model, Msg, main)

{-| Compares two backend exports and prints what the newer one has lost: how big each part of
the model is in both, then which guilds, channels, DM channels, users, files and so on are gone
or smaller.

It has to be compiled from the same version of at-chat that wrote the exports, otherwise they
won't decode. `build-backup-diff.sh` takes care of that, see the README.

-}

import Array
import Bytes exposing (Bytes)
import Bytes.Decode
import Bytes.Encode
import ChannelName
import CustomEmoji
import Dict exposing (Dict)
import Discord
import DiscordUserData exposing (DiscordUserData(..))
import DmChannel
import DmChannelId exposing (DmChannelId)
import FileStatus
import GuildName
import Id exposing (GuildId, Id)
import IdArray
import Json.Encode
import List.Nonempty
import LocalState
import NonemptyDict
import NonemptySet
import OneToOne
import PersonName
import SeqDict
import SeqSet
import Slack
import Sticker
import Types exposing (BackendModel, SlackUserData(..))
import User
import WireHelper
import WordSpellingGame


port toJs : Json.Encode.Value -> Cmd msg


{-| Lamdera lets `Bytes` cross a port, which spares a copy of the whole export.
-}
port fileFromJs : (Bytes -> msg) -> Sub msg


type alias Flags =
    { oldName : String, newName : String }


type Model
    = ReadingOld Flags
    | ReadingNew Flags Summary
    | Finished


type Msg
    = GotFile Bytes


main : Program Flags Model Msg
main =
    Platform.worker
        { init = \flags -> ( ReadingOld flags, requestFile "old" )
        , update = update
        , subscriptions = \_ -> fileFromJs GotFile
        }


requestFile : String -> Cmd msg
requestFile which =
    Json.Encode.object [ ( "tag", Json.Encode.string "readFile" ), ( "which", Json.Encode.string which ) ]
        |> toJs


finish : Bool -> String -> Cmd msg
finish succeeded text =
    Json.Encode.object
        [ ( "tag", Json.Encode.string "finish" )
        , ( "succeeded", Json.Encode.bool succeeded )
        , ( "text", Json.Encode.string text )
        ]
        |> toJs


update : Msg -> Model -> ( Model, Cmd Msg )
update (GotFile bytes) model =
    case model of
        ReadingOld flags ->
            case summarize bytes of
                Just summary ->
                    ( ReadingNew flags summary, requestFile "new" )

                Nothing ->
                    ( Finished, finish False (undecodableMessage flags.oldName) )

        ReadingNew flags oldSummary ->
            case summarize bytes of
                Just newSummary ->
                    ( Finished, finish True (report flags oldSummary newSummary) )

                Nothing ->
                    ( Finished, finish False (undecodableMessage flags.newName) )

        Finished ->
            ( model, Cmd.none )


undecodableMessage : String -> String
undecodableMessage name =
    name ++ " couldn't be decoded. Either it's corrupt, or this tool was built from a different version of at-chat than the one that wrote it."



-- SUMMARY


{-| Only what's needed to compare two exports, so that the first export's summary is all that's
kept in memory while the second one is decoded.
-}
type alias Summary =
    { fileBytes : Int
    , parts : Dict String Part
    , collections : Dict String (Dict String Entry)
    , guilds : Dict String GuildSummary
    , dmChannels : Dict String ChannelSummary
    , discordGuilds : Dict String GuildSummary
    , discordDmChannels : Dict String ChannelSummary
    , slackWorkspaces : Dict String GuildSummary
    , slackDmChannels : Dict String ChannelSummary
    , userNames : Dict String String
    , discordUserNames : Dict String String
    }


{-| A field of the backend model. `bytes` is how much its encoding takes up in the export.
-}
type alias Part =
    { count : Int, bytes : Int }


{-| One value in a dictionary field. `label` is whatever helps tell what it is, and is compared
too, so that a Discord account going from linked to unlinked shows up.

Discord attachments are keyed by their file hash, since their ids are opaque, so attachments
that share a file count as one.

-}
type alias Entry =
    { label : String, bytes : Int }


type alias GuildSummary =
    { name : String, headerBytes : Int, channels : Dict String ChannelSummary }


type alias ChannelSummary =
    { name : String, bytes : Int, messages : Int, threads : Int, threadMessages : Int }


summarize : Bytes -> Maybe Summary
summarize bytes =
    Bytes.Decode.decode
        (WireHelper.foldStreamedBackendModel
            { init = initSummary (Bytes.width bytes)
            , guild = addGuild
            , dmChannel = addDmChannel
            , discordGuild = addDiscordGuild
            , discordDmChannel = addDiscordDmChannel
            }
        )
        bytes
        |> Maybe.map addStreamedParts


initSummary : Int -> BackendModel -> Summary
initSummary fileBytes model =
    { fileBytes = fileBytes
    , parts = Dict.fromList (baseParts model)
    , collections = collections model
    , guilds = Dict.empty
    , dmChannels = Dict.empty
    , discordGuilds = Dict.empty
    , discordDmChannels = Dict.empty
    , slackWorkspaces =
        SeqDict.foldl
            (\teamId workspace dict -> Dict.insert (Slack.idToString teamId) (slackWorkspaceSummary workspace) dict)
            Dict.empty
            model.slackWorkspaces
    , slackDmChannels =
        SeqDict.foldl
            (\channelId dmChannel dict -> Dict.insert (Slack.idToString channelId) (slackDmChannelSummary model dmChannel) dict)
            Dict.empty
            model.slackDmChannels
    , userNames =
        NonemptyDict.foldl
            (\userId user dict -> Dict.insert (Id.toString userId) (PersonName.toString user.name) dict)
            Dict.empty
            model.users
    , discordUserNames =
        SeqDict.foldl
            (\userId user dict -> Dict.insert (Discord.idToString userId) (DiscordUserData.username user) dict)
            Dict.empty
            model.discordUsers
    }


{-| The guilds and DM channels are streamed separately from the rest of the model, so their parts
are added up once they've all gone by.
-}
addStreamedParts : Summary -> Summary
addStreamedParts summary =
    { summary
        | parts =
            summary.parts
                |> Dict.insert "guilds" { count = Dict.size summary.guilds, bytes = sumGuildBytes summary.guilds }
                |> Dict.insert "dmChannels" { count = Dict.size summary.dmChannels, bytes = sumChannelBytes summary.dmChannels }
                |> Dict.insert "discordGuilds" { count = Dict.size summary.discordGuilds, bytes = sumGuildBytes summary.discordGuilds }
                |> Dict.insert "discordDmChannels" { count = Dict.size summary.discordDmChannels, bytes = sumChannelBytes summary.discordDmChannels }
    }


sumGuildBytes : Dict String GuildSummary -> Int
sumGuildBytes guilds =
    Dict.foldl (\_ guild total -> total + guildBytes guild) 0 guilds


sumChannelBytes : Dict String ChannelSummary -> Int
sumChannelBytes channels =
    Dict.foldl (\_ channel total -> total + channel.bytes) 0 channels


guildBytes : GuildSummary -> Int
guildBytes guild =
    guild.headerBytes + sumChannelBytes guild.channels


guildMessages : GuildSummary -> Int
guildMessages guild =
    Dict.foldl (\_ channel total -> total + channel.messages + channel.threadMessages) 0 guild.channels


width : BackendModel -> Int
width model =
    encodedWidth (WireHelper.encodeBackendModel model)


{-| elm/bytes doesn't expose `getWidth`, so this writes out the bytes to measure them.
-}
encodedWidth : Bytes.Encode.Encoder -> Int
encodedWidth encoder =
    Bytes.width (Bytes.Encode.encode encoder)


{-| The size of each field is measured by putting it back into a model that has every big field
emptied out, and seeing how much bigger that model's encoding gets. That way nothing needs an
encoder written for it here.

`users` can't be emptied, so it's left holding one user and its size is off by that one user.

-}
baseParts : BackendModel -> List ( String, Part )
baseParts model =
    let
        emptied : BackendModel
        emptied =
            { model
                | users =
                    let
                        ( userId, user ) =
                            NonemptyDict.head model.users
                    in
                    NonemptyDict.singleton userId user
                , sessions = SeqDict.empty
                , connections = SeqDict.empty
                , pendingLogins = SeqDict.empty
                , logs = Array.empty
                , twoFactorAuthentication = SeqDict.empty
                , twoFactorAuthenticationSetup = SeqDict.empty
                , deletedGuilds = SeqDict.empty
                , orphanedDiscordGuildsLastHour = SeqSet.empty
                , slackWorkspaces = SeqDict.empty
                , slackUsers = SeqDict.empty
                , slackFiles = SeqDict.empty
                , slackDmChannels = SeqDict.empty
                , orphanedSlackWorkspacesLastHour = SeqSet.empty
                , orphanedSlackDmChannelsLastHour = SeqSet.empty
                , files = SeqDict.empty
                , orphanedFilesLastHour = SeqSet.empty
                , textEditor = { undoPoint = SeqDict.empty, history = Array.empty, cursorPosition = SeqDict.empty }
                , discordUsers = SeqDict.empty
                , pendingDiscordCreateMessages = SeqDict.empty
                , pendingDiscordCreateDmMessages = SeqDict.empty
                , discordAttachments = SeqDict.empty
                , loadingDiscordChannels = SeqDict.empty
                , sendMessageRateLimits = SeqDict.empty
                , peerToPeerRateLimits = SeqDict.empty
                , sessionRateLimits =
                    { shortWindowStartedAt = model.sessionRateLimits.shortWindowStartedAt
                    , shortWindowCounts = SeqDict.empty
                    , longWindowStartedAt = model.sessionRateLimits.longWindowStartedAt
                    , longWindowCounts = SeqDict.empty
                    }
                , toBackendLogs = Array.empty
                , backendMsgLogs = Array.empty
                , stickers = SeqDict.empty
                , discordStickers = OneToOne.empty
                , customEmojis = SeqDict.empty
                , discordCustomEmojis = OneToOne.empty
                , websocketCloseEvents = Array.empty
                , goMatchPublicIds = OneToOne.empty
                , wordSpellingGameEnglish = WordSpellingGame.WordList_NotLoaded
                , wordSpellingGameSwedish = WordSpellingGame.WordList_NotLoaded
                , pendingGatewayReconnects = SeqDict.empty
                , pendingSlackSends = SeqDict.empty
                , pendingSlackUserLookups = SeqSet.empty
                , refreshingSlackConversations = SeqSet.empty
                , pendingSlackReconnects = SeqDict.empty
                , callRecordings = SeqDict.empty
            }

        emptiedWidth : Int
        emptiedWidth =
            width emptied

        part : String -> Int -> BackendModel -> ( String, Part )
        part name count withField =
            ( name, { count = count, bytes = width withField - emptiedWidth } )
    in
    [ part "users" (NonemptyDict.size model.users) { emptied | users = model.users }
    , part "sessions" (SeqDict.size model.sessions) { emptied | sessions = model.sessions }
    , part "connections" (SeqDict.size model.connections) { emptied | connections = model.connections }
    , part "pendingLogins" (SeqDict.size model.pendingLogins) { emptied | pendingLogins = model.pendingLogins }
    , part "logs" (Array.length model.logs) { emptied | logs = model.logs }
    , part "twoFactorAuthentication" (SeqDict.size model.twoFactorAuthentication) { emptied | twoFactorAuthentication = model.twoFactorAuthentication }
    , part "twoFactorAuthenticationSetup" (SeqDict.size model.twoFactorAuthenticationSetup) { emptied | twoFactorAuthenticationSetup = model.twoFactorAuthenticationSetup }
    , part "deletedGuilds" (SeqDict.size model.deletedGuilds) { emptied | deletedGuilds = model.deletedGuilds }
    , part "orphanedDiscordGuildsLastHour" (SeqSet.size model.orphanedDiscordGuildsLastHour) { emptied | orphanedDiscordGuildsLastHour = model.orphanedDiscordGuildsLastHour }
    , part "slackWorkspaces" (SeqDict.size model.slackWorkspaces) { emptied | slackWorkspaces = model.slackWorkspaces }
    , part "slackUsers" (SeqDict.size model.slackUsers) { emptied | slackUsers = model.slackUsers }
    , part "slackFiles" (SeqDict.size model.slackFiles) { emptied | slackFiles = model.slackFiles }
    , part "slackDmChannels" (SeqDict.size model.slackDmChannels) { emptied | slackDmChannels = model.slackDmChannels }
    , part "orphanedSlackWorkspacesLastHour" (SeqSet.size model.orphanedSlackWorkspacesLastHour) { emptied | orphanedSlackWorkspacesLastHour = model.orphanedSlackWorkspacesLastHour }
    , part "orphanedSlackDmChannelsLastHour" (SeqSet.size model.orphanedSlackDmChannelsLastHour) { emptied | orphanedSlackDmChannelsLastHour = model.orphanedSlackDmChannelsLastHour }
    , part "files" (SeqDict.size model.files) { emptied | files = model.files }
    , part "orphanedFilesLastHour" (SeqSet.size model.orphanedFilesLastHour) { emptied | orphanedFilesLastHour = model.orphanedFilesLastHour }
    , part "textEditor" (Array.length model.textEditor.history) { emptied | textEditor = model.textEditor }
    , part "discordUsers" (SeqDict.size model.discordUsers) { emptied | discordUsers = model.discordUsers }
    , part "pendingDiscordCreateMessages" (SeqDict.size model.pendingDiscordCreateMessages) { emptied | pendingDiscordCreateMessages = model.pendingDiscordCreateMessages }
    , part "pendingDiscordCreateDmMessages" (SeqDict.size model.pendingDiscordCreateDmMessages) { emptied | pendingDiscordCreateDmMessages = model.pendingDiscordCreateDmMessages }
    , part "discordAttachments" (SeqDict.size model.discordAttachments) { emptied | discordAttachments = model.discordAttachments }
    , part "loadingDiscordChannels" (SeqDict.size model.loadingDiscordChannels) { emptied | loadingDiscordChannels = model.loadingDiscordChannels }
    , part "sendMessageRateLimits" (SeqDict.size model.sendMessageRateLimits) { emptied | sendMessageRateLimits = model.sendMessageRateLimits }
    , part "peerToPeerRateLimits" (SeqDict.size model.peerToPeerRateLimits) { emptied | peerToPeerRateLimits = model.peerToPeerRateLimits }
    , part "sessionRateLimits" (SeqDict.size model.sessionRateLimits.longWindowCounts) { emptied | sessionRateLimits = model.sessionRateLimits }
    , part "toBackendLogs" (Array.length model.toBackendLogs) { emptied | toBackendLogs = model.toBackendLogs }
    , part "backendMsgLogs" (Array.length model.backendMsgLogs) { emptied | backendMsgLogs = model.backendMsgLogs }
    , part "stickers" (SeqDict.size model.stickers) { emptied | stickers = model.stickers }
    , part "discordStickers" (OneToOne.size model.discordStickers) { emptied | discordStickers = model.discordStickers }
    , part "customEmojis" (SeqDict.size model.customEmojis) { emptied | customEmojis = model.customEmojis }
    , part "discordCustomEmojis" (OneToOne.size model.discordCustomEmojis) { emptied | discordCustomEmojis = model.discordCustomEmojis }
    , part "websocketCloseEvents" (Array.length model.websocketCloseEvents) { emptied | websocketCloseEvents = model.websocketCloseEvents }
    , part "goMatchPublicIds" (OneToOne.size model.goMatchPublicIds) { emptied | goMatchPublicIds = model.goMatchPublicIds }
    , part "wordSpellingGameEnglish" 0 { emptied | wordSpellingGameEnglish = model.wordSpellingGameEnglish }
    , part "wordSpellingGameSwedish" 0 { emptied | wordSpellingGameSwedish = model.wordSpellingGameSwedish }
    , part "pendingGatewayReconnects" (SeqDict.size model.pendingGatewayReconnects) { emptied | pendingGatewayReconnects = model.pendingGatewayReconnects }
    , part "pendingSlackSends" (SeqDict.size model.pendingSlackSends) { emptied | pendingSlackSends = model.pendingSlackSends }
    , part "pendingSlackUserLookups" (SeqSet.size model.pendingSlackUserLookups) { emptied | pendingSlackUserLookups = model.pendingSlackUserLookups }
    , part "refreshingSlackConversations" (SeqSet.size model.refreshingSlackConversations) { emptied | refreshingSlackConversations = model.refreshingSlackConversations }
    , part "pendingSlackReconnects" (SeqDict.size model.pendingSlackReconnects) { emptied | pendingSlackReconnects = model.pendingSlackReconnects }
    , part "callRecordings" (SeqDict.size model.callRecordings) { emptied | callRecordings = model.callRecordings }
    , ( "(every other field)", { count = 0, bytes = emptiedWidth } )
    ]


collections : BackendModel -> Dict String (Dict String Entry)
collections model =
    Dict.fromList
        [ ( "users"
          , NonemptyDict.foldl
                (\userId user dict ->
                    Dict.insert
                        (Id.toString userId)
                        { label = PersonName.toString user.name
                        , bytes = encodedWidth (User.w3_encode_BackendUser user)
                        }
                        dict
                )
                Dict.empty
                model.users
          )
        , ( "deletedGuilds"
          , SeqDict.foldl
                (\guildId deleted dict ->
                    Dict.insert
                        (Id.toString guildId)
                        { label = GuildName.toString deleted.guild.name
                        , bytes = encodedWidth (LocalState.w3_encode_DeletedBackendGuild deleted)
                        }
                        dict
                )
                Dict.empty
                model.deletedGuilds
          )
        , ( "files"
          , SeqDict.foldl
                (\fileHash file dict ->
                    Dict.insert
                        (FileStatus.fileHashToString fileHash)
                        { label = "file of " ++ formatBytes file.fileSize
                        , bytes = encodedWidth (FileStatus.w3_encode_BackendFileData file)
                        }
                        dict
                )
                Dict.empty
                model.files
          )
        , ( "discordUsers"
          , SeqDict.foldl
                (\userId user dict ->
                    Dict.insert
                        (Discord.idToString userId)
                        { label =
                            DiscordUserData.username user
                                ++ (case user of
                                        BasicData _ ->
                                            " (not linked)"

                                        FullData _ ->
                                            " (linked)"

                                        NeedsAuthAgain _ ->
                                            " (linked, needs auth again)"
                                   )
                        , bytes = encodedWidth (DiscordUserData.w3_encode_DiscordUserData user)
                        }
                        dict
                )
                Dict.empty
                model.discordUsers
          )
        , ( "discordAttachments"
          , SeqDict.foldl
                (\_ attachment dict ->
                    Dict.insert
                        (FileStatus.fileHashToString attachment.fileHash)
                        { label = ""
                        , bytes = encodedWidth (Types.w3_encode_DiscordAttachmentData attachment)
                        }
                        dict
                )
                Dict.empty
                model.discordAttachments
          )
        , ( "slackUsers"
          , SeqDict.foldl
                (\userId user dict ->
                    Dict.insert
                        (Slack.idToString userId)
                        { label =
                            case user of
                                SlackBasicData data ->
                                    data.user.name ++ " (not linked)"

                                SlackFullData data ->
                                    data.user.name ++ " (linked)"
                        , bytes = encodedWidth (Types.w3_encode_SlackUserData user)
                        }
                        dict
                )
                Dict.empty
                model.slackUsers
          )
        , ( "slackFiles"
          , SeqDict.foldl
                (\fileId file dict ->
                    Dict.insert
                        (Slack.idToString fileId)
                        { label = FileStatus.fileHashToString file.fileHash
                        , bytes = encodedWidth (Types.w3_encode_SlackFileData file)
                        }
                        dict
                )
                Dict.empty
                model.slackFiles
          )
        , ( "stickers"
          , SeqDict.foldl
                (\stickerId sticker dict ->
                    Dict.insert
                        (Id.toString stickerId)
                        { label = sticker.name
                        , bytes = encodedWidth (Sticker.w3_encode_StickerData sticker)
                        }
                        dict
                )
                Dict.empty
                model.stickers
          )
        , ( "customEmojis"
          , SeqDict.foldl
                (\emojiId emoji dict ->
                    Dict.insert
                        (Id.toString emojiId)
                        { label = ""
                        , bytes = encodedWidth (CustomEmoji.w3_encode_CustomEmojiData emoji)
                        }
                        dict
                )
                Dict.empty
                model.customEmojis
          )
        ]


addGuild : ( Id GuildId, LocalState.BackendGuild ) -> Summary -> Summary
addGuild ( guildId, guild ) summary =
    { summary
        | guilds =
            Dict.insert
                (Id.toString guildId)
                { name = GuildName.toString guild.name
                , headerBytes = encodedWidth (WireHelper.encodeGuildHeader ( guildId, guild ))
                , channels =
                    SeqDict.foldl
                        (\channelId channel dict ->
                            Dict.insert
                                (Id.toString channelId)
                                { name = ChannelName.toString channel.name
                                , bytes = encodedWidth (WireHelper.encodeGuildChannel ( channelId, channel ))
                                , messages = IdArray.length channel.messages
                                , threads = SeqDict.size channel.threads
                                , threadMessages = SeqDict.foldl (\_ thread total -> total + IdArray.length thread.messages) 0 channel.threads
                                }
                                dict
                        )
                        Dict.empty
                        guild.channels
                }
                summary.guilds
    }


addDiscordGuild : ( Discord.Id Discord.GuildId, LocalState.DiscordBackendGuild ) -> Summary -> Summary
addDiscordGuild ( guildId, guild ) summary =
    { summary
        | discordGuilds =
            Dict.insert
                (Discord.idToString guildId)
                { name = GuildName.toString guild.name
                , headerBytes = encodedWidth (WireHelper.encodeDiscordGuildHeader ( guildId, guild ))
                , channels =
                    SeqDict.foldl
                        (\channelId channel dict ->
                            Dict.insert
                                (Discord.idToString channelId)
                                { name = ChannelName.toString channel.name
                                , bytes = encodedWidth (WireHelper.encodeDiscordGuildChannel ( channelId, channel ))
                                , messages = IdArray.length channel.messages
                                , threads = SeqDict.size channel.threads
                                , threadMessages = SeqDict.foldl (\_ thread total -> total + IdArray.length thread.messages) 0 channel.threads
                                }
                                dict
                        )
                        Dict.empty
                        guild.channels
                }
                summary.discordGuilds
    }


slackWorkspaceSummary : Types.SlackBackendWorkspace -> GuildSummary
slackWorkspaceSummary workspace =
    { name = workspace.name
    , headerBytes = encodedWidth (Types.w3_encode_SlackBackendWorkspace { workspace | channels = SeqDict.empty })
    , channels =
        SeqDict.foldl
            (\channelId channel dict ->
                Dict.insert
                    (Slack.idToString channelId)
                    { name = ChannelName.toString channel.name
                    , bytes = encodedWidth (Types.w3_encode_SlackBackendChannel channel)
                    , messages = IdArray.length channel.messages
                    , threads = SeqDict.size channel.threads
                    , threadMessages = SeqDict.foldl (\_ thread total -> total + IdArray.length thread.messages) 0 channel.threads
                    }
                    dict
            )
            Dict.empty
            workspace.channels
    }


addDmChannel : ( DmChannelId, DmChannel.BackendDmChannel ) -> Summary -> Summary
addDmChannel ( dmChannelId, dmChannel ) summary =
    let
        ( userA, userB ) =
            DmChannelId.toUserIds dmChannelId

        userName : Id a -> String
        userName userId =
            Dict.get (Id.toString userId) summary.userNames |> Maybe.withDefault (Id.toString userId)
    in
    { summary
        | dmChannels =
            Dict.insert
                (DmChannelId.toString dmChannelId)
                { name = userName userA ++ " & " ++ userName userB
                , bytes = encodedWidth (WireHelper.encodeDmChannel ( dmChannelId, dmChannel ))
                , messages = IdArray.length dmChannel.messages
                , threads = SeqDict.size dmChannel.threads
                , threadMessages = SeqDict.foldl (\_ thread total -> total + IdArray.length thread.messages) 0 dmChannel.threads
                }
                summary.dmChannels
    }


addDiscordDmChannel : ( Discord.Id Discord.PrivateChannelId, DmChannel.DiscordDmChannel ) -> Summary -> Summary
addDiscordDmChannel ( channelId, dmChannel ) summary =
    { summary
        | discordDmChannels =
            Dict.insert
                (Discord.idToString channelId)
                { name =
                    NonemptyDict.keys dmChannel.members
                        |> List.Nonempty.toList
                        |> List.map
                            (\userId ->
                                Dict.get (Discord.idToString userId) summary.discordUserNames
                                    |> Maybe.withDefault (Discord.idToString userId)
                            )
                        |> String.join " & "
                , bytes = encodedWidth (WireHelper.encodeDiscordDmChannel ( channelId, dmChannel ))
                , messages = IdArray.length dmChannel.messages
                , threads = 0
                , threadMessages = 0
                }
                summary.discordDmChannels
    }


slackDmChannelSummary : BackendModel -> Types.SlackDmChannel -> ChannelSummary
slackDmChannelSummary model dmChannel =
    { name =
        NonemptySet.toList dmChannel.members
            |> List.map
                (\userId ->
                    case SeqDict.get userId model.slackUsers of
                        Just (SlackBasicData data) ->
                            data.user.name

                        Just (SlackFullData data) ->
                            data.user.name

                        Nothing ->
                            Slack.idToString userId
                )
            |> String.join " & "
    , bytes = encodedWidth (Types.w3_encode_SlackDmChannel dmChannel)
    , messages = IdArray.length dmChannel.messages
    , threads = SeqDict.size dmChannel.threads
    , threadMessages = SeqDict.foldl (\_ thread total -> total + IdArray.length thread.messages) 0 dmChannel.threads
    }



-- REPORT


{-| How many rows each list in the report shows before it says how many more there are.
-}
rowLimit : Int
rowLimit =
    25


report : Flags -> Summary -> Summary -> String
report flags old new =
    [ "Old: " ++ flags.oldName ++ " (" ++ formatBytes old.fileBytes ++ ")"
    , "New: " ++ flags.newName ++ " (" ++ formatBytes new.fileBytes ++ ")"
    , "Change: " ++ formatDelta (new.fileBytes - old.fileBytes)
    , ""
    , partsSection old new
    , guildsSection "Guilds" old.guilds new.guilds
    , guildsSection "Discord guilds" old.discordGuilds new.discordGuilds
    , guildsSection "Slack workspaces" old.slackWorkspaces new.slackWorkspaces
    , channelsSection "DM channels" old.dmChannels new.dmChannels
    , channelsSection "Discord DM channels" old.discordDmChannels new.discordDmChannels
    , channelsSection "Slack DM channels" old.slackDmChannels new.slackDmChannels
    , Dict.foldr
        (\name oldEntries sections ->
            collectionSection name oldEntries (Dict.get name new.collections |> Maybe.withDefault Dict.empty) :: sections
        )
        []
        old.collections
        |> List.filter (\section -> section /= "")
        |> String.join "\n"
    ]
        |> String.join "\n"


heading : String -> String
heading text =
    "== " ++ text ++ " " ++ String.repeat (max 3 (76 - String.length text)) "=" ++ "\n"


partsSection : Summary -> Summary -> String
partsSection old new =
    let
        names : List String
        names =
            Dict.keys (Dict.union old.parts new.parts)

        rows : List { name : String, old : Part, new : Part }
        rows =
            List.map
                (\name ->
                    { name = name
                    , old = Dict.get name old.parts |> Maybe.withDefault { count = 0, bytes = 0 }
                    , new = Dict.get name new.parts |> Maybe.withDefault { count = 0, bytes = 0 }
                    }
                )
                names
                |> List.sortBy (\row -> row.new.bytes - row.old.bytes)

        total : (Part -> Int) -> Dict String Part -> Int
        total getter parts =
            Dict.foldl (\_ part sum -> sum + getter part) 0 parts
    in
    heading "Size of each part of the model, biggest loss first"
        ++ table
            [ "part", "old", "new", "change", "count old", "count new" ]
            (List.filterMap
                (\row ->
                    if row.old == row.new then
                        Nothing

                    else
                        Just
                            [ row.name
                            , formatBytes row.old.bytes
                            , formatBytes row.new.bytes
                            , formatDelta (row.new.bytes - row.old.bytes)
                            , formatInt row.old.count
                            , formatInt row.new.count
                            ]
                )
                rows
                ++ [ [ "(total)"
                     , formatBytes (total .bytes old.parts)
                     , formatBytes (total .bytes new.parts)
                     , formatDelta (total .bytes new.parts - total .bytes old.parts)
                     , ""
                     , ""
                     ]
                   ]
            )
        ++ "Parts that are the same size in both aren't listed. Sizes are of the encoded model, so they add up to the file size give or take a few bytes.\n"


guildsSection : String -> Dict String GuildSummary -> Dict String GuildSummary -> String
guildsSection title old new =
    let
        removed : List ( String, GuildSummary )
        removed =
            Dict.diff old new |> Dict.toList |> List.sortBy (\( _, guild ) -> -(guildBytes guild))

        added : List ( String, GuildSummary )
        added =
            Dict.diff new old |> Dict.toList |> List.sortBy (\( _, guild ) -> -(guildBytes guild))

        shrunk : List { id : String, old : GuildSummary, new : GuildSummary }
        shrunk =
            Dict.foldl
                (\id oldGuild list ->
                    case Dict.get id new of
                        Just newGuild ->
                            if guildBytes newGuild < guildBytes oldGuild || guildMessages newGuild < guildMessages oldGuild then
                                { id = id, old = oldGuild, new = newGuild } :: list

                            else
                                list

                        Nothing ->
                            list
                )
                []
                old
                |> List.sortBy (\row -> guildBytes row.new - guildBytes row.old)
    in
    heading (title ++ ": " ++ formatInt (Dict.size old) ++ " → " ++ formatInt (Dict.size new))
        ++ (if List.isEmpty removed then
                ""

            else
                "Removed:\n"
                    ++ table
                        [ "id", "name", "size", "channels", "messages" ]
                        (List.map
                            (\( id, guild ) ->
                                [ id
                                , guild.name
                                , formatBytes (guildBytes guild)
                                , formatInt (Dict.size guild.channels)
                                , formatInt (guildMessages guild)
                                ]
                            )
                            removed
                        )
           )
        ++ (if List.isEmpty shrunk then
                ""

            else
                "Shrunk or lost messages:\n"
                    ++ (limitRows shrunk
                            |> List.map
                                (\row ->
                                    "  "
                                        ++ row.id
                                        ++ " "
                                        ++ row.old.name
                                        ++ ": "
                                        ++ formatBytes (guildBytes row.old)
                                        ++ " → "
                                        ++ formatBytes (guildBytes row.new)
                                        ++ ", messages "
                                        ++ formatInt (guildMessages row.old)
                                        ++ " → "
                                        ++ formatInt (guildMessages row.new)
                                        ++ "\n"
                                        ++ indent (channelsDiff row.old.channels row.new.channels)
                                )
                            |> String.concat
                       )
                    ++ moreRows shrunk
           )
        ++ (if List.isEmpty added then
                ""

            else
                "Added: "
                    ++ (List.map (\( id, guild ) -> id ++ " " ++ guild.name) added |> String.join ", ")
                    ++ "\n"
           )


indent : String -> String
indent text =
    String.lines text
        |> List.map
            (\line ->
                if line == "" then
                    line

                else
                    "      " ++ line
            )
        |> String.join "\n"


{-| What happened to the channels of a guild that's in both exports.
-}
channelsDiff : Dict String ChannelSummary -> Dict String ChannelSummary -> String
channelsDiff old new =
    let
        removed : List ( String, ChannelSummary )
        removed =
            Dict.diff old new |> Dict.toList |> List.sortBy (\( _, channel ) -> -channel.bytes)

        shrunk : List { id : String, old : ChannelSummary, new : ChannelSummary }
        shrunk =
            shrunkChannels old new
    in
    (List.map
        (\( id, channel ) ->
            "channel removed: " ++ id ++ " #" ++ channel.name ++ ", " ++ formatBytes channel.bytes ++ ", " ++ messageCount channel ++ "\n"
        )
        removed
        |> String.concat
    )
        ++ (limitRows shrunk
                |> List.map
                    (\row ->
                        "channel shrunk: "
                            ++ row.id
                            ++ " #"
                            ++ row.old.name
                            ++ ", "
                            ++ formatBytes row.old.bytes
                            ++ " → "
                            ++ formatBytes row.new.bytes
                            ++ ", "
                            ++ messageCount row.old
                            ++ " → "
                            ++ messageCount row.new
                            ++ "\n"
                    )
                |> String.concat
           )
        ++ moreRows shrunk


shrunkChannels : Dict String ChannelSummary -> Dict String ChannelSummary -> List { id : String, old : ChannelSummary, new : ChannelSummary }
shrunkChannels old new =
    Dict.foldl
        (\id oldChannel list ->
            case Dict.get id new of
                Just newChannel ->
                    if
                        (newChannel.bytes < oldChannel.bytes)
                            || (newChannel.messages < oldChannel.messages)
                            || (newChannel.threadMessages < oldChannel.threadMessages)
                    then
                        { id = id, old = oldChannel, new = newChannel } :: list

                    else
                        list

                Nothing ->
                    list
        )
        []
        old
        |> List.sortBy (\row -> row.new.bytes - row.old.bytes)


messageCount : ChannelSummary -> String
messageCount channel =
    formatInt channel.messages
        ++ " messages"
        ++ (if channel.threads > 0 then
                " + " ++ formatInt channel.threadMessages ++ " in " ++ formatInt channel.threads ++ " threads"

            else
                ""
           )


channelsSection : String -> Dict String ChannelSummary -> Dict String ChannelSummary -> String
channelsSection title old new =
    let
        removed : List ( String, ChannelSummary )
        removed =
            Dict.diff old new |> Dict.toList |> List.sortBy (\( _, channel ) -> -channel.bytes)

        shrunk : List { id : String, old : ChannelSummary, new : ChannelSummary }
        shrunk =
            shrunkChannels old new
    in
    heading (title ++ ": " ++ formatInt (Dict.size old) ++ " → " ++ formatInt (Dict.size new))
        ++ (if List.isEmpty removed then
                ""

            else
                "Removed ("
                    ++ formatInt (List.length removed)
                    ++ ", "
                    ++ formatBytes (List.map (\( _, channel ) -> channel.bytes) removed |> List.sum)
                    ++ "):\n"
                    ++ table
                        [ "id", "between", "size", "messages" ]
                        (limitRows removed
                            |> List.map (\( id, channel ) -> [ id, channel.name, formatBytes channel.bytes, messageCount channel ])
                        )
                    ++ moreRows removed
           )
        ++ (if List.isEmpty shrunk then
                ""

            else
                "Shrunk or lost messages:\n"
                    ++ table
                        [ "id", "between", "old", "new", "messages old", "messages new" ]
                        (limitRows shrunk
                            |> List.map
                                (\row ->
                                    [ row.id
                                    , row.old.name
                                    , formatBytes row.old.bytes
                                    , formatBytes row.new.bytes
                                    , messageCount row.old
                                    , messageCount row.new
                                    ]
                                )
                        )
                    ++ moreRows shrunk
           )


collectionSection : String -> Dict String Entry -> Dict String Entry -> String
collectionSection name old new =
    let
        removed : List ( String, Entry )
        removed =
            Dict.diff old new |> Dict.toList |> List.sortBy (\( _, entry ) -> -entry.bytes)

        added : Int
        added =
            Dict.size (Dict.diff new old)

        changed : List { id : String, old : Entry, new : Entry }
        changed =
            Dict.foldl
                (\id oldEntry list ->
                    case Dict.get id new of
                        Just newEntry ->
                            if newEntry.bytes < oldEntry.bytes || newEntry.label /= oldEntry.label then
                                { id = id, old = oldEntry, new = newEntry } :: list

                            else
                                list

                        Nothing ->
                            list
                )
                []
                old
                |> List.sortBy (\row -> row.new.bytes - row.old.bytes)
    in
    if List.isEmpty removed && List.isEmpty changed then
        ""

    else
        heading
            (name
                ++ ": "
                ++ formatInt (Dict.size old)
                ++ " → "
                ++ formatInt (Dict.size new)
                ++ " ("
                ++ formatInt (List.length removed)
                ++ " removed, "
                ++ formatInt added
                ++ " added)"
            )
            ++ (if List.isEmpty removed then
                    ""

                else
                    "Removed, biggest first ("
                        ++ formatBytes (List.map (\( _, entry ) -> entry.bytes) removed |> List.sum)
                        ++ " in the model):\n"
                        ++ table
                            [ "key", "what", "size" ]
                            (limitRows removed |> List.map (\( id, entry ) -> [ id, entry.label, formatBytes entry.bytes ]))
                        ++ moreRows removed
               )
            ++ (if List.isEmpty changed then
                    ""

                else
                    "Shrunk or changed:\n"
                        ++ table
                            [ "key", "old", "new", "size old", "size new" ]
                            (limitRows changed
                                |> List.map
                                    (\row ->
                                        [ row.id
                                        , row.old.label
                                        , row.new.label
                                        , formatBytes row.old.bytes
                                        , formatBytes row.new.bytes
                                        ]
                                    )
                            )
                        ++ moreRows changed
               )



-- FORMATTING


limitRows : List a -> List a
limitRows rows =
    List.take rowLimit rows


moreRows : List a -> String
moreRows rows =
    let
        hidden : Int
        hidden =
            List.length rows - rowLimit
    in
    if hidden > 0 then
        "  ...and " ++ formatInt hidden ++ " more\n"

    else
        ""


table : List String -> List (List String) -> String
table headers rows =
    let
        columnWidths : List Int
        columnWidths =
            List.foldl
                (\row widths -> List.map2 max widths (List.map String.length row))
                (List.map String.length headers)
                rows
    in
    List.map
        (\row ->
            "  "
                ++ (List.map2 (\columnWidth cell -> String.padRight columnWidth ' ' cell) columnWidths row
                        |> String.join "  "
                        |> String.trimRight
                   )
                ++ "\n"
        )
        (headers :: rows)
        |> String.concat


formatBytes : Int -> String
formatBytes bytes =
    let
        absolute : Float
        absolute =
            toFloat (abs bytes)

        sign : String
        sign =
            if bytes < 0 then
                "-"

            else
                ""
    in
    if absolute >= 1024 * 1024 then
        sign ++ formatFloat (absolute / (1024 * 1024)) ++ " MB"

    else if absolute >= 1024 then
        sign ++ formatFloat (absolute / 1024) ++ " KB"

    else
        sign ++ String.fromInt (abs bytes) ++ " B"


formatDelta : Int -> String
formatDelta bytes =
    if bytes > 0 then
        "+" ++ formatBytes bytes

    else
        formatBytes bytes


formatFloat : Float -> String
formatFloat value =
    let
        tenths : Int
        tenths =
            round (value * 10)
    in
    String.fromInt (tenths // 10) ++ "." ++ String.fromInt (modBy 10 tenths)


formatInt : Int -> String
formatInt value =
    let
        digits : String
        digits =
            String.fromInt (abs value)

        groups : List String
        groups =
            groupDigits digits []
    in
    (if value < 0 then
        "-"

     else
        ""
    )
        ++ String.join "," groups


groupDigits : String -> List String -> List String
groupDigits digits groups =
    if String.length digits > 3 then
        groupDigits (String.dropRight 3 digits) (String.right 3 digits :: groups)

    else
        digits :: groups
