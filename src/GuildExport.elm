module GuildExport exposing (backendGuildCodec, discordExportCodec)

{-| Module for encoding and decoding guild data for export/import functionality
-}

import ChannelName
import Codec exposing (Codec)
import CodecExtra
import Discord
import Emoji
import FileName
import FileStatus exposing (FileData, ImageMetadata)
import GuildName
import Id
import LocalState exposing (BackendChannel, BackendGuild, ChannelStatus, DiscordBackendChannel, DiscordBackendGuild)
import Message exposing (Message, UserTextMessageData)
import RichText
import SecretId
import Thread exposing (BackendThread, DiscordBackendThread, LastTypedAt)
import Types exposing (DiscordBasicUserData, DiscordExport, DiscordFullUserDataExport, DiscordNeedsAuthAgainExport, DiscordUserDataExport(..))
import User


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

                Message.UserJoinedMessage argA argB argC ->
                    userJoinedMessageEncoder argA argB argC

                Message.DeletedMessage arg0 ->
                    deletedMessageEncoder arg0
        )
        |> Codec.variant1 "UserTextMessage" Message.UserTextMessage (userTextMessageDataCodec userId)
        |> Codec.variant3
            "UserJoinedMessage"
            Message.UserJoinedMessage
            CodecExtra.timePosix
            userId
            (CodecExtra.seqDict Emoji.codec (CodecExtra.nonemptySet userId))
        |> Codec.variant1 "DeletedMessage" Message.DeletedMessage CodecExtra.timePosix
        |> Codec.buildCustom


userTextMessageDataCodec : Codec userId -> Codec (UserTextMessageData messageId userId)
userTextMessageDataCodec userId =
    Codec.object UserTextMessageData
        |> Codec.field "createdAt" .createdAt CodecExtra.timePosix
        |> Codec.field "createdBy" .createdBy userId
        |> Codec.field "content" .content (CodecExtra.nonempty (RichText.codec userId))
        |> Codec.field "reactions" .reactions (CodecExtra.seqDict Emoji.codec (CodecExtra.nonemptySet userId))
        |> Codec.field "editedAt" .editedAt (Codec.nullable CodecExtra.timePosix)
        |> Codec.field "repliedTo" .repliedTo (Codec.nullable Id.codec)
        |> Codec.field "attachedFiles" .attachedFiles (CodecExtra.seqDict Id.codec fileDataCodec)
        |> Codec.buildObject


fileDataCodec : Codec FileData
fileDataCodec =
    Codec.object FileData
        |> Codec.field "fileName" .fileName FileName.codec
        |> Codec.field "fileSize" .fileSize Codec.int
        |> Codec.field "imageMetadata" .imageMetadata (Codec.nullable imageMetadataCodec)
        |> Codec.field "contentType" .contentType FileStatus.contentTypeCodec
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


discordExportCodec : Codec DiscordExport
discordExportCodec =
    Codec.object Types.DiscordExport
        |> Codec.field "guildId" .guildId CodecExtra.discordId
        |> Codec.field "guild" .guild discordGuildCodec
        |> Codec.field "users" .users (CodecExtra.seqDict CodecExtra.discordId discordUserDataCodec)
        |> Codec.buildObject


discordUserDataCodec : Codec DiscordUserDataExport
discordUserDataCodec =
    Codec.custom
        (\basicDataEncoder fullDataEncoder needsAuthAgainEncoder value ->
            case value of
                BasicDataExport arg0 ->
                    basicDataEncoder arg0

                FullDataExport arg0 ->
                    fullDataEncoder arg0

                NeedsAuthAgainExport arg0 ->
                    needsAuthAgainEncoder arg0
        )
        |> Codec.variant1 "BasicData" BasicDataExport discordBasicUserDataCodec
        |> Codec.variant1 "FullData" FullDataExport discordFullUserDataCodec
        |> Codec.variant1 "NeedsAuthAgain" NeedsAuthAgainExport discordNeedsAuthAgainCodec
        |> Codec.buildCustom


discordBasicUserDataCodec : Codec DiscordBasicUserData
discordBasicUserDataCodec =
    Codec.object Types.DiscordBasicUserData
        |> Codec.field "user" .user partialUserCodec
        |> Codec.field "icon" .icon (Codec.nullable FileStatus.fileHashCodec)
        |> Codec.buildObject


partialUserCodec : Codec Discord.PartialUser
partialUserCodec =
    Codec.object Discord.PartialUser
        |> Codec.field "id" .id CodecExtra.discordId
        |> Codec.field "username" .username Codec.string
        |> Codec.field "avatar" .avatar (Codec.nullable imageHashCodec)
        |> Codec.field "discriminator" .discriminator userDiscriminatorCodec
        |> Codec.buildObject


imageHashCodec : Codec (Discord.ImageHash hashType)
imageHashCodec =
    Codec.custom
        (\imageHashEncoder value ->
            case value of
                Discord.ImageHash arg0 ->
                    imageHashEncoder arg0
        )
        |> Codec.variant1 "ImageHash" Discord.ImageHash Codec.string
        |> Codec.buildCustom


userDiscriminatorCodec : Codec Discord.UserDiscriminator
userDiscriminatorCodec =
    Codec.custom
        (\userDiscriminatorEncoder value ->
            case value of
                Discord.UserDiscriminator arg0 ->
                    userDiscriminatorEncoder arg0
        )
        |> Codec.variant1 "UserDiscriminator" Discord.UserDiscriminator Codec.int
        |> Codec.buildCustom


discordFullUserDataCodec : Codec DiscordFullUserDataExport
discordFullUserDataCodec =
    Codec.object Types.DiscordFullUserDataExport
        |> Codec.field "auth" .auth User.linkDiscordDataCodec
        |> Codec.field "user" .user userCodec
        |> Codec.field "linkedTo" .linkedTo Id.codec
        |> Codec.field "icon" .icon (Codec.nullable FileStatus.fileHashCodec)
        |> Codec.field "linkedAt" .linkedAt CodecExtra.timePosix
        |> Codec.buildObject


discordNeedsAuthAgainCodec : Codec DiscordNeedsAuthAgainExport
discordNeedsAuthAgainCodec =
    Codec.object DiscordNeedsAuthAgainExport
        |> Codec.field "user" .user userCodec
        |> Codec.field "linkedTo" .linkedTo Id.codec
        |> Codec.field "icon" .icon (Codec.nullable FileStatus.fileHashCodec)
        |> Codec.field "linkedAt" .linkedAt CodecExtra.timePosix
        |> Codec.buildObject


userCodec : Codec Discord.User
userCodec =
    Codec.object Discord.User
        |> Codec.field "id" .id CodecExtra.discordId
        |> Codec.field "username" .username Codec.string
        |> Codec.field "discriminator" .discriminator userDiscriminatorCodec
        |> Codec.field "avatar" .avatar (Codec.nullable imageHashCodec)
        |> Codec.field "bot" .bot (optionalDataCodec Codec.bool)
        |> Codec.field "system" .system (optionalDataCodec Codec.bool)
        |> Codec.field "mfaEnabled" .mfaEnabled (optionalDataCodec Codec.bool)
        |> Codec.field "locale" .locale (optionalDataCodec Codec.string)
        |> Codec.field "verified" .verified (optionalDataCodec Codec.bool)
        |> Codec.field "email" .email (optionalDataCodec (Codec.nullable Codec.string))
        |> Codec.field "flags" .flags (optionalDataCodec Codec.int)
        |> Codec.field "premiumType" .premiumType (optionalDataCodec Codec.int)
        |> Codec.field "publicFlags" .publicFlags (optionalDataCodec Codec.int)
        |> Codec.buildObject


optionalDataCodec : Codec a -> Codec (Discord.OptionalData a)
optionalDataCodec a =
    Codec.custom
        (\includedEncoder missingEncoder value ->
            case value of
                Discord.Included arg0 ->
                    includedEncoder arg0

                Discord.Missing ->
                    missingEncoder
        )
        |> Codec.variant1 "Included" Discord.Included a
        |> Codec.variant0 "Missing" Discord.Missing
        |> Codec.buildCustom


discordGuildCodec : Codec DiscordBackendGuild
discordGuildCodec =
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
