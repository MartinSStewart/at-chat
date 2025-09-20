module Evergreen.V92.User exposing (..)

import Effect.Time
import Evergreen.V92.EmailAddress
import Evergreen.V92.FileStatus
import Evergreen.V92.Id
import Evergreen.V92.NonemptyDict
import Evergreen.V92.OneOrGreater
import Evergreen.V92.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredFromSlack
    | RegisteredDirectly Evergreen.V92.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes


type alias BackendUser =
    { name : Evergreen.V92.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V92.Id.GuildOrDmIdNoThread (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V92.Id.GuildOrDmIdNoThread, Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelMessageId ) (Evergreen.V92.Id.Id Evergreen.V92.Id.ThreadMessageId)
    , lastDmViewed : Maybe ( Evergreen.V92.Id.Id Evergreen.V92.Id.UserId, Evergreen.V92.Id.ThreadRoute )
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) ( Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelId, Evergreen.V92.Id.ThreadRoute )
    , icon : Maybe Evergreen.V92.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) (Evergreen.V92.NonemptyDict.NonemptyDict ( Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelId, Evergreen.V92.Id.ThreadRoute ) Evergreen.V92.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V92.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V92.FileStatus.FileHash
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
