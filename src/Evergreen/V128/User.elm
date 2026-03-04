module Evergreen.V128.User exposing (..)

import Effect.Time
import Evergreen.V128.Discord.Id
import Evergreen.V128.EmailAddress
import Evergreen.V128.FileStatus
import Evergreen.V128.Id
import Evergreen.V128.NonemptyDict
import Evergreen.V128.OneOrGreater
import Evergreen.V128.PersonName
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


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) Evergreen.V128.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V128.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V128.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V128.Id.AnyGuildOrDmId (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V128.Id.AnyGuildOrDmId, Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId ) (Evergreen.V128.Id.Id Evergreen.V128.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) ( Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelId, Evergreen.V128.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) ( Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId, Evergreen.V128.Id.ThreadRoute )
    , icon : Maybe Evergreen.V128.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) (Evergreen.V128.NonemptyDict.NonemptyDict ( Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelId, Evergreen.V128.Id.ThreadRoute ) Evergreen.V128.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) (Evergreen.V128.NonemptyDict.NonemptyDict ( Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId, Evergreen.V128.Id.ThreadRoute ) Evergreen.V128.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId)
    }


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V128.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V128.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V128.PersonName.PersonName
    , icon : Maybe Evergreen.V128.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V128.PersonName.PersonName
    , icon : Maybe Evergreen.V128.FileStatus.FileHash
    , email : Maybe Evergreen.V128.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
