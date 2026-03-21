module Evergreen.V163.User exposing (..)

import Effect.Time
import Evergreen.V163.Discord
import Evergreen.V163.DiscordUserData
import Evergreen.V163.EmailAddress
import Evergreen.V163.FileStatus
import Evergreen.V163.Id
import Evergreen.V163.NonemptyDict
import Evergreen.V163.OneOrGreater
import Evergreen.V163.Pagination
import Evergreen.V163.PersonName
import Evergreen.V163.RichText
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


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId) Evergreen.V163.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V163.Discord.Id Evergreen.V163.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V163.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V163.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V163.Id.Id Evergreen.V163.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V163.Id.AnyGuildOrDmId (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V163.Id.AnyGuildOrDmId, Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelMessageId ) (Evergreen.V163.Id.Id Evergreen.V163.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.GuildId) ( Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelId, Evergreen.V163.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V163.Discord.Id Evergreen.V163.Discord.GuildId) ( Evergreen.V163.Discord.Id Evergreen.V163.Discord.ChannelId, Evergreen.V163.Id.ThreadRoute )
    , icon : Maybe Evergreen.V163.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V163.Id.Id Evergreen.V163.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V163.Discord.Id Evergreen.V163.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.GuildId) (Evergreen.V163.NonemptyDict.NonemptyDict ( Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelId, Evergreen.V163.Id.ThreadRoute ) Evergreen.V163.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V163.Discord.Id Evergreen.V163.Discord.GuildId) (Evergreen.V163.NonemptyDict.NonemptyDict ( Evergreen.V163.Discord.Id Evergreen.V163.Discord.ChannelId, Evergreen.V163.Id.ThreadRoute ) Evergreen.V163.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V163.Id.Id Evergreen.V163.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V163.Discord.Id Evergreen.V163.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V163.RichText.Domain
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V163.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V163.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V163.PersonName.PersonName
    , icon : Maybe Evergreen.V163.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V163.PersonName.PersonName
    , icon : Maybe Evergreen.V163.FileStatus.FileHash
    , email : Maybe Evergreen.V163.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V163.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
