module Evergreen.V146.User exposing (..)

import Effect.Time
import Evergreen.V146.Discord
import Evergreen.V146.DiscordUserData
import Evergreen.V146.EmailAddress
import Evergreen.V146.FileStatus
import Evergreen.V146.Id
import Evergreen.V146.NonemptyDict
import Evergreen.V146.OneOrGreater
import Evergreen.V146.PersonName
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
    = DmChannelLastViewed (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) Evergreen.V146.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V146.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V146.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V146.Id.AnyGuildOrDmId (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V146.Id.AnyGuildOrDmId, Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId ) (Evergreen.V146.Id.Id Evergreen.V146.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) ( Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelId, Evergreen.V146.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) ( Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId, Evergreen.V146.Id.ThreadRoute )
    , icon : Maybe Evergreen.V146.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) (Evergreen.V146.NonemptyDict.NonemptyDict ( Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelId, Evergreen.V146.Id.ThreadRoute ) Evergreen.V146.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) (Evergreen.V146.NonemptyDict.NonemptyDict ( Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId, Evergreen.V146.Id.ThreadRoute ) Evergreen.V146.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V146.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V146.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V146.PersonName.PersonName
    , icon : Maybe Evergreen.V146.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V146.PersonName.PersonName
    , icon : Maybe Evergreen.V146.FileStatus.FileHash
    , email : Maybe Evergreen.V146.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V146.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
