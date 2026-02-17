module Evergreen.V115.User exposing (..)

import Effect.Time
import Evergreen.V115.Discord.Id
import Evergreen.V115.EmailAddress
import Evergreen.V115.FileStatus
import Evergreen.V115.Id
import Evergreen.V115.NonemptyDict
import Evergreen.V115.OneOrGreater
import Evergreen.V115.PersonName
import SeqDict
import SeqSet


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) Evergreen.V115.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V115.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V115.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V115.Id.AnyGuildOrDmId (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId ) (Evergreen.V115.Id.Id Evergreen.V115.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) ( Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelId, Evergreen.V115.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId) ( Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId, Evergreen.V115.Id.ThreadRoute )
    , icon : Maybe Evergreen.V115.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) (Evergreen.V115.NonemptyDict.NonemptyDict ( Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelId, Evergreen.V115.Id.ThreadRoute ) Evergreen.V115.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId) (Evergreen.V115.NonemptyDict.NonemptyDict ( Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId, Evergreen.V115.Id.ThreadRoute ) Evergreen.V115.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V115.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V115.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V115.PersonName.PersonName
    , icon : Maybe Evergreen.V115.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V115.PersonName.PersonName
    , icon : Maybe Evergreen.V115.FileStatus.FileHash
    , email : Maybe Evergreen.V115.EmailAddress.EmailAddress
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
