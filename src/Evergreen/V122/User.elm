module Evergreen.V122.User exposing (..)

import Effect.Time
import Evergreen.V122.Discord.Id
import Evergreen.V122.EmailAddress
import Evergreen.V122.FileStatus
import Evergreen.V122.Id
import Evergreen.V122.NonemptyDict
import Evergreen.V122.OneOrGreater
import Evergreen.V122.PersonName
import SeqDict
import SeqSet


type AdminUiSection
    = UsersSection
    | LogSection
    | DiscordDmChannelsSection
    | DiscordUsersSection
    | DiscordGuildsSection


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) Evergreen.V122.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V122.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V122.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V122.Id.AnyGuildOrDmId (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V122.Id.AnyGuildOrDmId, Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId ) (Evergreen.V122.Id.Id Evergreen.V122.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) ( Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelId, Evergreen.V122.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId) ( Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.ChannelId, Evergreen.V122.Id.ThreadRoute )
    , icon : Maybe Evergreen.V122.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) (Evergreen.V122.NonemptyDict.NonemptyDict ( Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelId, Evergreen.V122.Id.ThreadRoute ) Evergreen.V122.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId) (Evergreen.V122.NonemptyDict.NonemptyDict ( Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.ChannelId, Evergreen.V122.Id.ThreadRoute ) Evergreen.V122.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    }


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V122.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V122.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V122.PersonName.PersonName
    , icon : Maybe Evergreen.V122.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V122.PersonName.PersonName
    , icon : Maybe Evergreen.V122.FileStatus.FileHash
    , email : Maybe Evergreen.V122.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
