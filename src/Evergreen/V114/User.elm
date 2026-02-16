module Evergreen.V114.User exposing (..)

import Effect.Time
import Evergreen.V114.Discord.Id
import Evergreen.V114.EmailAddress
import Evergreen.V114.FileStatus
import Evergreen.V114.Id
import Evergreen.V114.NonemptyDict
import Evergreen.V114.OneOrGreater
import Evergreen.V114.PersonName
import SeqDict
import SeqSet


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) Evergreen.V114.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V114.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V114.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V114.Id.AnyGuildOrDmId (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId ) (Evergreen.V114.Id.Id Evergreen.V114.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) ( Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelId, Evergreen.V114.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId) ( Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.ChannelId, Evergreen.V114.Id.ThreadRoute )
    , icon : Maybe Evergreen.V114.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) (Evergreen.V114.NonemptyDict.NonemptyDict ( Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelId, Evergreen.V114.Id.ThreadRoute ) Evergreen.V114.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId) (Evergreen.V114.NonemptyDict.NonemptyDict ( Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.ChannelId, Evergreen.V114.Id.ThreadRoute ) Evergreen.V114.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V114.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V114.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V114.PersonName.PersonName
    , icon : Maybe Evergreen.V114.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V114.PersonName.PersonName
    , icon : Maybe Evergreen.V114.FileStatus.FileHash
    , email : Maybe Evergreen.V114.EmailAddress.EmailAddress
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
