module Evergreen.V121.User exposing (..)

import Effect.Time
import Evergreen.V121.Discord.Id
import Evergreen.V121.EmailAddress
import Evergreen.V121.FileStatus
import Evergreen.V121.Id
import Evergreen.V121.NonemptyDict
import Evergreen.V121.OneOrGreater
import Evergreen.V121.PersonName
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
    = DmChannelLastViewed (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId) Evergreen.V121.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V121.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V121.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V121.Id.AnyGuildOrDmId (Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V121.Id.AnyGuildOrDmId, Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelMessageId ) (Evergreen.V121.Id.Id Evergreen.V121.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.GuildId) ( Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelId, Evergreen.V121.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.GuildId) ( Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.ChannelId, Evergreen.V121.Id.ThreadRoute )
    , icon : Maybe Evergreen.V121.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V121.Id.Id Evergreen.V121.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.GuildId) (Evergreen.V121.NonemptyDict.NonemptyDict ( Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelId, Evergreen.V121.Id.ThreadRoute ) Evergreen.V121.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.GuildId) (Evergreen.V121.NonemptyDict.NonemptyDict ( Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.ChannelId, Evergreen.V121.Id.ThreadRoute ) Evergreen.V121.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    }


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V121.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V121.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V121.PersonName.PersonName
    , icon : Maybe Evergreen.V121.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V121.PersonName.PersonName
    , icon : Maybe Evergreen.V121.FileStatus.FileHash
    , email : Maybe Evergreen.V121.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
