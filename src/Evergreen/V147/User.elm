module Evergreen.V147.User exposing (..)

import Effect.Time
import Evergreen.V147.Discord
import Evergreen.V147.DiscordUserData
import Evergreen.V147.EmailAddress
import Evergreen.V147.FileStatus
import Evergreen.V147.Id
import Evergreen.V147.NonemptyDict
import Evergreen.V147.OneOrGreater
import Evergreen.V147.Pagination
import Evergreen.V147.PersonName
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


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) Evergreen.V147.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V147.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V147.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V147.Id.Id Evergreen.V147.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V147.Id.AnyGuildOrDmId (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V147.Id.AnyGuildOrDmId, Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId ) (Evergreen.V147.Id.Id Evergreen.V147.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) ( Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelId, Evergreen.V147.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) ( Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId, Evergreen.V147.Id.ThreadRoute )
    , icon : Maybe Evergreen.V147.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) (Evergreen.V147.NonemptyDict.NonemptyDict ( Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelId, Evergreen.V147.Id.ThreadRoute ) Evergreen.V147.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) (Evergreen.V147.NonemptyDict.NonemptyDict ( Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId, Evergreen.V147.Id.ThreadRoute ) Evergreen.V147.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V147.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V147.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V147.PersonName.PersonName
    , icon : Maybe Evergreen.V147.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V147.PersonName.PersonName
    , icon : Maybe Evergreen.V147.FileStatus.FileHash
    , email : Maybe Evergreen.V147.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V147.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
