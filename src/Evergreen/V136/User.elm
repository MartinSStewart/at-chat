module Evergreen.V136.User exposing (..)

import Effect.Time
import Evergreen.V136.Discord.Id
import Evergreen.V136.EmailAddress
import Evergreen.V136.FileStatus
import Evergreen.V136.Id
import Evergreen.V136.NonemptyDict
import Evergreen.V136.OneOrGreater
import Evergreen.V136.PersonName
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
    = DmChannelLastViewed (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) Evergreen.V136.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V136.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V136.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V136.Id.AnyGuildOrDmId (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId ) (Evergreen.V136.Id.Id Evergreen.V136.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) ( Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelId, Evergreen.V136.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) ( Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId, Evergreen.V136.Id.ThreadRoute )
    , icon : Maybe Evergreen.V136.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) (Evergreen.V136.NonemptyDict.NonemptyDict ( Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelId, Evergreen.V136.Id.ThreadRoute ) Evergreen.V136.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) (Evergreen.V136.NonemptyDict.NonemptyDict ( Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId, Evergreen.V136.Id.ThreadRoute ) Evergreen.V136.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId)
    }


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V136.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V136.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V136.PersonName.PersonName
    , icon : Maybe Evergreen.V136.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V136.PersonName.PersonName
    , icon : Maybe Evergreen.V136.FileStatus.FileHash
    , email : Maybe Evergreen.V136.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
