module Evergreen.V162.User exposing (..)

import Effect.Time
import Evergreen.V162.Discord
import Evergreen.V162.DiscordUserData
import Evergreen.V162.EmailAddress
import Evergreen.V162.FileStatus
import Evergreen.V162.Id
import Evergreen.V162.NonemptyDict
import Evergreen.V162.OneOrGreater
import Evergreen.V162.Pagination
import Evergreen.V162.PersonName
import Evergreen.V162.RichText
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
    = DmChannelLastViewed (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId) Evergreen.V162.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V162.Discord.Id Evergreen.V162.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V162.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V162.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V162.Id.Id Evergreen.V162.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V162.Id.AnyGuildOrDmId (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V162.Id.AnyGuildOrDmId, Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelMessageId ) (Evergreen.V162.Id.Id Evergreen.V162.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.GuildId) ( Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelId, Evergreen.V162.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V162.Discord.Id Evergreen.V162.Discord.GuildId) ( Evergreen.V162.Discord.Id Evergreen.V162.Discord.ChannelId, Evergreen.V162.Id.ThreadRoute )
    , icon : Maybe Evergreen.V162.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V162.Id.Id Evergreen.V162.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V162.Discord.Id Evergreen.V162.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.GuildId) (Evergreen.V162.NonemptyDict.NonemptyDict ( Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelId, Evergreen.V162.Id.ThreadRoute ) Evergreen.V162.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V162.Discord.Id Evergreen.V162.Discord.GuildId) (Evergreen.V162.NonemptyDict.NonemptyDict ( Evergreen.V162.Discord.Id Evergreen.V162.Discord.ChannelId, Evergreen.V162.Id.ThreadRoute ) Evergreen.V162.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V162.Id.Id Evergreen.V162.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V162.Discord.Id Evergreen.V162.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V162.RichText.Domain
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V162.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V162.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V162.PersonName.PersonName
    , icon : Maybe Evergreen.V162.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V162.PersonName.PersonName
    , icon : Maybe Evergreen.V162.FileStatus.FileHash
    , email : Maybe Evergreen.V162.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V162.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
