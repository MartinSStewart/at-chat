module Evergreen.V149.User exposing (..)

import Effect.Time
import Evergreen.V149.Discord
import Evergreen.V149.DiscordUserData
import Evergreen.V149.EmailAddress
import Evergreen.V149.FileStatus
import Evergreen.V149.Id
import Evergreen.V149.NonemptyDict
import Evergreen.V149.OneOrGreater
import Evergreen.V149.Pagination
import Evergreen.V149.PersonName
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
    = DmChannelLastViewed (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) Evergreen.V149.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V149.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V149.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V149.Id.Id Evergreen.V149.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V149.Id.AnyGuildOrDmId (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V149.Id.AnyGuildOrDmId, Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId ) (Evergreen.V149.Id.Id Evergreen.V149.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) ( Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelId, Evergreen.V149.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) ( Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId, Evergreen.V149.Id.ThreadRoute )
    , icon : Maybe Evergreen.V149.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) (Evergreen.V149.NonemptyDict.NonemptyDict ( Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelId, Evergreen.V149.Id.ThreadRoute ) Evergreen.V149.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) (Evergreen.V149.NonemptyDict.NonemptyDict ( Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId, Evergreen.V149.Id.ThreadRoute ) Evergreen.V149.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V149.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V149.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V149.PersonName.PersonName
    , icon : Maybe Evergreen.V149.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V149.PersonName.PersonName
    , icon : Maybe Evergreen.V149.FileStatus.FileHash
    , email : Maybe Evergreen.V149.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V149.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
