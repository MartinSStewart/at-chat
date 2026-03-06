module Evergreen.V138.User exposing (..)

import Effect.Time
import Evergreen.V138.Discord.Id
import Evergreen.V138.EmailAddress
import Evergreen.V138.FileStatus
import Evergreen.V138.Id
import Evergreen.V138.NonemptyDict
import Evergreen.V138.OneOrGreater
import Evergreen.V138.PersonName
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
    = DmChannelLastViewed (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) Evergreen.V138.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V138.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V138.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V138.Id.AnyGuildOrDmId (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId ) (Evergreen.V138.Id.Id Evergreen.V138.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) ( Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelId, Evergreen.V138.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) ( Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId, Evergreen.V138.Id.ThreadRoute )
    , icon : Maybe Evergreen.V138.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) (Evergreen.V138.NonemptyDict.NonemptyDict ( Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelId, Evergreen.V138.Id.ThreadRoute ) Evergreen.V138.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) (Evergreen.V138.NonemptyDict.NonemptyDict ( Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId, Evergreen.V138.Id.ThreadRoute ) Evergreen.V138.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId)
    }


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V138.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V138.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V138.PersonName.PersonName
    , icon : Maybe Evergreen.V138.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V138.PersonName.PersonName
    , icon : Maybe Evergreen.V138.FileStatus.FileHash
    , email : Maybe Evergreen.V138.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
