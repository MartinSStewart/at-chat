module Evergreen.V187.User exposing (..)

import Effect.Time
import Evergreen.V187.Discord
import Evergreen.V187.DiscordUserData
import Evergreen.V187.EmailAddress
import Evergreen.V187.Emoji
import Evergreen.V187.FileStatus
import Evergreen.V187.Id
import Evergreen.V187.NonemptyDict
import Evergreen.V187.OneOrGreater
import Evergreen.V187.Pagination
import Evergreen.V187.PersonName
import Evergreen.V187.RichText
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


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) Evergreen.V187.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V187.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V187.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V187.Id.Id Evergreen.V187.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V187.Id.AnyGuildOrDmId (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V187.Id.AnyGuildOrDmId, Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId ) (Evergreen.V187.Id.Id Evergreen.V187.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) ( Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelId, Evergreen.V187.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) ( Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId, Evergreen.V187.Id.ThreadRoute )
    , icon : Maybe Evergreen.V187.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) (Evergreen.V187.NonemptyDict.NonemptyDict ( Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelId, Evergreen.V187.Id.ThreadRoute ) Evergreen.V187.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.NonemptyDict.NonemptyDict ( Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId, Evergreen.V187.Id.ThreadRoute ) Evergreen.V187.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V187.RichText.Domain
    , emojiConfig : Evergreen.V187.Emoji.EmojiConfig
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V187.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V187.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V187.PersonName.PersonName
    , icon : Maybe Evergreen.V187.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V187.PersonName.PersonName
    , icon : Maybe Evergreen.V187.FileStatus.FileHash
    , email : Maybe Evergreen.V187.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V187.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
