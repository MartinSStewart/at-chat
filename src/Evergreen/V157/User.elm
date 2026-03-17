module Evergreen.V157.User exposing (..)

import Effect.Time
import Evergreen.V157.Discord
import Evergreen.V157.DiscordUserData
import Evergreen.V157.EmailAddress
import Evergreen.V157.FileStatus
import Evergreen.V157.Id
import Evergreen.V157.NonemptyDict
import Evergreen.V157.OneOrGreater
import Evergreen.V157.Pagination
import Evergreen.V157.PersonName
import Evergreen.V157.RichText
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
    = DmChannelLastViewed (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) Evergreen.V157.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V157.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V157.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V157.Id.Id Evergreen.V157.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V157.Id.AnyGuildOrDmId (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V157.Id.AnyGuildOrDmId, Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId ) (Evergreen.V157.Id.Id Evergreen.V157.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) ( Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelId, Evergreen.V157.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) ( Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId, Evergreen.V157.Id.ThreadRoute )
    , icon : Maybe Evergreen.V157.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) (Evergreen.V157.NonemptyDict.NonemptyDict ( Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelId, Evergreen.V157.Id.ThreadRoute ) Evergreen.V157.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.NonemptyDict.NonemptyDict ( Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId, Evergreen.V157.Id.ThreadRoute ) Evergreen.V157.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V157.RichText.Domain
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V157.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V157.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V157.PersonName.PersonName
    , icon : Maybe Evergreen.V157.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V157.PersonName.PersonName
    , icon : Maybe Evergreen.V157.FileStatus.FileHash
    , email : Maybe Evergreen.V157.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V157.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
