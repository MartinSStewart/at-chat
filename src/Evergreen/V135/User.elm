module Evergreen.V135.User exposing (..)

import Effect.Time
import Evergreen.V135.Discord.Id
import Evergreen.V135.EmailAddress
import Evergreen.V135.FileStatus
import Evergreen.V135.Id
import Evergreen.V135.NonemptyDict
import Evergreen.V135.OneOrGreater
import Evergreen.V135.PersonName
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
    = DmChannelLastViewed (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) Evergreen.V135.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V135.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V135.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V135.Id.AnyGuildOrDmId (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId ) (Evergreen.V135.Id.Id Evergreen.V135.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) ( Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelId, Evergreen.V135.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) ( Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId, Evergreen.V135.Id.ThreadRoute )
    , icon : Maybe Evergreen.V135.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) (Evergreen.V135.NonemptyDict.NonemptyDict ( Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelId, Evergreen.V135.Id.ThreadRoute ) Evergreen.V135.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) (Evergreen.V135.NonemptyDict.NonemptyDict ( Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId, Evergreen.V135.Id.ThreadRoute ) Evergreen.V135.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId)
    }


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V135.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V135.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V135.PersonName.PersonName
    , icon : Maybe Evergreen.V135.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V135.PersonName.PersonName
    , icon : Maybe Evergreen.V135.FileStatus.FileHash
    , email : Maybe Evergreen.V135.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
