module Evergreen.V130.User exposing (..)

import Effect.Time
import Evergreen.V130.Discord.Id
import Evergreen.V130.EmailAddress
import Evergreen.V130.FileStatus
import Evergreen.V130.Id
import Evergreen.V130.NonemptyDict
import Evergreen.V130.OneOrGreater
import Evergreen.V130.PersonName
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
    = DmChannelLastViewed (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) Evergreen.V130.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V130.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V130.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V130.Id.AnyGuildOrDmId (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V130.Id.AnyGuildOrDmId, Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId ) (Evergreen.V130.Id.Id Evergreen.V130.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) ( Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelId, Evergreen.V130.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) ( Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId, Evergreen.V130.Id.ThreadRoute )
    , icon : Maybe Evergreen.V130.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) (Evergreen.V130.NonemptyDict.NonemptyDict ( Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelId, Evergreen.V130.Id.ThreadRoute ) Evergreen.V130.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) (Evergreen.V130.NonemptyDict.NonemptyDict ( Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId, Evergreen.V130.Id.ThreadRoute ) Evergreen.V130.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId)
    }


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V130.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V130.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V130.PersonName.PersonName
    , icon : Maybe Evergreen.V130.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V130.PersonName.PersonName
    , icon : Maybe Evergreen.V130.FileStatus.FileHash
    , email : Maybe Evergreen.V130.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
