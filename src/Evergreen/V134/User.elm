module Evergreen.V134.User exposing (..)

import Effect.Time
import Evergreen.V134.Discord.Id
import Evergreen.V134.EmailAddress
import Evergreen.V134.FileStatus
import Evergreen.V134.Id
import Evergreen.V134.NonemptyDict
import Evergreen.V134.OneOrGreater
import Evergreen.V134.PersonName
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
    = DmChannelLastViewed (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V134.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V134.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V134.Id.AnyGuildOrDmId (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId ) (Evergreen.V134.Id.Id Evergreen.V134.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) ( Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelId, Evergreen.V134.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) ( Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId, Evergreen.V134.Id.ThreadRoute )
    , icon : Maybe Evergreen.V134.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) (Evergreen.V134.NonemptyDict.NonemptyDict ( Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelId, Evergreen.V134.Id.ThreadRoute ) Evergreen.V134.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) (Evergreen.V134.NonemptyDict.NonemptyDict ( Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId, Evergreen.V134.Id.ThreadRoute ) Evergreen.V134.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId)
    }


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V134.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V134.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V134.PersonName.PersonName
    , icon : Maybe Evergreen.V134.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V134.PersonName.PersonName
    , icon : Maybe Evergreen.V134.FileStatus.FileHash
    , email : Maybe Evergreen.V134.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
