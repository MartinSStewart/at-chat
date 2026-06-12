module Evergreen.V285.User exposing (..)

import Effect.Time
import Evergreen.V285.CustomEmoji
import Evergreen.V285.Discord
import Evergreen.V285.DiscordUserData
import Evergreen.V285.EmailAddress
import Evergreen.V285.Emoji
import Evergreen.V285.FileStatus
import Evergreen.V285.Id
import Evergreen.V285.NonemptyDict
import Evergreen.V285.OneOrGreater
import Evergreen.V285.Pagination
import Evergreen.V285.PersonName
import Evergreen.V285.RichText
import Evergreen.V285.Sticker
import Evergreen.V285.UserAgent
import Evergreen.V285.UserSession
import SeqDict
import SeqSet


type AdminUiSection
    = UsersSection
    | LogSection
    | DmChannelsSection
    | DiscordDmChannelsSection
    | DiscordUsersSection
    | DiscordGuildsSection
    | GuildsSection
    | DeletedGuildsSection
    | ApiKeysSection
    | ExportSection
    | ConnectionsSection
    | FilesSection
    | ToBackendLogsSection
    | StickersAndEmojisSection
    | VoiceChatSection
    | WebsocketCloseEventsSection
    | SessionsSection


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) Evergreen.V285.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V285.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V285.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V285.Id.Id Evergreen.V285.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V285.Id.AnyGuildOrDmId (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V285.Id.AnyGuildOrDmId, Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId ) (Evergreen.V285.Id.Id Evergreen.V285.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) ( Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelId, Evergreen.V285.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) ( Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId, Evergreen.V285.Id.ThreadRoute )
    , icon : Maybe Evergreen.V285.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) (Evergreen.V285.NonemptyDict.NonemptyDict ( Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelId, Evergreen.V285.Id.ThreadRoute ) Evergreen.V285.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.NonemptyDict.NonemptyDict ( Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId, Evergreen.V285.Id.ThreadRoute ) Evergreen.V285.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V285.RichText.Domain
    , emojiConfig : Evergreen.V285.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V285.Id.Id Evergreen.V285.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V285.Id.Id Evergreen.V285.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V285.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V285.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V285.PersonName.PersonName
    , icon : Maybe Evergreen.V285.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V285.PersonName.PersonName
    , icon : Maybe Evergreen.V285.FileStatus.FileHash
    , email : Maybe Evergreen.V285.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V285.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V285.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V285.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.StickerId) Evergreen.V285.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.CustomEmojiId) Evergreen.V285.CustomEmoji.CustomEmojiData
    }
