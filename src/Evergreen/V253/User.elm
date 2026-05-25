module Evergreen.V253.User exposing (..)

import Effect.Time
import Evergreen.V253.CustomEmoji
import Evergreen.V253.Discord
import Evergreen.V253.DiscordUserData
import Evergreen.V253.EmailAddress
import Evergreen.V253.Emoji
import Evergreen.V253.FileStatus
import Evergreen.V253.Id
import Evergreen.V253.NonemptyDict
import Evergreen.V253.OneOrGreater
import Evergreen.V253.Pagination
import Evergreen.V253.PersonName
import Evergreen.V253.RichText
import Evergreen.V253.Sticker
import Evergreen.V253.UserAgent
import Evergreen.V253.UserSession
import SeqDict
import SeqSet


type AdminUiSection
    = UsersSection
    | LogSection
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


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) Evergreen.V253.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V253.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V253.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V253.Id.Id Evergreen.V253.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V253.Id.AnyGuildOrDmId (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V253.Id.AnyGuildOrDmId, Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId ) (Evergreen.V253.Id.Id Evergreen.V253.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) ( Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelId, Evergreen.V253.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) ( Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId, Evergreen.V253.Id.ThreadRoute )
    , icon : Maybe Evergreen.V253.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) (Evergreen.V253.NonemptyDict.NonemptyDict ( Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelId, Evergreen.V253.Id.ThreadRoute ) Evergreen.V253.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.NonemptyDict.NonemptyDict ( Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId, Evergreen.V253.Id.ThreadRoute ) Evergreen.V253.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V253.RichText.Domain
    , emojiConfig : Evergreen.V253.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V253.Id.Id Evergreen.V253.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V253.Id.Id Evergreen.V253.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V253.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V253.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V253.PersonName.PersonName
    , icon : Maybe Evergreen.V253.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V253.PersonName.PersonName
    , icon : Maybe Evergreen.V253.FileStatus.FileHash
    , email : Maybe Evergreen.V253.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V253.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V253.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V253.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.StickerId) Evergreen.V253.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.CustomEmojiId) Evergreen.V253.CustomEmoji.CustomEmojiData
    }
