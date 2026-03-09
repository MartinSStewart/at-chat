module Evergreen.V148.User exposing (..)

import Effect.Time
import Evergreen.V148.Discord
import Evergreen.V148.DiscordUserData
import Evergreen.V148.EmailAddress
import Evergreen.V148.FileStatus
import Evergreen.V148.Id
import Evergreen.V148.NonemptyDict
import Evergreen.V148.OneOrGreater
import Evergreen.V148.Pagination
import Evergreen.V148.PersonName
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
    = DmChannelLastViewed (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) Evergreen.V148.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V148.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V148.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V148.Id.Id Evergreen.V148.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V148.Id.AnyGuildOrDmId (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V148.Id.AnyGuildOrDmId, Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId ) (Evergreen.V148.Id.Id Evergreen.V148.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) ( Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelId, Evergreen.V148.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) ( Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId, Evergreen.V148.Id.ThreadRoute )
    , icon : Maybe Evergreen.V148.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) (Evergreen.V148.NonemptyDict.NonemptyDict ( Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelId, Evergreen.V148.Id.ThreadRoute ) Evergreen.V148.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) (Evergreen.V148.NonemptyDict.NonemptyDict ( Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId, Evergreen.V148.Id.ThreadRoute ) Evergreen.V148.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V148.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V148.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V148.PersonName.PersonName
    , icon : Maybe Evergreen.V148.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V148.PersonName.PersonName
    , icon : Maybe Evergreen.V148.FileStatus.FileHash
    , email : Maybe Evergreen.V148.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V148.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
