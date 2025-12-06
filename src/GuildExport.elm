module GuildExport exposing (backendGuildCodec, discordBackendGuildCodec)

{-| Module for encoding and decoding guild data for export/import functionality
-}

import Array exposing (Array)
import ChannelName exposing (ChannelName(..))
import Codec exposing (Codec)
import CodecExtra
import Coord
import Discord.Id
import Emoji exposing (Emoji(..))
import FileName exposing (FileName)
import FileStatus exposing (ContentType(..), FileData, FileHash(..), FileId, ImageMetadata)
import GuildName exposing (GuildName(..))
import Id exposing (ChannelId, Id(..), InviteLinkId, ThreadMessageId, UserId)
import List.Nonempty exposing (Nonempty)
import LocalState exposing (BackendChannel, BackendGuild, ChannelStatus(..), DiscordBackendChannel, DiscordBackendGuild)
import Message exposing (Message(..), UserTextMessageData)
import NonemptySet exposing (NonemptySet)
import OneToOne exposing (OneToOne)
import RichText exposing (Language(..), RichText(..))
import SecretId exposing (SecretId(..))
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import String.Nonempty exposing (NonemptyString(..))
import Thread exposing (BackendThread, DiscordBackendThread, LastTypedAt)
import Time
import UInt64 exposing (UInt64)
import Url exposing (Protocol(..))



-- Helper codecs for basic types


charCodec : Codec Char
charCodec =
    Codec.map
        (\s -> String.uncons s |> Maybe.map Tuple.first |> Maybe.withDefault 'e')
        String.fromChar
        Codec.string



-- FileData codec


fileDataCodec : Codec FileData
fileDataCodec =
    Codec.object FileData
        |> Codec.field "fileName" .fileName fileNameCodec
        |> Codec.field "fileSize" .fileSize Codec.int
        |> Codec.field "imageMetadata" .imageMetadata (Codec.maybe imageMetadataStubCodec)
        |> Codec.field "contentType" .contentType contentTypeCodec
        |> Codec.field "fileHash" .fileHash FileStatus.fileHashCodec
        |> Codec.buildObject


contentTypeCodec : Codec FileStatus.ContentType
contentTypeCodec =
    Codec.map (\i -> ContentType i) (\(ContentType i) -> i) Codec.int


imageMetadataStubCodec : Codec FileStatus.ImageMetadata
imageMetadataStubCodec =
    -- Simplified codec that just encodes minimal data
    Codec.map
        (\( w, h ) ->
            { imageSize = Coord.xy w h
            , orientation = Nothing
            , gpsLocation = Nothing
            , cameraOwner = Nothing
            , exposureTime = Nothing
            , fNumber = Nothing
            , focalLength = Nothing
            , isoSpeedRating = Nothing
            , make = Nothing
            , model = Nothing
            , software = Nothing
            , userComment = Nothing
            }
        )
        (\meta -> ( Coord.xRaw meta.imageSize, Coord.yRaw meta.imageSize ))
        (Codec.tuple Codec.int Codec.int)


fileNameCodec : Codec FileName
fileNameCodec =
    Codec.map FileName.fromString FileName.toString Codec.string



-- Message codec


messageCodec : Codec messageId -> Codec userId -> Codec (Message messageId userId)
messageCodec messageIdCodec userIdCodec =
    Codec.custom
        (\userTextEncoder userJoinedEncoder deletedEncoder value ->
            case value of
                UserTextMessage data ->
                    userTextEncoder data

                UserJoinedMessage time userId reactions ->
                    userJoinedEncoder ( time, userId, reactions )

                DeletedMessage time ->
                    deletedEncoder time
        )
        |> Codec.variant1 "UserTextMessage" UserTextMessage (userTextMessageDataCodec messageIdCodec userIdCodec)
        |> Codec.variant1 "UserJoinedMessage"
            (\( time, userId, reactions ) -> UserJoinedMessage time userId reactions)
            (Codec.triple timePosixCodec userIdCodec (seqDictCodec emojiCodec (nonemptySetCodec userIdCodec)))
        |> Codec.variant1 "DeletedMessage" DeletedMessage timePosixCodec
        |> Codec.buildCustom


userTextMessageDataCodec : Codec messageId -> Codec userId -> Codec (UserTextMessageData messageId userId)
userTextMessageDataCodec messageIdCodec userIdCodec =
    Codec.object UserTextMessageData
        |> Codec.field "createdAt" .createdAt timePosixCodec
        |> Codec.field "createdBy" .createdBy userIdCodec
        |> Codec.field "content" .content (nonemptyCodec (richTextCodec userIdCodec))
        |> Codec.field "reactions" .reactions (seqDictCodec emojiCodec (nonemptySetCodec userIdCodec))
        |> Codec.field "editedAt" .editedAt (Codec.maybe timePosixCodec)
        |> Codec.field "repliedTo" .repliedTo (Codec.maybe messageIdCodec)
        |> Codec.field "attachedFiles" .attachedFiles (seqDictCodec idCodec fileDataCodec)
        |> Codec.buildObject



-- LastTypedAt codec


lastTypedAtCodec : Codec (Id messageId) -> Codec (LastTypedAt messageId)
lastTypedAtCodec messageIdCodec =
    Codec.object LastTypedAt
        |> Codec.field "time" .time timePosixCodec
        |> Codec.field "messageIndex" .messageIndex (Codec.maybe messageIdCodec)
        |> Codec.buildObject



-- BackendThread codec


backendThreadCodec : Codec BackendThread
backendThreadCodec =
    Codec.object BackendThread
        |> Codec.field "messages" .messages (Codec.array (messageCodec idCodec idCodec))
        |> Codec.field "lastTypedAt" .lastTypedAt (seqDictCodec idCodec (lastTypedAtCodec idCodec))
        |> Codec.buildObject


discordBackendThreadCodec : Codec DiscordBackendThread
discordBackendThreadCodec =
    Codec.object DiscordBackendThread
        |> Codec.field "messages" .messages (Codec.array (messageCodec idCodec discordIdCodec))
        |> Codec.field "lastTypedAt" .lastTypedAt (seqDictCodec discordIdCodec (lastTypedAtCodec idCodec))
        |> Codec.field "linkedMessageIds" .linkedMessageIds (oneToOneCodec discordIdCodec idCodec)
        |> Codec.buildObject



-- ChannelStatus codec


channelStatusCodec : Codec ChannelStatus
channelStatusCodec =
    Codec.custom
        (\activeEncoder deletedEncoder value ->
            case value of
                ChannelActive ->
                    activeEncoder

                ChannelDeleted data ->
                    deletedEncoder data
        )
        |> Codec.variant0 "ChannelActive" ChannelActive
        |> Codec.variant1 "ChannelDeleted"
            ChannelDeleted
            (Codec.object (\deletedAt deletedBy -> { deletedAt = deletedAt, deletedBy = deletedBy })
                |> Codec.field "deletedAt" .deletedAt timePosixCodec
                |> Codec.field "deletedBy" .deletedBy idCodec
                |> Codec.buildObject
            )
        |> Codec.buildCustom



-- BackendChannel codec


backendChannelCodec : Codec BackendChannel
backendChannelCodec =
    Codec.object BackendChannel
        |> Codec.field "createdAt" .createdAt timePosixCodec
        |> Codec.field "createdBy" .createdBy idCodec
        |> Codec.field "name" .name channelNameCodec
        |> Codec.field "messages" .messages (Codec.array (messageCodec idCodec idCodec))
        |> Codec.field "status" .status channelStatusCodec
        |> Codec.field "lastTypedAt" .lastTypedAt (seqDictCodec idCodec (lastTypedAtCodec idCodec))
        |> Codec.field "threads" .threads (seqDictCodec idCodec backendThreadCodec)
        |> Codec.buildObject


discordBackendChannelCodec : Codec DiscordBackendChannel
discordBackendChannelCodec =
    Codec.object DiscordBackendChannel
        |> Codec.field "name" .name channelNameCodec
        |> Codec.field "messages" .messages (Codec.array (messageCodec idCodec discordIdCodec))
        |> Codec.field "status" .status channelStatusCodec
        |> Codec.field "lastTypedAt" .lastTypedAt (seqDictCodec discordIdCodec (lastTypedAtCodec idCodec))
        |> Codec.field "linkedMessageIds" .linkedMessageIds (oneToOneCodec discordIdCodec idCodec)
        |> Codec.field "threads" .threads (seqDictCodec idCodec discordBackendThreadCodec)
        |> Codec.buildObject



-- BackendGuild codec


backendGuildCodec : Codec BackendGuild
backendGuildCodec =
    Codec.object BackendGuild
        |> Codec.field "createdAt" .createdAt timePosixCodec
        |> Codec.field "createdBy" .createdBy idCodec
        |> Codec.field "name" .name guildNameCodec
        |> Codec.field "icon" .icon (Codec.maybe fileHashCodec)
        |> Codec.field "channels" .channels (seqDictCodec idCodec backendChannelCodec)
        |> Codec.field "members" .members (seqDictCodec idCodec memberDataCodec)
        |> Codec.field "owner" .owner idCodec
        |> Codec.field "invites" .invites (seqDictCodec secretIdCodec inviteDataCodec)
        |> Codec.buildObject


discordBackendGuildCodec : Codec DiscordBackendGuild
discordBackendGuildCodec =
    Codec.object DiscordBackendGuild
        |> Codec.field "name" .name guildNameCodec
        |> Codec.field "icon" .icon (Codec.maybe fileHashCodec)
        |> Codec.field "channels" .channels (seqDictCodec discordIdCodec discordBackendChannelCodec)
        |> Codec.field "members" .members (seqDictCodec discordIdCodec memberDataCodec)
        |> Codec.field "owner" .owner discordIdCodec
        |> Codec.buildObject



-- Helper codecs for guild member and invite data


memberDataCodec : Codec { joinedAt : Time.Posix }
memberDataCodec =
    Codec.object (\joinedAt -> { joinedAt = joinedAt })
        |> Codec.field "joinedAt" .joinedAt timePosixCodec
        |> Codec.buildObject


inviteDataCodec : Codec { createdAt : Time.Posix, createdBy : Id UserId }
inviteDataCodec =
    Codec.object (\createdAt createdBy -> { createdAt = createdAt, createdBy = createdBy })
        |> Codec.field "createdAt" .createdAt timePosixCodec
        |> Codec.field "createdBy" .createdBy idCodec
        |> Codec.buildObject
