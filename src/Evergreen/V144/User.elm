module Evergreen.V144.User exposing (..)

import Effect.Time
import Evergreen.V144.Discord
import Evergreen.V144.EmailAddress
import Evergreen.V144.FileStatus
import Evergreen.V144.Id
import Evergreen.V144.NonemptyDict
import Evergreen.V144.OneOrGreater
import Evergreen.V144.PersonName
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
    = DmChannelLastViewed (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) Evergreen.V144.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V144.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V144.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V144.Id.AnyGuildOrDmId (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V144.Id.AnyGuildOrDmId, Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId ) (Evergreen.V144.Id.Id Evergreen.V144.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) ( Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelId, Evergreen.V144.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) ( Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId, Evergreen.V144.Id.ThreadRoute )
    , icon : Maybe Evergreen.V144.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) (Evergreen.V144.NonemptyDict.NonemptyDict ( Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelId, Evergreen.V144.Id.ThreadRoute ) Evergreen.V144.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) (Evergreen.V144.NonemptyDict.NonemptyDict ( Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId, Evergreen.V144.Id.ThreadRoute ) Evergreen.V144.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId)
    }


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V144.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V144.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V144.PersonName.PersonName
    , icon : Maybe Evergreen.V144.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V144.PersonName.PersonName
    , icon : Maybe Evergreen.V144.FileStatus.FileHash
    , email : Maybe Evergreen.V144.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
