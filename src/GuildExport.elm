module GuildExport exposing (backendGuildCodec, discordBackendGuildCodec)

{-| Module for encoding and decoding guild data for export/import functionality
-}

import ChannelName exposing (ChannelName(..))
import Codec exposing (Codec)
import CodecExtra
import Emoji exposing (Emoji(..))
import FileName exposing (FileName)
import FileStatus exposing (ContentType(..), FileData, FileHash(..), FileId, ImageMetadata)
import GuildName exposing (GuildName(..))
import Id exposing (ChannelId, Id(..), InviteLinkId, ThreadMessageId, UserId)
import LocalState exposing (BackendChannel, BackendGuild, ChannelStatus(..), DiscordBackendChannel, DiscordBackendGuild)
import Message exposing (Message(..), UserTextMessageData)
import RichText exposing (Language(..), RichText(..))
import SecretId exposing (SecretId(..))
import Thread exposing (BackendThread, DiscordBackendThread, LastTypedAt)


backendGuildCodec : Codec BackendGuild
backendGuildCodec =
    Codec.object BackendGuild
        |> Codec.field "createdAt" .createdAt CodecExtra.timePosix
        |> Codec.field "createdBy" .createdBy Id.codec
        |> Codec.field "name" .name GuildName.codec
        |> Codec.field "icon" .icon (Codec.nullable FileStatus.fileHashCodec)
        |> Codec.field "channels" .channels (CodecExtra.seqDict Id.codec backendChannelCodec)
        |> Codec.field
            "members"
            .members
            (CodecExtra.seqDict
                Id.codec
                (Codec.object (\joinedAt -> { joinedAt = joinedAt })
                    |> Codec.field "joinedAt" .joinedAt CodecExtra.timePosix
                    |> Codec.buildObject
                )
            )
        |> Codec.field "owner" .owner Id.codec
        |> Codec.field
            "invites"
            .invites
            (CodecExtra.seqDict
                SecretId.codec
                (Codec.object (\createdAt createdBy -> { createdAt = createdAt, createdBy = createdBy })
                    |> Codec.field "createdAt" .createdAt CodecExtra.timePosix
                    |> Codec.field "createdBy" .createdBy Id.codec
                    |> Codec.buildObject
                )
            )
        |> Codec.buildObject


backendChannelCodec : Codec BackendChannel
backendChannelCodec =
    Codec.object BackendChannel
        |> Codec.field "createdAt" .createdAt CodecExtra.timePosix
        |> Codec.field "createdBy" .createdBy Id.codec
        |> Codec.field "name" .name ChannelName.codec
        |> Codec.field "messages" .messages (Codec.array (messageCodec Id.codec))
        |> Codec.field "status" .status channelStatusCodec
        |> Codec.field "lastTypedAt" .lastTypedAt (CodecExtra.seqDict Id.codec lastTypedAtCodec)
        |> Codec.field "threads" .threads (CodecExtra.seqDict Id.codec backendThreadCodec)
        |> Codec.buildObject


messageCodec : Codec userId -> Codec (Message messageId userId)
messageCodec userId =
    Codec.custom
        (\userTextMessageEncoder userJoinedMessageEncoder deletedMessageEncoder value ->
            case value of
                Message.UserTextMessage arg0 ->
                    userTextMessageEncoder arg0

                Message.UserJoinedMessage arg0 arg1 arg2 ->
                    userJoinedMessageEncoder arg0 arg1 arg2

                Message.DeletedMessage arg0 ->
                    deletedMessageEncoder arg0
        )
        |> Codec.variant1 "UserTextMessage" Message.UserTextMessage (userTextMessageDataCodec userId)
        |> Codec.variant3
            "UserJoinedMessage"
            Message.UserJoinedMessage
            CodecExtra.timePosix
            userId
            (CodecExtra.seqDict emojiCodec (CodecExtra.nonemptySet userId))
        |> Codec.variant1 "DeletedMessage" Message.DeletedMessage CodecExtra.timePosix
        |> Codec.buildCustom


userTextMessageDataCodec : Codec userId -> Codec (UserTextMessageData messageId userId)
userTextMessageDataCodec userId =
    Codec.object UserTextMessageData
        |> Codec.field "createdAt" .createdAt CodecExtra.timePosix
        |> Codec.field "createdBy" .createdBy userId
        |> Codec.field "content" .content (CodecExtra.nonempty (RichText.codec userId))
        |> Codec.field "reactions" .reactions (CodecExtra.seqDict emojiCodec (CodecExtra.nonemptySet userId))
        |> Codec.field "editedAt" .editedAt (Codec.nullable CodecExtra.timePosix)
        |> Codec.field "repliedTo" .repliedTo (Codec.nullable Id.codec)
        |> Codec.field "attachedFiles" .attachedFiles (CodecExtra.seqDict Id.codec fileDataCodec)
        |> Codec.buildObject


emojiCodec : Codec Emoji
emojiCodec =
    Codec.custom
        (\unicodeEmojiEncoder value ->
            case value of
                Emoji.UnicodeEmoji arg0 ->
                    unicodeEmojiEncoder arg0
        )
        |> Codec.variant1 "UnicodeEmoji" Emoji.UnicodeEmoji Codec.string
        |> Codec.buildCustom


fileDataCodec : Codec FileData
fileDataCodec =
    Codec.object FileData
        |> Codec.field "fileName" .fileName FileName.codec
        |> Codec.field "fileSize" .fileSize Codec.int
        |> Codec.field "imageMetadata" .imageMetadata (Codec.nullable imageMetadataCodec)
        |> Codec.field "contentType" .contentType contentTypeCodec
        |> Codec.field "fileHash" .fileHash FileStatus.fileHashCodec
        |> Codec.buildObject


imageMetadataCodec : Codec ImageMetadata
imageMetadataCodec =
    Codec.object ImageMetadata
        |> Codec.field "imageSize" .imageSize (Codec.tuple CodecExtra.quantityInt CodecExtra.quantityInt)
        |> Codec.field "orientation" .orientation (Codec.nullable orientationCodec)
        |> Codec.field "gpsLocation" .gpsLocation (Codec.nullable locationCodec)
        |> Codec.field "cameraOwner" .cameraOwner (Codec.nullable Codec.string)
        |> Codec.field "exposureTime" .exposureTime (Codec.nullable exposureTimeCodec)
        |> Codec.field "fNumber" .fNumber (Codec.nullable Codec.float)
        |> Codec.field "focalLength" .focalLength (Codec.nullable Codec.float)
        |> Codec.field "isoSpeedRating" .isoSpeedRating (Codec.nullable Codec.int)
        |> Codec.field "make" .make (Codec.nullable Codec.string)
        |> Codec.field "model" .model (Codec.nullable Codec.string)
        |> Codec.field "software" .software (Codec.nullable Codec.string)
        |> Codec.field "userComment" .userComment (Codec.nullable Codec.string)
        |> Codec.buildObject


orientationCodec : Codec FileStatus.Orientation
orientationCodec =
    Codec.custom
        (\noChangeEncoder rotation90Encoder rotation180Encoder rotation270Encoder mirroredEncoder mirroredRotation90Encoder mirroredRotation180Encoder mirroredRotation270Encoder value ->
            case value of
                FileStatus.NoChange ->
                    noChangeEncoder

                FileStatus.Rotation90 ->
                    rotation90Encoder

                FileStatus.Rotation180 ->
                    rotation180Encoder

                FileStatus.Rotation270 ->
                    rotation270Encoder

                FileStatus.Mirrored ->
                    mirroredEncoder

                FileStatus.MirroredRotation90 ->
                    mirroredRotation90Encoder

                FileStatus.MirroredRotation180 ->
                    mirroredRotation180Encoder

                FileStatus.MirroredRotation270 ->
                    mirroredRotation270Encoder
        )
        |> Codec.variant0 "NoChange" FileStatus.NoChange
        |> Codec.variant0 "Rotation90" FileStatus.Rotation90
        |> Codec.variant0 "Rotation180" FileStatus.Rotation180
        |> Codec.variant0 "Rotation270" FileStatus.Rotation270
        |> Codec.variant0 "Mirrored" FileStatus.Mirrored
        |> Codec.variant0 "MirroredRotation90" FileStatus.MirroredRotation90
        |> Codec.variant0 "MirroredRotation180" FileStatus.MirroredRotation180
        |> Codec.variant0 "MirroredRotation270" FileStatus.MirroredRotation270
        |> Codec.buildCustom


locationCodec : Codec FileStatus.Location
locationCodec =
    Codec.object FileStatus.Location
        |> Codec.field "lat" .lat Codec.float
        |> Codec.field "lon" .lon Codec.float
        |> Codec.buildObject


exposureTimeCodec : Codec FileStatus.ExposureTime
exposureTimeCodec =
    Codec.object FileStatus.ExposureTime
        |> Codec.field "numerator" .numerator Codec.int
        |> Codec.field "denominator" .denominator Codec.int
        |> Codec.buildObject


contentTypeCodec : Codec ContentType
contentTypeCodec =
    Codec.custom
        (\contentTypeEncoder value ->
            case value of
                FileStatus.ContentType arg0 ->
                    contentTypeEncoder arg0
        )
        |> Codec.variant1 "ContentType" ContentType Codec.int
        |> Codec.buildCustom


channelStatusCodec : Codec ChannelStatus
channelStatusCodec =
    Codec.custom
        (\channelActiveEncoder channelDeletedEncoder value ->
            case value of
                LocalState.ChannelActive ->
                    channelActiveEncoder

                LocalState.ChannelDeleted arg0 ->
                    channelDeletedEncoder arg0
        )
        |> Codec.variant0 "ChannelActive" LocalState.ChannelActive
        |> Codec.variant1
            "ChannelDeleted"
            LocalState.ChannelDeleted
            (Codec.object (\deletedAt deletedBy -> { deletedAt = deletedAt, deletedBy = deletedBy })
                |> Codec.field "deletedAt" .deletedAt CodecExtra.timePosix
                |> Codec.field "deletedBy" .deletedBy Id.codec
                |> Codec.buildObject
            )
        |> Codec.buildCustom


lastTypedAtCodec : Codec (LastTypedAt messageId)
lastTypedAtCodec =
    Codec.object LastTypedAt
        |> Codec.field "time" .time CodecExtra.timePosix
        |> Codec.field "messageIndex" .messageIndex (Codec.nullable Id.codec)
        |> Codec.buildObject


backendThreadCodec : Codec BackendThread
backendThreadCodec =
    Codec.object BackendThread
        |> Codec.field "messages" .messages (Codec.array (messageCodec Id.codec))
        |> Codec.field "lastTypedAt" .lastTypedAt (CodecExtra.seqDict Id.codec lastTypedAtCodec)
        |> Codec.buildObject


discordBackendGuildCodec : Codec DiscordBackendGuild
discordBackendGuildCodec =
    Codec.object DiscordBackendGuild
        |> Codec.field "name" .name GuildName.codec
        |> Codec.field "icon" .icon (Codec.nullable FileStatus.fileHashCodec)
        |> Codec.field "channels" .channels (CodecExtra.seqDict CodecExtra.discordId discordBackendChannelCodec)
        |> Codec.field
            "members"
            .members
            (CodecExtra.seqDict
                CodecExtra.discordId
                (Codec.object (\joinedAt -> { joinedAt = joinedAt })
                    |> Codec.field "joinedAt" .joinedAt CodecExtra.timePosix
                    |> Codec.buildObject
                )
            )
        |> Codec.field "owner" .owner CodecExtra.discordId
        |> Codec.buildObject


discordBackendChannelCodec : Codec DiscordBackendChannel
discordBackendChannelCodec =
    Codec.object DiscordBackendChannel
        |> Codec.field "name" .name ChannelName.codec
        |> Codec.field "messages" .messages (Codec.array (messageCodec CodecExtra.discordId))
        |> Codec.field "status" .status channelStatusCodec
        |> Codec.field "lastTypedAt" .lastTypedAt (CodecExtra.seqDict CodecExtra.discordId lastTypedAtCodec)
        |> Codec.field "linkedMessageIds" .linkedMessageIds (CodecExtra.oneToOne CodecExtra.discordId Id.codec)
        |> Codec.field "threads" .threads (CodecExtra.seqDict Id.codec discordBackendThreadCodec)
        |> Codec.buildObject


discordBackendThreadCodec : Codec DiscordBackendThread
discordBackendThreadCodec =
    Codec.object DiscordBackendThread
        |> Codec.field "messages" .messages (Codec.array (messageCodec CodecExtra.discordId))
        |> Codec.field "lastTypedAt" .lastTypedAt (CodecExtra.seqDict CodecExtra.discordId lastTypedAtCodec)
        |> Codec.field "linkedMessageIds" .linkedMessageIds (CodecExtra.oneToOne CodecExtra.discordId Id.codec)
        |> Codec.buildObject
