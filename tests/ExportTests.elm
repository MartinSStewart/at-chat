module ExportTests exposing (tests)

{-| Covers how a backend export is split into steps and that the steps add up to
something the import decoder can read back.
-}

import Backend
import Bytes exposing (Bytes)
import Bytes.Decode
import ChannelDescription
import Discord
import DmChannel exposing (DiscordDmChannel)
import DmChannelId
import Expect
import GuildName
import Id
import IdArray
import LocalState exposing (BackendChannel, BackendGuild, ChannelStatus(..), DiscordBackendChannel, DiscordBackendGuild)
import MembersAndOwner
import NonemptyDict
import OneToOne
import Pages.Admin
import SeqDict
import SeqSet
import Test exposing (Test, describe, test)
import Time
import Types exposing (BackendModel, ExportStateProgress)
import UInt64
import Unsafe
import WireHelper


tests : Test
tests =
    describe "Export"
        [ test "Each guild takes one step for the guild and one step per channel" <|
            \_ ->
                stepsOf testModel
                    |> List.filterMap
                        (\progress ->
                            case progress of
                                Pages.Admin.ExportingGuilds counts ->
                                    Just counts

                                _ ->
                                    Nothing
                        )
                    -- The first guild has three channels and the second has one,
                    -- so the first guild takes four steps and the second two. The
                    -- counts are of guilds, so they don't move while the channels
                    -- of a guild are being encoded.
                    |> Expect.equal
                        [ { encoded = 1, total = 2 }
                        , { encoded = 1, total = 2 }
                        , { encoded = 1, total = 2 }
                        , { encoded = 1, total = 2 }
                        , { encoded = 2, total = 2 }
                        , { encoded = 2, total = 2 }
                        ]
        , test "Each Discord guild takes one step for the guild and one step per channel" <|
            \_ ->
                stepsOf testModel
                    |> List.filterMap
                        (\progress ->
                            case progress of
                                Pages.Admin.ExportingDiscordGuilds counts ->
                                    Just counts

                                _ ->
                                    Nothing
                        )
                    -- The one Discord guild has two channels
                    |> Expect.equal
                        [ { encoded = 1, total = 1 }
                        , { encoded = 1, total = 1 }
                        , { encoded = 1, total = 1 }
                        ]
        , test "The exported bytes decode back into the model they were made from" <|
            \_ ->
                case exportOf testModel |> Maybe.andThen (Bytes.Decode.decode WireHelper.decodeStreamedBackendModel) of
                    Just decoded ->
                        Expect.equal
                            { guilds = testModel.guilds
                            , dmChannels = testModel.dmChannels
                            , discordGuilds = testModel.discordGuilds
                            , discordDmChannels = testModel.discordDmChannels
                            }
                            { guilds = decoded.guilds
                            , dmChannels = decoded.dmChannels
                            , discordGuilds = decoded.discordGuilds
                            , discordDmChannels = decoded.discordDmChannels
                            }

                    Nothing ->
                        Expect.fail "The export could not be decoded"
        ]


{-| The progress of every step the export takes, in order, ending with the step
that assembles the export.
-}
stepsOf : BackendModel -> List Pages.Admin.ExportProgress
stepsOf model =
    case (Backend.startExport (Time.millisToPosix 0) model).scheduledExportState of
        Just exportState ->
            stepsHelper exportState []

        Nothing ->
            []


stepsHelper : ExportStateProgress -> List Pages.Admin.ExportProgress -> List Pages.Admin.ExportProgress
stepsHelper exportState collected =
    case Backend.handleExportBackendStep exportState of
        ( progress, Just nextExportState ) ->
            stepsHelper nextExportState (progress :: collected)

        ( progress, Nothing ) ->
            List.reverse (progress :: collected)


exportOf : BackendModel -> Maybe Bytes
exportOf model =
    case List.reverse (stepsOf model) of
        (Pages.Admin.ExportingFinalStep bytes) :: _ ->
            Just bytes

        _ ->
            Nothing


testModel : BackendModel
testModel =
    let
        ( baseModel, _ ) =
            Backend.app_.init
    in
    { baseModel
        | guilds =
            SeqDict.fromList
                [ ( Id.fromInt 0, guildWithChannels [ 0, 1, 2 ] )
                , ( Id.fromInt 1, guildWithChannels [ 0 ] )
                ]
        , dmChannels =
            SeqDict.fromList
                [ ( DmChannelId.fromUserIds (Id.fromInt 0) (Id.fromInt 1), DmChannel.backendInit ) ]
        , discordGuilds = SeqDict.fromList [ ( discordId 1, discordGuildWithChannels [ 2, 3 ] ) ]
        , discordDmChannels = SeqDict.fromList [ ( discordId 4, discordDmChannel ) ]
    }


guildWithChannels : List Int -> BackendGuild
guildWithChannels channelIds =
    { createdAt = Time.millisToPosix 0
    , createdBy = Id.fromInt 0
    , name = guildName
    , icon = Nothing
    , channels = List.map (\channelId -> ( Id.fromInt channelId, channel )) channelIds |> SeqDict.fromList
    , membersAndOwner = MembersAndOwner.init SeqDict.empty (Id.fromInt 0)
    , invites = SeqDict.empty
    }


guildName : GuildName.GuildName
guildName =
    Unsafe.guildName "A guild"


discordGuildName : GuildName.GuildName
discordGuildName =
    Unsafe.guildName "A Discord guild"


channel : BackendChannel
channel =
    { createdAt = Time.millisToPosix 0
    , createdBy = Id.fromInt 0
    , name = Unsafe.channelName "channel"
    , description = ChannelDescription.empty
    , messages = IdArray.empty
    , status = ChannelActive
    , lastTypedAt = SeqDict.empty
    , threads = SeqDict.empty
    , dateDividerDrawings = SeqDict.empty
    , games = SeqDict.empty
    }


discordGuildWithChannels : List Int -> DiscordBackendGuild
discordGuildWithChannels channelIds =
    { name = discordGuildName
    , icon = Nothing
    , channels = List.map (\channelId -> ( discordId channelId, discordChannel )) channelIds |> SeqDict.fromList
    , membersAndOwner = MembersAndOwner.init SeqDict.empty (discordId 0)
    , stickers = SeqSet.empty
    , customEmojis = SeqSet.empty
    , roles = SeqDict.empty
    }


discordChannel : DiscordBackendChannel
discordChannel =
    { name = Unsafe.channelName "discord-channel"
    , description = ChannelDescription.empty
    , isForum = False
    , messages = IdArray.empty
    , status = ChannelActive
    , lastTypedAt = SeqDict.empty
    , linkedMessageIds = OneToOne.empty
    , threads = SeqDict.empty
    , dateDividerDrawings = SeqDict.empty
    , permissionOverwrites = []
    }


discordDmChannel : DiscordDmChannel
discordDmChannel =
    { messages = IdArray.empty
    , lastTypedAt = SeqDict.empty
    , linkedMessageIds = OneToOne.empty
    , members = NonemptyDict.singleton (discordId 0) { messagesSent = 0 }
    , dateDividerDrawings = SeqDict.empty
    }


discordId : Int -> Discord.Id a
discordId id =
    Discord.idFromUInt64 (UInt64.fromInt id)
