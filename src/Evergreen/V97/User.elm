module Evergreen.V97.User exposing (..)

import Effect.Time
import Evergreen.V97.EmailAddress
import Evergreen.V97.FileStatus
import Evergreen.V97.Id
import Evergreen.V97.NonemptyDict
import Evergreen.V97.OneOrGreater
import Evergreen.V97.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredFromSlack
    | RegisteredDirectly Evergreen.V97.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes


type alias BackendUser =
    { name : Evergreen.V97.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V97.Id.GuildOrDmIdNoThread (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V97.Id.GuildOrDmIdNoThread, Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelMessageId ) (Evergreen.V97.Id.Id Evergreen.V97.Id.ThreadMessageId)
    , lastDmViewed : Maybe ( Evergreen.V97.Id.Id Evergreen.V97.Id.UserId, Evergreen.V97.Id.ThreadRoute )
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) ( Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelId, Evergreen.V97.Id.ThreadRoute )
    , icon : Maybe Evergreen.V97.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) (Evergreen.V97.NonemptyDict.NonemptyDict ( Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelId, Evergreen.V97.Id.ThreadRoute ) Evergreen.V97.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V97.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V97.FileStatus.FileHash
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
