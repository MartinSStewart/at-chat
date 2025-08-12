module Evergreen.V24.Discord exposing (..)

import Duration
import Evergreen.V24.Discord.Id
import Quantity
import Time


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


type UserDiscriminator
    = UserDiscriminator Int


type AvatarHash
    = AvatarHash Never


type ImageHash hashType
    = ImageHash String


type OptionalData a
    = Included a
    | Missing


type alias User =
    { id : Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.UserId
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


type IconHash
    = IconHash Never


type alias Permissions =
    { createInstantInvite : Bool
    , kickMembers : Bool
    , banMembers : Bool
    , administrator : Bool
    , manageChannels : Bool
    , manageGuild : Bool
    , addReaction : Bool
    , viewAuditLog : Bool
    , prioritySpeaker : Bool
    , stream : Bool
    , viewChannel : Bool
    , sendMessages : Bool
    , sentTextToSpeechMessages : Bool
    , manageMessages : Bool
    , embedLinks : Bool
    , attachFiles : Bool
    , readMessageHistory : Bool
    , mentionEveryone : Bool
    , useExternalEmojis : Bool
    , viewGuildInsights : Bool
    , connect : Bool
    , speak : Bool
    , muteMembers : Bool
    , deafenMembers : Bool
    , moveMembers : Bool
    , useVoiceActivityDetection : Bool
    , changeNickname : Bool
    , manageNicknames : Bool
    , manageRoles : Bool
    , manageWebhooks : Bool
    , manageGuildExpressions : Bool
    , useApplicationCommands : Bool
    , requestToSpeak : Bool
    , manageEvents : Bool
    , manageThreads : Bool
    , createPublicThreads : Bool
    , createPrivateThreads : Bool
    , useExternalStickers : Bool
    , sendMessagesInThreads : Bool
    , useEmbeddedActivities : Bool
    , moderateMembers : Bool
    , viewCreatorMontetizationAnalytics : Bool
    , useSoundboard : Bool
    , createGuildExpressions : Bool
    , createEvents : Bool
    , useExternalSounds : Bool
    , sendVoiceMessages : Bool
    , sendPolls : Bool
    , useExternalApps : Bool
    }


type alias PartialGuild =
    { id : Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.GuildId
    , name : String
    , icon : Maybe (ImageHash IconHash)
    , owner : Bool
    , permissions : Permissions
    }


type SplashHash
    = SplashHash Never


type DiscoverySplashHash
    = DiscoverSplashHash Never


type EmojiType
    = UnicodeEmojiType String
    | CustomEmojiType
        { id : Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.CustomEmojiId
        , name : Maybe String
        }


type alias EmojiData =
    { type_ : EmojiType
    , roles : OptionalData (List (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.RoleId))
    , user : OptionalData User
    , requireColons : OptionalData Bool
    , managed : OptionalData Bool
    , animated : OptionalData Bool
    , available : OptionalData Bool
    }


type alias GuildMember =
    { user : User
    , nickname : Maybe String
    , roles : List (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.RoleId)
    , joinedAt : Time.Posix
    , premiumSince : OptionalData (Maybe Time.Posix)
    , deaf : Bool
    , mute : Bool
    }


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
    { id : Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.ChannelId
    , type_ : ChannelType
    , guildId : OptionalData (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.GuildId)
    , position : OptionalData Int
    , name : OptionalData String
    , topic : OptionalData (Maybe String)
    , nsfw : OptionalData Bool
    , lastMessageId : OptionalData (Maybe (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.MessageId))
    , bitrate : OptionalData (Quantity.Quantity Int (Quantity.Rate Bits Duration.Seconds))
    , userLimit : OptionalData Int
    , rateLimitPerUser : OptionalData (Quantity.Quantity Int Duration.Seconds)
    , recipients : OptionalData (List User)
    , icon : OptionalData (Maybe String)
    , ownerId : OptionalData (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.UserId)
    , applicationId : OptionalData (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.ApplicationId)
    , parentId : OptionalData (Maybe (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.ChannelId))
    , lastPinTimestamp : OptionalData Time.Posix
    }


type BannerHash
    = BannerHash Never


type alias Guild =
    { id : Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.GuildId
    , name : String
    , icon : Maybe (ImageHash IconHash)
    , splash : Maybe (ImageHash SplashHash)
    , discoverySplash : Maybe (ImageHash DiscoverySplashHash)
    , owner : OptionalData Bool
    , ownerId : Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.UserId
    , permissions : OptionalData Permissions
    , region : String
    , afkChannelId : Maybe (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.ChannelId)
    , afkTimeout : Quantity.Quantity Int Duration.Seconds
    , embedEnabled : OptionalData Bool
    , embedChannelId : OptionalData (Maybe (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.ChannelId))
    , verificationLevel : Int
    , defaultMessageNotifications : Int
    , explicitContentFilter : Int
    , emojis : List EmojiData
    , features : List String
    , mfaLevel : Int
    , applicationId : Maybe (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.ApplicationId)
    , widgetEnabled : OptionalData Bool
    , widgetChannelId : OptionalData (Maybe (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.ChannelId))
    , systemChannelId : Maybe (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.ChannelId)
    , systemChannelFlags : Int
    , rulesChannelId : Maybe (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.ChannelId)
    , joinedAt : OptionalData Time.Posix
    , large : OptionalData Bool
    , unavailable : OptionalData Bool
    , memberCount : OptionalData Int
    , members : OptionalData (List GuildMember)
    , channels : OptionalData (List Channel)
    , maxPresences : OptionalData (Maybe Int)
    , maxMembers : OptionalData Int
    , vanityUrlCode : Maybe String
    , description : Maybe String
    , banner : Maybe (ImageHash BannerHash)
    , premiumTier : Int
    , premiumSubscriptionCount : OptionalData Int
    , preferredLocale : String
    , publicUpdatesChannelId : Maybe (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.ChannelId)
    , approximateMemberCount : OptionalData Int
    , approximatePresenceCount : OptionalData Int
    }


type RoleOrUserId
    = RoleOrUserId_RoleId (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.RoleId)
    | RoleOrUserId_UserId (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.UserId)


type alias Overwrite =
    { id : RoleOrUserId
    , allow : Permissions
    , deny : Permissions
    }


type alias Channel2 =
    { id : Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.ChannelId
    , type_ : ChannelType
    , guildId : OptionalData (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.GuildId)
    , position : OptionalData Int
    , name : OptionalData String
    , topic : OptionalData (Maybe String)
    , nsfw : OptionalData Bool
    , lastMessageId : OptionalData (Maybe (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.MessageId))
    , bitrate : OptionalData (Quantity.Quantity Int (Quantity.Rate Bits Duration.Seconds))
    , parentId : OptionalData (Maybe (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.ChannelId))
    , permissionOverwrites : List Overwrite
    }


type alias Attachment =
    { id : Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.AttachmentId
    , filename : String
    , size : Int
    , url : String
    , proxyUrl : String
    , height : Maybe Int
    , width : Maybe Int
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
    { id : Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.MessageId
    , channelId : Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.ChannelId
    , guildId : OptionalData (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.GuildId)
    , author : User
    , content : String
    , timestamp : Time.Posix
    , editedTimestamp : Maybe Time.Posix
    , textToSpeech : Bool
    , mentionEveryone : Bool
    , mentionRoles : List (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.RoleId)
    , attachments : List Attachment
    , reactions : OptionalData (List Reaction)
    , pinned : Bool
    , webhookId : OptionalData (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.WebhookId)
    , type_ : MessageType
    , flags : OptionalData Int
    }
