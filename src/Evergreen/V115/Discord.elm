module Evergreen.V115.Discord exposing (..)

import Duration
import Evergreen.V115.Discord.Id
import Evergreen.V115.SafeJson
import Quantity
import Time


type ErrorCode
    = GeneralError0
    | UnknownAccount10001
    | UnknownApp10002
    | UnknownChannel10003
    | UnknownGuild10004
    | UnknownIntegration1005
    | UnknownInvite10006
    | UnknownMember10007
    | UnknownMessage10008
    | UnknownPermissionOverwrite10009
    | UnknownProvider10010
    | UnknownRole10011
    | UnknownToken10012
    | UnknownUser10013
    | UnknownEmoji10014
    | UnknownWebhook10015
    | UnknownBan10026
    | UnknownSku10027
    | UnknownStoreListing10028
    | UnknownEntitlement10029
    | UnknownBuild10030
    | UnknownLobby10031
    | UnknownBranch10032
    | UnknownRedistributable10036
    | BotsCannotUseThisEndpoint20001
    | OnlyBotsCanUseThisEndpoint20002
    | MaxNumberOfGuilds30001
    | MaxNumberOfFriends30002
    | MaxNumberOfPinsForChannel30003
    | MaxNumberOfGuildsRoles30005
    | MaxNumberOfWebhooks30007
    | MaxNumberOfReactions30010
    | MaxNumberOfGuildChannels30013
    | MaxNumberOfAttachmentsInAMessage30015
    | MaxNumberOfInvitesReached30016
    | UnauthorizedProvideAValidTokenAndTryAgain40001
    | VerifyYourAccount40002
    | RequestEntityTooLarge40005
    | FeatureTemporarilyDisabledServerSide40006
    | UserIsBannedFromThisGuild40007
    | MissingAccess50001
    | InvalidAccountType50002
    | CannotExecuteActionOnADmChannel50003
    | GuildWidgetDisabled50004
    | CannotEditAMessageAuthoredByAnotherUser50005
    | CannotSendAnEmptyMessage50006
    | CannotSendMessagesToThisUser50007
    | CannotSendMessagesInAVoiceChannel50008
    | ChannelVerificationLevelTooHigh50009
    | OAuth2AppDoesNotHaveABot50010
    | OAuth2AppLimitReached50011
    | InvalidOAuth2State50012
    | YouLackPermissionsToPerformThatAction50013
    | InvalidAuthenticationTokenProvided50014
    | NoteWasTooLong50015
    | ProvidedTooFewOrTooManyMessagesToDelete50016
    | MessageCanOnlyBePinnedToChannelItIsIn50019
    | InviteCodeWasEitherInvalidOrTaken50020
    | CannotExecuteActionOnASystemMessage50021
    | InvalidOAuth2AccessTokenProvided50025
    | MessageProvidedWasTooOldToBulkDelete50034
    | InvalidFormBody50035
    | InviteWasAcceptedToAGuildTheAppsBotIsNotIn50036
    | InvalidApiVersionProvided50041
    | ReactionWasBlocked90001
    | ApiIsCurrentlyOverloaded130000


type alias RateLimit =
    { retryAfter : Duration.Duration
    , isGlobal : Bool
    }


type HttpError
    = NotModified304 ErrorCode
    | Unauthorized401 ErrorCode
    | Forbidden403 ErrorCode
    | NotFound404 ErrorCode
    | TooManyRequests429 RateLimit
    | GatewayUnavailable502 ErrorCode
    | ServerError5xx
        { statusCode : Int
        , errorCode : ErrorCode
        }
    | NetworkError
    | Timeout
    | UnexpectedError String


type AvatarHash
    = AvatarHash Never


type ImageHash hashType
    = ImageHash String


type UserDiscriminator
    = UserDiscriminator Int


type alias PartialUser =
    { id : Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId
    , username : String
    , avatar : Maybe (ImageHash AvatarHash)
    , discriminator : UserDiscriminator
    }


type alias UserAuth =
    { token : String
    , userAgent : String
    , xSuperProperties : Evergreen.V115.SafeJson.SafeJson
    }


type OptionalData a
    = Included a
    | Missing


type alias User =
    { id : Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId
    , username : String
    , discriminator : UserDiscriminator
    , avatar : Maybe (ImageHash AvatarHash)
    , bot : OptionalData Bool
    , system : OptionalData Bool
    , mfaEnabled : OptionalData Bool
    , locale : OptionalData String
    , verified : OptionalData Bool
    , email : OptionalData (Maybe String)
    , flags : OptionalData Int
    , premiumType : OptionalData Int
    , publicFlags : OptionalData Int
    }


type SessionId
    = SessionId String


type SequenceCounter
    = SequenceCounter Int


type alias Model connection =
    { websocketHandle : Maybe connection
    , gatewayState : Maybe ( SessionId, SequenceCounter )
    , heartbeatInterval : Maybe Duration.Duration
    }


type Msg
    = GotWebsocketData String
    | WebsocketClosed


type alias Attachment =
    { id : Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.AttachmentId
    , filename : String
    , size : Int
    , url : String
    , proxyUrl : String
    , height : Maybe Int
    , width : Maybe Int
    }


type EmojiType
    = UnicodeEmojiType String
    | CustomEmojiType
        { id : Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.CustomEmojiId
        , name : Maybe String
        }


type alias EmojiData =
    { type_ : EmojiType
    , roles : OptionalData (List (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.RoleId))
    , user : OptionalData User
    , requireColons : OptionalData Bool
    , managed : OptionalData Bool
    , animated : OptionalData Bool
    , available : OptionalData Bool
    }


type alias Reaction =
    { count : Int
    , me : Bool
    , emoji : EmojiData
    }


type MessageType
    = DefaultMessageType
    | RecipientAdd
    | RecipientRemove
    | Call
    | ChannelNameChange
    | ChannelIconChange
    | ChannelPinnedMessage
    | GuildMemberJoin
    | UserPremiumGuildSubscription
    | UserPremiumGuildSubscriptionTier1
    | UserPremiumGuildSubscriptionTier2
    | UserPremiumGuildSubscriptionTier3
    | ChannelFollowAdd
    | GuildDiscoveryDisqualified
    | GuildDiscoveryRequalified
    | GuildDiscoveryGracePeriodInitialWarning
    | GuildDiscoveryGracePeriodFinalWarning
    | ThreadCreated
    | Reply
    | ApplicationCommand
    | ThreadStarterMessage
    | GuildInviteReminder


type alias Message =
    { id : Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.MessageId
    , channelId : Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId
    , guildId : OptionalData (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId)
    , author : User
    , content : String
    , timestamp : Time.Posix
    , editedTimestamp : Maybe Time.Posix
    , textToSpeech : Bool
    , mentionEveryone : Bool
    , mentionRoles : List (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.RoleId)
    , attachments : List Attachment
    , reactions : OptionalData (List Reaction)
    , pinned : Bool
    , webhookId : OptionalData (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.WebhookId)
    , type_ : MessageType
    , flags : OptionalData Int
    , referencedMessage : ReferencedMessage
    }


type ReferencedMessage
    = Referenced Message
    | ReferenceDeleted
    | NoReference


type ChannelType
    = GuildText
    | DirectMessage
    | GuildVoice
    | GroupDirectMessage
    | GuildCategory
    | GuildAnnouncement
    | AnnouncementThread
    | PublicThread
    | PrivateThread
    | GuildStageVoice
    | GuildDirectory
    | GuildForum
    | GuildMedia


type Bits
    = Bits Never


type alias Channel =
    { id : Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId
    , type_ : ChannelType
    , guildId : OptionalData (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId)
    , position : OptionalData Int
    , name : OptionalData String
    , topic : OptionalData (Maybe String)
    , nsfw : OptionalData Bool
    , lastMessageId : OptionalData (Maybe (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.MessageId))
    , bitrate : OptionalData (Quantity.Quantity Int (Quantity.Rate Bits Duration.Seconds))
    , userLimit : OptionalData Int
    , rateLimitPerUser : OptionalData (Quantity.Quantity Int Duration.Seconds)
    , recipients : OptionalData (List User)
    , icon : OptionalData (Maybe String)
    , ownerId : OptionalData (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId)
    , applicationId : OptionalData (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ApplicationId)
    , parentId : OptionalData (Maybe (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId))
    , lastPinTimestamp : OptionalData Time.Posix
    }


type IconHash
    = IconHash Never


type alias GatewayGuildProperties =
    { nsfwLevel : Int
    , systemChannelFlags : Int
    , icon : Maybe (ImageHash IconHash)
    , maxVideoChannelUsers : Int
    , id : Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId
    , systemChannelId : Maybe (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId)
    , afkChannelId : Maybe (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId)
    , name : String
    , maxMembers : Maybe Int
    , nsfw : Bool
    , description : Maybe String
    , preferredLocale : String
    , rulesChannelId : Maybe (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId)
    , ownerId : Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId
    }


type StickerType
    = StandardSticker
    | GuildSticker


type StickerFormatType
    = PngFormat
    | ApngFormat
    | LottieFormat
    | GifFormat


type alias Sticker =
    { id : Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.StickerId
    , packId : OptionalData (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.StickerPackId)
    , name : String
    , description : Maybe String
    , tags : String
    , stickerType : StickerType
    , formatType : StickerFormatType
    , available : OptionalData Bool
    , guildId : OptionalData String
    , user : OptionalData PartialUser
    , sortValue : OptionalData Int
    }


type alias GatewayGuild =
    { joinedAt : Time.Posix
    , large : Bool
    , unavailable : OptionalData Bool
    , geoRestricted : OptionalData Bool
    , memberCount : Int
    , channels : List Channel
    , threads : List Channel
    , dataMode : String
    , properties : GatewayGuildProperties
    , stickers : List Sticker
    , emojis : List EmojiData
    , premiumSubscriptionCount : Int
    }
