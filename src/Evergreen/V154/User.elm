module Evergreen.V154.User exposing (..)

import Effect.Time
import Evergreen.V154.Discord
import Evergreen.V154.DiscordUserData
import Evergreen.V154.EmailAddress
import Evergreen.V154.FileStatus
import Evergreen.V154.Id
import Evergreen.V154.NonemptyDict
import Evergreen.V154.OneOrGreater
import Evergreen.V154.Pagination
import Evergreen.V154.PersonName
import Evergreen.V154.RichText
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
    = DmChannelLastViewed (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) Evergreen.V154.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V154.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V154.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V154.Id.Id Evergreen.V154.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V154.Id.AnyGuildOrDmId (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId ) (Evergreen.V154.Id.Id Evergreen.V154.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) ( Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelId, Evergreen.V154.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) ( Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId, Evergreen.V154.Id.ThreadRoute )
    , icon : Maybe Evergreen.V154.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) (Evergreen.V154.NonemptyDict.NonemptyDict ( Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelId, Evergreen.V154.Id.ThreadRoute ) Evergreen.V154.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) (Evergreen.V154.NonemptyDict.NonemptyDict ( Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId, Evergreen.V154.Id.ThreadRoute ) Evergreen.V154.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V154.RichText.Domain
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V154.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V154.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V154.PersonName.PersonName
    , icon : Maybe Evergreen.V154.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V154.PersonName.PersonName
    , icon : Maybe Evergreen.V154.FileStatus.FileHash
    , email : Maybe Evergreen.V154.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V154.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
