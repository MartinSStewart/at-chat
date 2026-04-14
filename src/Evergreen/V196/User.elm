module Evergreen.V196.User exposing (..)

import Effect.Time
import Evergreen.V196.Discord
import Evergreen.V196.DiscordUserData
import Evergreen.V196.EmailAddress
import Evergreen.V196.Emoji
import Evergreen.V196.FileStatus
import Evergreen.V196.Id
import Evergreen.V196.NonemptyDict
import Evergreen.V196.OneOrGreater
import Evergreen.V196.Pagination
import Evergreen.V196.PersonName
import Evergreen.V196.RichText
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
    | StickersSection


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId) Evergreen.V196.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V196.Discord.Id Evergreen.V196.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V196.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V196.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V196.Id.Id Evergreen.V196.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V196.Id.AnyGuildOrDmId (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V196.Id.AnyGuildOrDmId, Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelMessageId ) (Evergreen.V196.Id.Id Evergreen.V196.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.GuildId) ( Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelId, Evergreen.V196.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V196.Discord.Id Evergreen.V196.Discord.GuildId) ( Evergreen.V196.Discord.Id Evergreen.V196.Discord.ChannelId, Evergreen.V196.Id.ThreadRoute )
    , icon : Maybe Evergreen.V196.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V196.Id.Id Evergreen.V196.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V196.Discord.Id Evergreen.V196.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.GuildId) (Evergreen.V196.NonemptyDict.NonemptyDict ( Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelId, Evergreen.V196.Id.ThreadRoute ) Evergreen.V196.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V196.Discord.Id Evergreen.V196.Discord.GuildId) (Evergreen.V196.NonemptyDict.NonemptyDict ( Evergreen.V196.Discord.Id Evergreen.V196.Discord.ChannelId, Evergreen.V196.Id.ThreadRoute ) Evergreen.V196.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V196.Id.Id Evergreen.V196.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V196.Discord.Id Evergreen.V196.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V196.RichText.Domain
    , emojiConfig : Evergreen.V196.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V196.Id.Id Evergreen.V196.Id.StickerId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V196.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V196.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V196.PersonName.PersonName
    , icon : Maybe Evergreen.V196.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V196.PersonName.PersonName
    , icon : Maybe Evergreen.V196.FileStatus.FileHash
    , email : Maybe Evergreen.V196.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V196.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
