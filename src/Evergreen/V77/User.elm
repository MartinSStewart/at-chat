module Evergreen.V77.User exposing (..)

import Effect.Time
import Evergreen.V77.EmailAddress
import Evergreen.V77.FileStatus
import Evergreen.V77.Id
import Evergreen.V77.NonemptyDict
import Evergreen.V77.OneOrGreater
import Evergreen.V77.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredFromSlack
    | RegisteredDirectly Evergreen.V77.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes


type alias BackendUser =
    { name : Evergreen.V77.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V77.Id.GuildOrDmIdNoThread (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V77.Id.GuildOrDmIdNoThread, Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelMessageId ) (Evergreen.V77.Id.Id Evergreen.V77.Id.ThreadMessageId)
    , lastDmViewed : Maybe ( Evergreen.V77.Id.Id Evergreen.V77.Id.UserId, Evergreen.V77.Id.ThreadRoute )
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) ( Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelId, Evergreen.V77.Id.ThreadRoute )
    , icon : Maybe Evergreen.V77.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) (Evergreen.V77.NonemptyDict.NonemptyDict ( Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelId, Evergreen.V77.Id.ThreadRoute ) Evergreen.V77.OneOrGreater.OneOrGreater)
    }


type alias FrontendUser =
    { name : Evergreen.V77.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V77.FileStatus.FileHash
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
