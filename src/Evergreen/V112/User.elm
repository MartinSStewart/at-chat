module Evergreen.V112.User exposing (..)

import Effect.Time
import Evergreen.V112.Discord.Id
import Evergreen.V112.EmailAddress
import Evergreen.V112.FileStatus
import Evergreen.V112.Id
import Evergreen.V112.NonemptyDict
import Evergreen.V112.OneOrGreater
import Evergreen.V112.PersonName
import SeqDict
import SeqSet


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) Evergreen.V112.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V112.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V112.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V112.Id.AnyGuildOrDmId (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId ) (Evergreen.V112.Id.Id Evergreen.V112.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) ( Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelId, Evergreen.V112.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId) ( Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.ChannelId, Evergreen.V112.Id.ThreadRoute )
    , icon : Maybe Evergreen.V112.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) (Evergreen.V112.NonemptyDict.NonemptyDict ( Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelId, Evergreen.V112.Id.ThreadRoute ) Evergreen.V112.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId) (Evergreen.V112.NonemptyDict.NonemptyDict ( Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.ChannelId, Evergreen.V112.Id.ThreadRoute ) Evergreen.V112.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V112.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V112.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V112.PersonName.PersonName
    , icon : Maybe Evergreen.V112.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V112.PersonName.PersonName
    , icon : Maybe Evergreen.V112.FileStatus.FileHash
    , email : Maybe Evergreen.V112.EmailAddress.EmailAddress
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
