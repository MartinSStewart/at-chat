module Evergreen.V158.User exposing (..)

import Effect.Time
import Evergreen.V158.Discord
import Evergreen.V158.DiscordUserData
import Evergreen.V158.EmailAddress
import Evergreen.V158.FileStatus
import Evergreen.V158.Id
import Evergreen.V158.NonemptyDict
import Evergreen.V158.OneOrGreater
import Evergreen.V158.Pagination
import Evergreen.V158.PersonName
import Evergreen.V158.RichText
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
    = DmChannelLastViewed (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) Evergreen.V158.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V158.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V158.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V158.Id.Id Evergreen.V158.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V158.Id.AnyGuildOrDmId (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V158.Id.AnyGuildOrDmId, Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId ) (Evergreen.V158.Id.Id Evergreen.V158.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) ( Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelId, Evergreen.V158.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) ( Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId, Evergreen.V158.Id.ThreadRoute )
    , icon : Maybe Evergreen.V158.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) (Evergreen.V158.NonemptyDict.NonemptyDict ( Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelId, Evergreen.V158.Id.ThreadRoute ) Evergreen.V158.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.NonemptyDict.NonemptyDict ( Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId, Evergreen.V158.Id.ThreadRoute ) Evergreen.V158.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V158.RichText.Domain
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V158.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V158.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V158.PersonName.PersonName
    , icon : Maybe Evergreen.V158.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V158.PersonName.PersonName
    , icon : Maybe Evergreen.V158.FileStatus.FileHash
    , email : Maybe Evergreen.V158.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V158.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
