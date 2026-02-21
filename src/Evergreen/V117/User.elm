module Evergreen.V117.User exposing (..)

import Effect.Time
import Evergreen.V117.Discord.Id
import Evergreen.V117.EmailAddress
import Evergreen.V117.FileStatus
import Evergreen.V117.Id
import Evergreen.V117.NonemptyDict
import Evergreen.V117.OneOrGreater
import Evergreen.V117.PersonName
import SeqDict
import SeqSet


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) Evergreen.V117.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V117.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V117.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V117.Id.AnyGuildOrDmId (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId ) (Evergreen.V117.Id.Id Evergreen.V117.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) ( Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelId, Evergreen.V117.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId) ( Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.ChannelId, Evergreen.V117.Id.ThreadRoute )
    , icon : Maybe Evergreen.V117.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) (Evergreen.V117.NonemptyDict.NonemptyDict ( Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelId, Evergreen.V117.Id.ThreadRoute ) Evergreen.V117.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId) (Evergreen.V117.NonemptyDict.NonemptyDict ( Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.ChannelId, Evergreen.V117.Id.ThreadRoute ) Evergreen.V117.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V117.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V117.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V117.PersonName.PersonName
    , icon : Maybe Evergreen.V117.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V117.PersonName.PersonName
    , icon : Maybe Evergreen.V117.FileStatus.FileHash
    , email : Maybe Evergreen.V117.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
