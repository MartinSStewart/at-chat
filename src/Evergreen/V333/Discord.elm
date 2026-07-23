module Evergreen.V333.Discord exposing (..)

import Duration
import Evergreen.V333.SafeJson
import Quantity
import Time
import UInt64


type PrivateChannelId
    = PrivateChannelId Never


type Id idType
    = Id UInt64.UInt64


type GuildId
    = GuildId Never


type UserId
    = UserId Never


type ChannelId
    = ChannelId Never


type alias UserAuth =
    { token : String
    , userAgent : String
    , xSuperProperties : Evergreen.V333.SafeJson.SafeJson
    }


type AvatarHash
    = AvatarHash Never


type ImageHash hashType
    = ImageHash String


type UserDiscriminator
    = UserDiscriminator Int


type alias PartialUser =
    { id : Id UserId
    , username : String
    , avatar : Maybe (ImageHash AvatarHash)
    , discriminator : UserDiscriminator
    }


type OptionalData a
    = Included a
    | Missing


type alias User =
    { id : Id UserId
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


type RoleId
    = RoleId Never


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


type MessageId
    = MessageId Never


type RoleOrUserId
    = RoleOrUserId_RoleId (Id RoleId)
    | RoleOrUserId_UserId (Id UserId)


type alias Overwrite =
    { id : RoleOrUserId
    , allow : Permissions
    , deny : Permissions
    }


type StickerId
    = StickerId Never


type StickerFormatType
    = PngFormat
    | ApngFormat
    | LottieFormat
    | GifFormat


type alias RoleColors =
    { primaryColor : Int
    , secondaryColor : Maybe Int
    , tertiaryColor : Maybe Int
    }


type RoleIconHash
    = RoleIconHash Never


type IntegrationId
    = IntegrationId Never


type SubscriptionListingId
    = SubscriptionListingId Never


type alias RoleTags =
    { botId : OptionalData (Id UserId)
    , integrationId : OptionalData (Id IntegrationId)
    , premiumSubscriber : Bool
    , subscriptionListingId : OptionalData (Id SubscriptionListingId)
    , availableForPurchase : Bool
    , guildConnections : Bool
    }


type alias Role =
    { id : Id RoleId
    , name : String
    , description : Maybe String
    , colors : OptionalData RoleColors
    , hoist : Bool
    , icon : Maybe (ImageHash RoleIconHash)
    , unicodeEmoji : Maybe String
    , position : Int
    , permissions : Permissions
    , managed : Bool
    , mentionable : Bool
    , flags : OptionalData Int
    , tags : OptionalData RoleTags
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


type AttachmentId
    = AttachmentId Never


type alias AttachmentFlags =
    { isClip : Bool
    , isThumbnail : Bool
    , isRemix : Bool
    , isSpoiler : Bool
    , containsExplicitMedia : Bool
    , isAnimated : Bool
    , containsGoreContent : Bool
    , containsSelfHarmContent : Bool
    }


type alias Attachment =
    { id : Id AttachmentId
    , filename : String
    , size : Int
    , url : String
    , proxyUrl : String
    , height : Maybe Int
    , width : Maybe Int
    , contentType : OptionalData String
    , flags : OptionalData AttachmentFlags
    }


type EmbedType
    = EmbedType_AgeVerificationSystemNotification
    | EmbedType_Article
    | EmbedType_AutoModerationMessage
    | EmbedType_AutoModerationNotification
    | EmbedType_Gift
    | EmbedType_Gifv
    | EmbedType_Image
    | EmbedType_Link
    | EmbedType_PollResult
    | EmbedType_PostPreview
    | EmbedType_Rich
    | EmbedType_SafetyPolicyNotice
    | EmbedType_SafetySystemNotification
    | EmbedType_Video


type alias Embed =
    { title : OptionalData String
    , type_ : OptionalData EmbedType
    , description : OptionalData String
    , url : OptionalData String
    }


type CustomEmojiId
    = CustomEmojiId Never


type EmojiType
    = UnicodeEmojiType String
    | CustomEmojiType
        { id : Id CustomEmojiId
        , name : Maybe String
        }


type alias EmojiData =
    { type_ : EmojiType
    , roles : OptionalData (List (Id RoleId))
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


type WebhookId
    = WebhookId Never


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
    | ContextMenuCommand
    | AutoModerationAction
    | RoleSubscriptionPurchase
    | InteractionPremiumUpsell
    | StageStart
    | StageEnd
    | StageSpeaker
    | StageRaiseHand
    | StageTopic
    | GuildApplicationPremiumSubscription
    | PrivateChannelIntegrationAdded
    | PrivateChannelIntegrationRemoved
    | PremiumReferral
    | GuildIncidentAlertModeEnabled
    | GuildIncidentAlertModeDisabled
    | GuildIncidentReportRaid
    | GuildIncidentReportFalseAlarm
    | GuildDeadChatRevivePrompt
    | CustomGift
    | GuildGamingStatsPrompt
    | Poll
    | PurchaseNotification
    | VoiceHangoutInvite
    | PollResult
    | Changelog
    | NitroNotification
    | ChannelLinkedToLobby
    | GiftingPrompt
    | InGameMessageNux
    | GuildJoinRequestAcceptNotification
    | GuildJoinRequestRejectNotification
    | GuildJoinRequestWithdrawnNotification
    | HdStreamingUpgraded
    | ChatWallpaperSet
    | ChatWallpaperRemove
    | ReportToModDeletedMessage
    | ReportToModTimeoutUser
    | ReportToModKickUser
    | ReportToModBanUser
    | ReportToModClosedReport
    | EmojiAdded
    | UnknownMessageType


type alias MessageFlags =
    { crossposted : Bool
    , isCrosspost : Bool
    , suppressEmbeds : Bool
    , sourceMessageDeleted : Bool
    , urgent : Bool
    , hasThread : Bool
    , ephemeral : Bool
    , loading : Bool
    , failedToMentionSomeRolesInThread : Bool
    , guildFeedHidden : Bool
    , shouldShowLinkNotDiscordWarning : Bool
    , suppressNotifications : Bool
    , isVoiceMessage : Bool
    , hasSnapshot : Bool
    , isComponentsV2 : Bool
    , sentBySocialLayerIntegration : Bool
    }


type alias StickerItem =
    { id : Id StickerId
    , name : String
    , formatType : StickerFormatType
    }


type StickerPackId
    = StickerPackId Never


type StickerType
    = StandardSticker
    | GuildSticker


type alias Sticker =
    { id : Id StickerId
    , packId : OptionalData (Id StickerPackId)
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


type alias MessageSnapshot =
    { content : String
    , timestamp : Time.Posix
    , editedTimestamp : Maybe Time.Posix
    , attachments : List Attachment
    , embeds : List Embed
    , type_ : MessageType
    , flags : MessageFlags
    , stickerItems : OptionalData (List StickerItem)
    }


type alias Message =
    { id : Id MessageId
    , channelId : Id ChannelId
    , guildId : OptionalData (Id GuildId)
    , author : User
    , content : String
    , timestamp : Time.Posix
    , editedTimestamp : Maybe Time.Posix
    , textToSpeech : Bool
    , mentionEveryone : Bool
    , mentionRoles : List (Id RoleId)
    , attachments : List Attachment
    , embeds : OptionalData (List Embed)
    , reactions : OptionalData (List Reaction)
    , pinned : Bool
    , webhookId : OptionalData (Id WebhookId)
    , type_ : MessageType
    , flags : OptionalData MessageFlags
    , referencedMessage : ReferencedMessage
    , stickerItems : OptionalData (List StickerItem)
    , stickers : OptionalData (List Sticker)
    , messageSnapshots : OptionalData (List MessageSnapshot)
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


type ApplicationId
    = ApplicationId Never


type alias Channel =
    { id : Id ChannelId
    , type_ : ChannelType
    , guildId : OptionalData (Id GuildId)
    , position : OptionalData Int
    , permissionOverwrites : OptionalData (List Overwrite)
    , name : OptionalData String
    , topic : OptionalData (Maybe String)
    , nsfw : OptionalData Bool
    , lastMessageId : OptionalData (Maybe (Id MessageId))
    , bitrate : OptionalData (Quantity.Quantity Int (Quantity.Rate Bits Duration.Seconds))
    , userLimit : OptionalData Int
    , rateLimitPerUser : OptionalData (Quantity.Quantity Int Duration.Seconds)
    , recipients : OptionalData (List User)
    , icon : OptionalData (Maybe String)
    , ownerId : OptionalData (Id UserId)
    , applicationId : OptionalData (Id ApplicationId)
    , parentId : OptionalData (Maybe (Id ChannelId))
    , lastPinTimestamp : OptionalData Time.Posix
    , permissions : OptionalData Permissions
    }


type IconHash
    = IconHash Never


type alias GatewayGuildProperties =
    { nsfwLevel : Int
    , systemChannelFlags : Int
    , icon : Maybe (ImageHash IconHash)
    , maxVideoChannelUsers : Int
    , id : Id GuildId
    , systemChannelId : Maybe (Id ChannelId)
    , afkChannelId : Maybe (Id ChannelId)
    , name : String
    , maxMembers : Maybe Int
    , nsfw : Bool
    , description : Maybe String
    , preferredLocale : String
    , rulesChannelId : Maybe (Id ChannelId)
    , ownerId : Id UserId
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
    , roles : List Role
    , emojis : List EmojiData
    , premiumSubscriptionCount : Int
    }


type alias UserMessageUpdate =
    { id : Id MessageId
    , channelId : Id ChannelId
    , guildId : OptionalData (Id GuildId)
    , author : User
    , content : String
    , timestamp : Time.Posix
    , embeds : List Embed
    , attachments : List Attachment
    , flags : MessageFlags
    , stickerItems : OptionalData (List StickerItem)
    , stickers : OptionalData (List Sticker)
    , messageSnapshots : OptionalData (List MessageSnapshot)
    }


type alias StickerPack =
    { id : Id StickerPackId
    , stickers : List Sticker
    , name : String
    , description : String
    }


type SplashHash
    = SplashHash Never


type DiscoverySplashHash
    = DiscoverSplashHash Never


type alias GuildMember =
    { user : User
    , nickname : Maybe String
    , roles : List (Id RoleId)
    , joinedAt : Time.Posix
    , premiumSince : OptionalData (Maybe Time.Posix)
    , deaf : Bool
    , mute : Bool
    }


type BannerHash
    = BannerHash Never


type alias Guild =
    { id : Id GuildId
    , name : String
    , icon : Maybe (ImageHash IconHash)
    , splash : Maybe (ImageHash SplashHash)
    , discoverySplash : Maybe (ImageHash DiscoverySplashHash)
    , owner : OptionalData Bool
    , ownerId : Id UserId
    , region : String
    , afkChannelId : Maybe (Id ChannelId)
    , afkTimeout : Quantity.Quantity Int Duration.Seconds
    , embedEnabled : OptionalData Bool
    , embedChannelId : OptionalData (Maybe (Id ChannelId))
    , verificationLevel : Int
    , defaultMessageNotifications : Int
    , explicitContentFilter : Int
    , roles : List Role
    , emojis : List EmojiData
    , features : List String
    , mfaLevel : Int
    , applicationId : Maybe (Id ApplicationId)
    , widgetEnabled : OptionalData Bool
    , widgetChannelId : OptionalData (Maybe (Id ChannelId))
    , systemChannelId : Maybe (Id ChannelId)
    , systemChannelFlags : Int
    , rulesChannelId : Maybe (Id ChannelId)
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
    , publicUpdatesChannelId : Maybe (Id ChannelId)
    , approximateMemberCount : OptionalData Int
    , approximatePresenceCount : OptionalData Int
    }
