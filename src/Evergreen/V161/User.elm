module Evergreen.V161.User exposing (..)

import Effect.Time
import Evergreen.V161.Discord
import Evergreen.V161.DiscordUserData
import Evergreen.V161.EmailAddress
import Evergreen.V161.FileStatus
import Evergreen.V161.Id
import Evergreen.V161.NonemptyDict
import Evergreen.V161.OneOrGreater
import Evergreen.V161.Pagination
import Evergreen.V161.PersonName
import Evergreen.V161.RichText
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
    = DmChannelLastViewed (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) Evergreen.V161.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V161.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V161.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V161.Id.Id Evergreen.V161.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V161.Id.AnyGuildOrDmId (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V161.Id.AnyGuildOrDmId, Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId ) (Evergreen.V161.Id.Id Evergreen.V161.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) ( Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelId, Evergreen.V161.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) ( Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId, Evergreen.V161.Id.ThreadRoute )
    , icon : Maybe Evergreen.V161.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) (Evergreen.V161.NonemptyDict.NonemptyDict ( Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelId, Evergreen.V161.Id.ThreadRoute ) Evergreen.V161.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.NonemptyDict.NonemptyDict ( Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId, Evergreen.V161.Id.ThreadRoute ) Evergreen.V161.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V161.RichText.Domain
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V161.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V161.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V161.PersonName.PersonName
    , icon : Maybe Evergreen.V161.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V161.PersonName.PersonName
    , icon : Maybe Evergreen.V161.FileStatus.FileHash
    , email : Maybe Evergreen.V161.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V161.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
