module GuildExport exposing (backendGuildCodec, discordExportCodec)

{-| Module for encoding and decoding guild data for export/import functionality
-}

import ChannelName
import Codec exposing (Codec)
import CodecExtra
import Discord
import DmChannel exposing (DiscordChannelReloadingStatus(..))
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
        |> Codec.field "isReloading" .isReloading discordChannelReloadStatus
        |> Codec.buildObject


discordChannelReloadStatus : Codec DiscordChannelReloadingStatus
discordChannelReloadStatus =
    Codec.custom
        (\a b c value ->
            case value of
                DiscordChannel_NotReloading ->
                    a

                DiscordChannel_Reloading argA ->
                    b argA

                DiscordChannel_LastReloadFailed argA argB ->
                    c argA argB
        )
        |> Codec.variant0 "DiscordChannel_NotReloading" DiscordChannel_NotReloading
        |> Codec.variant1 "DiscordChannel_Reloading" DiscordChannel_Reloading CodecExtra.timePosix
        |> Codec.variant2 "DiscordChannel_LastReloadFailed" DiscordChannel_LastReloadFailed CodecExtra.timePosix discordHttpErrorCodec
        |> Codec.buildCustom


discordHttpErrorCodec : Codec Discord.HttpError
discordHttpErrorCodec =
    Codec.custom
        (\notModified304Encoder unauthorized401Encoder forbidden403Encoder notFound404Encoder tooManyRequests429Encoder gatewayUnavailable502Encoder serverError5xxEncoder networkErrorEncoder timeoutEncoder unexpectedErrorEncoder value ->
            case value of
                Discord.NotModified304 argA ->
                    notModified304Encoder argA

                Discord.Unauthorized401 argA ->
                    unauthorized401Encoder argA

                Discord.Forbidden403 argA ->
                    forbidden403Encoder argA

                Discord.NotFound404 argA ->
                    notFound404Encoder argA

                Discord.TooManyRequests429 argA ->
                    tooManyRequests429Encoder argA

                Discord.GatewayUnavailable502 argA ->
                    gatewayUnavailable502Encoder argA

                Discord.ServerError5xx argA ->
                    serverError5xxEncoder argA

                Discord.NetworkError ->
                    networkErrorEncoder

                Discord.Timeout ->
                    timeoutEncoder

                Discord.UnexpectedError argA ->
                    unexpectedErrorEncoder argA
        )
        |> Codec.variant1 "NotModified304" Discord.NotModified304 errorCodeCodec
        |> Codec.variant1 "Unauthorized401" Discord.Unauthorized401 errorCodeCodec
        |> Codec.variant1 "Forbidden403" Discord.Forbidden403 errorCodeCodec
        |> Codec.variant1 "NotFound404" Discord.NotFound404 errorCodeCodec
        |> Codec.variant1 "TooManyRequests429" Discord.TooManyRequests429 rateLimitCodec
        |> Codec.variant1 "GatewayUnavailable502" Discord.GatewayUnavailable502 errorCodeCodec
        |> Codec.variant1
            "ServerError5xx"
            Discord.ServerError5xx
            (Codec.object (\statusCode errorCode -> { statusCode = statusCode, errorCode = errorCode })
                |> Codec.field "statusCode" .statusCode Codec.int
                |> Codec.field "errorCode" .errorCode errorCodeCodec
                |> Codec.buildObject
            )
        |> Codec.variant0 "NetworkError" Discord.NetworkError
        |> Codec.variant0 "Timeout" Discord.Timeout
        |> Codec.variant1 "UnexpectedError" Discord.UnexpectedError Codec.string
        |> Codec.buildCustom


errorCodeCodec : Codec Discord.ErrorCode
errorCodeCodec =
    Codec.enum
        Codec.string
        [ ( "GeneralError0", Discord.GeneralError0 )
        , ( "UnknownAccount10001", Discord.UnknownAccount10001 )
        , ( "UnknownApp10002", Discord.UnknownApp10002 )
        , ( "UnknownChannel10003", Discord.UnknownChannel10003 )
        , ( "UnknownGuild10004", Discord.UnknownGuild10004 )
        , ( "UnknownIntegration1005", Discord.UnknownIntegration1005 )
        , ( "UnknownInvite10006", Discord.UnknownInvite10006 )
        , ( "UnknownMember10007", Discord.UnknownMember10007 )
        , ( "UnknownMessage10008", Discord.UnknownMessage10008 )
        , ( "UnknownPermissionOverwrite10009", Discord.UnknownPermissionOverwrite10009 )
        , ( "UnknownProvider10010", Discord.UnknownProvider10010 )
        , ( "UnknownRole10011", Discord.UnknownRole10011 )
        , ( "UnknownToken10012", Discord.UnknownToken10012 )
        , ( "UnknownUser10013", Discord.UnknownUser10013 )
        , ( "UnknownEmoji10014", Discord.UnknownEmoji10014 )
        , ( "UnknownWebhook10015", Discord.UnknownWebhook10015 )
        , ( "UnknownBan10026", Discord.UnknownBan10026 )
        , ( "UnknownSku10027", Discord.UnknownSku10027 )
        , ( "UnknownStoreListing10028", Discord.UnknownStoreListing10028 )
        , ( "UnknownEntitlement10029", Discord.UnknownEntitlement10029 )
        , ( "UnknownBuild10030", Discord.UnknownBuild10030 )
        , ( "UnknownLobby10031", Discord.UnknownLobby10031 )
        , ( "UnknownBranch10032", Discord.UnknownBranch10032 )
        , ( "UnknownRedistributable10036", Discord.UnknownRedistributable10036 )
        , ( "BotsCannotUseThisEndpoint20001", Discord.BotsCannotUseThisEndpoint20001 )
        , ( "OnlyBotsCanUseThisEndpoint20002", Discord.OnlyBotsCanUseThisEndpoint20002 )
        , ( "MaxNumberOfGuilds30001", Discord.MaxNumberOfGuilds30001 )
        , ( "MaxNumberOfFriends30002", Discord.MaxNumberOfFriends30002 )
        , ( "MaxNumberOfPinsForChannel30003", Discord.MaxNumberOfPinsForChannel30003 )
        , ( "MaxNumberOfGuildsRoles30005", Discord.MaxNumberOfGuildsRoles30005 )
        , ( "MaxNumberOfWebhooks30007", Discord.MaxNumberOfWebhooks30007 )
        , ( "MaxNumberOfReactions30010", Discord.MaxNumberOfReactions30010 )
        , ( "MaxNumberOfGuildChannels30013", Discord.MaxNumberOfGuildChannels30013 )
        , ( "MaxNumberOfAttachmentsInAMessage30015", Discord.MaxNumberOfAttachmentsInAMessage30015 )
        , ( "MaxNumberOfInvitesReached30016", Discord.MaxNumberOfInvitesReached30016 )
        , ( "UnauthorizedProvideAValidTokenAndTryAgain40001", Discord.UnauthorizedProvideAValidTokenAndTryAgain40001 )
        , ( "VerifyYourAccount40002", Discord.VerifyYourAccount40002 )
        , ( "RequestEntityTooLarge40005", Discord.RequestEntityTooLarge40005 )
        , ( "FeatureTemporarilyDisabledServerSide40006", Discord.FeatureTemporarilyDisabledServerSide40006 )
        , ( "UserIsBannedFromThisGuild40007", Discord.UserIsBannedFromThisGuild40007 )
        , ( "MissingAccess50001", Discord.MissingAccess50001 )
        , ( "InvalidAccountType50002", Discord.InvalidAccountType50002 )
        , ( "CannotExecuteActionOnADmChannel50003", Discord.CannotExecuteActionOnADmChannel50003 )
        , ( "GuildWidgetDisabled50004", Discord.GuildWidgetDisabled50004 )
        , ( "CannotEditAMessageAuthoredByAnotherUser50005", Discord.CannotEditAMessageAuthoredByAnotherUser50005 )
        , ( "CannotSendAnEmptyMessage50006", Discord.CannotSendAnEmptyMessage50006 )
        , ( "CannotSendMessagesToThisUser50007", Discord.CannotSendMessagesToThisUser50007 )
        , ( "CannotSendMessagesInAVoiceChannel50008", Discord.CannotSendMessagesInAVoiceChannel50008 )
        , ( "ChannelVerificationLevelTooHigh50009", Discord.ChannelVerificationLevelTooHigh50009 )
        , ( "OAuth2AppDoesNotHaveABot50010", Discord.OAuth2AppDoesNotHaveABot50010 )
        , ( "OAuth2AppLimitReached50011", Discord.OAuth2AppLimitReached50011 )
        , ( "InvalidOAuth2State50012", Discord.InvalidOAuth2State50012 )
        , ( "YouLackPermissionsToPerformThatAction50013", Discord.YouLackPermissionsToPerformThatAction50013 )
        , ( "InvalidAuthenticationTokenProvided50014", Discord.InvalidAuthenticationTokenProvided50014 )
        , ( "NoteWasTooLong50015", Discord.NoteWasTooLong50015 )
        , ( "ProvidedTooFewOrTooManyMessagesToDelete50016", Discord.ProvidedTooFewOrTooManyMessagesToDelete50016 )
        , ( "MessageCanOnlyBePinnedToChannelItIsIn50019", Discord.MessageCanOnlyBePinnedToChannelItIsIn50019 )
        , ( "InviteCodeWasEitherInvalidOrTaken50020", Discord.InviteCodeWasEitherInvalidOrTaken50020 )
        , ( "CannotExecuteActionOnASystemMessage50021", Discord.CannotExecuteActionOnASystemMessage50021 )
        , ( "InvalidOAuth2AccessTokenProvided50025", Discord.InvalidOAuth2AccessTokenProvided50025 )
        , ( "MessageProvidedWasTooOldToBulkDelete50034", Discord.MessageProvidedWasTooOldToBulkDelete50034 )
        , ( "InvalidFormBody50035", Discord.InvalidFormBody50035 )
        , ( "InviteWasAcceptedToAGuildTheAppsBotIsNotIn50036", Discord.InviteWasAcceptedToAGuildTheAppsBotIsNotIn50036 )
        , ( "InvalidApiVersionProvided50041", Discord.InvalidApiVersionProvided50041 )
        , ( "ReactionWasBlocked90001", Discord.ReactionWasBlocked90001 )
        , ( "ApiIsCurrentlyOverloaded130000", Discord.ApiIsCurrentlyOverloaded130000 )
        ]


rateLimitCodec : Codec Discord.RateLimit
rateLimitCodec =
    Codec.object Discord.RateLimit
        |> Codec.field "retryAfter" .retryAfter CodecExtra.quantityFloat
        |> Codec.field "isGlobal" .isGlobal Codec.bool
        |> Codec.buildObject


discordBackendThreadCodec : Codec DiscordBackendThread
discordBackendThreadCodec =
    Codec.object DiscordBackendThread
        |> Codec.field "messages" .messages (Codec.array (messageCodec CodecExtra.discordId))
        |> Codec.field "lastTypedAt" .lastTypedAt (CodecExtra.seqDict CodecExtra.discordId lastTypedAtCodec)
        |> Codec.field "linkedMessageIds" .linkedMessageIds (CodecExtra.oneToOne CodecExtra.discordId Id.codec)
        |> Codec.buildObject
