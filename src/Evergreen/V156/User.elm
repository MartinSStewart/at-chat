module Evergreen.V156.User exposing (..)

import Effect.Time
import Evergreen.V156.Discord
import Evergreen.V156.DiscordUserData
import Evergreen.V156.EmailAddress
import Evergreen.V156.FileStatus
import Evergreen.V156.Id
import Evergreen.V156.NonemptyDict
import Evergreen.V156.OneOrGreater
import Evergreen.V156.Pagination
import Evergreen.V156.PersonName
import Evergreen.V156.RichText
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
    = DmChannelLastViewed (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) Evergreen.V156.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V156.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V156.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V156.Id.Id Evergreen.V156.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V156.Id.AnyGuildOrDmId (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId ) (Evergreen.V156.Id.Id Evergreen.V156.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) ( Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelId, Evergreen.V156.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) ( Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId, Evergreen.V156.Id.ThreadRoute )
    , icon : Maybe Evergreen.V156.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) (Evergreen.V156.NonemptyDict.NonemptyDict ( Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelId, Evergreen.V156.Id.ThreadRoute ) Evergreen.V156.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) (Evergreen.V156.NonemptyDict.NonemptyDict ( Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId, Evergreen.V156.Id.ThreadRoute ) Evergreen.V156.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V156.RichText.Domain
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V156.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V156.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V156.PersonName.PersonName
    , icon : Maybe Evergreen.V156.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V156.PersonName.PersonName
    , icon : Maybe Evergreen.V156.FileStatus.FileHash
    , email : Maybe Evergreen.V156.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V156.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
