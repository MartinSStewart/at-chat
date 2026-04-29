module Evergreen.V211.User exposing (..)

import Effect.Time
import Evergreen.V211.Discord
import Evergreen.V211.DiscordUserData
import Evergreen.V211.EmailAddress
import Evergreen.V211.Emoji
import Evergreen.V211.FileStatus
import Evergreen.V211.Id
import Evergreen.V211.NonemptyDict
import Evergreen.V211.OneOrGreater
import Evergreen.V211.Pagination
import Evergreen.V211.PersonName
import Evergreen.V211.RichText
import SeqDict
import SeqSet


type AdminUiSection
    = UsersSection
    | LogSection
    | DiscordDmChannelsSection
    | DiscordUsersSection
    | DiscordGuildsSection
    | GuildsSection
    | ApiKeysSection
    | ExportSection
    | ConnectionsSection
    | FilesSection
    | ToBackendLogsSection
    | StickersAndEmojisSection


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId) Evergreen.V211.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V211.Discord.Id Evergreen.V211.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V211.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V211.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V211.Id.Id Evergreen.V211.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V211.Id.AnyGuildOrDmId (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V211.Id.AnyGuildOrDmId, Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelMessageId ) (Evergreen.V211.Id.Id Evergreen.V211.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.GuildId) ( Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelId, Evergreen.V211.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V211.Discord.Id Evergreen.V211.Discord.GuildId) ( Evergreen.V211.Discord.Id Evergreen.V211.Discord.ChannelId, Evergreen.V211.Id.ThreadRoute )
    , icon : Maybe Evergreen.V211.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V211.Id.Id Evergreen.V211.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V211.Discord.Id Evergreen.V211.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.GuildId) (Evergreen.V211.NonemptyDict.NonemptyDict ( Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelId, Evergreen.V211.Id.ThreadRoute ) Evergreen.V211.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V211.Discord.Id Evergreen.V211.Discord.GuildId) (Evergreen.V211.NonemptyDict.NonemptyDict ( Evergreen.V211.Discord.Id Evergreen.V211.Discord.ChannelId, Evergreen.V211.Id.ThreadRoute ) Evergreen.V211.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V211.Id.Id Evergreen.V211.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V211.Discord.Id Evergreen.V211.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V211.RichText.Domain
    , emojiConfig : Evergreen.V211.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V211.Id.Id Evergreen.V211.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V211.Id.Id Evergreen.V211.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V211.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V211.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V211.PersonName.PersonName
    , icon : Maybe Evergreen.V211.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V211.PersonName.PersonName
    , icon : Maybe Evergreen.V211.FileStatus.FileHash
    , email : Maybe Evergreen.V211.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V211.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
