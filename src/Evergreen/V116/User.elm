module Evergreen.V116.User exposing (..)

import Effect.Time
import Evergreen.V116.Discord.Id
import Evergreen.V116.EmailAddress
import Evergreen.V116.FileStatus
import Evergreen.V116.Id
import Evergreen.V116.NonemptyDict
import Evergreen.V116.OneOrGreater
import Evergreen.V116.PersonName
import SeqDict
import SeqSet


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) Evergreen.V116.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V116.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V116.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V116.Id.AnyGuildOrDmId (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId ) (Evergreen.V116.Id.Id Evergreen.V116.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) ( Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelId, Evergreen.V116.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId) ( Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.ChannelId, Evergreen.V116.Id.ThreadRoute )
    , icon : Maybe Evergreen.V116.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) (Evergreen.V116.NonemptyDict.NonemptyDict ( Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelId, Evergreen.V116.Id.ThreadRoute ) Evergreen.V116.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId) (Evergreen.V116.NonemptyDict.NonemptyDict ( Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.ChannelId, Evergreen.V116.Id.ThreadRoute ) Evergreen.V116.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V116.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V116.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V116.PersonName.PersonName
    , icon : Maybe Evergreen.V116.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V116.PersonName.PersonName
    , icon : Maybe Evergreen.V116.FileStatus.FileHash
    , email : Maybe Evergreen.V116.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
