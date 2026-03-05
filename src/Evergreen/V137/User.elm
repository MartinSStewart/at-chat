module Evergreen.V137.User exposing (..)

import Effect.Time
import Evergreen.V137.Discord.Id
import Evergreen.V137.EmailAddress
import Evergreen.V137.FileStatus
import Evergreen.V137.Id
import Evergreen.V137.NonemptyDict
import Evergreen.V137.OneOrGreater
import Evergreen.V137.PersonName
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
    = DmChannelLastViewed (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) Evergreen.V137.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V137.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V137.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V137.Id.AnyGuildOrDmId (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId ) (Evergreen.V137.Id.Id Evergreen.V137.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) ( Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelId, Evergreen.V137.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) ( Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId, Evergreen.V137.Id.ThreadRoute )
    , icon : Maybe Evergreen.V137.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) (Evergreen.V137.NonemptyDict.NonemptyDict ( Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelId, Evergreen.V137.Id.ThreadRoute ) Evergreen.V137.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) (Evergreen.V137.NonemptyDict.NonemptyDict ( Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId, Evergreen.V137.Id.ThreadRoute ) Evergreen.V137.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId)
    }


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V137.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V137.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V137.PersonName.PersonName
    , icon : Maybe Evergreen.V137.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V137.PersonName.PersonName
    , icon : Maybe Evergreen.V137.FileStatus.FileHash
    , email : Maybe Evergreen.V137.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
