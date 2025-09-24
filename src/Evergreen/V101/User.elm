module Evergreen.V101.User exposing (..)

import Effect.Time
import Evergreen.V101.EmailAddress
import Evergreen.V101.FileStatus
import Evergreen.V101.Id
import Evergreen.V101.NonemptyDict
import Evergreen.V101.OneOrGreater
import Evergreen.V101.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredFromSlack
    | RegisteredDirectly Evergreen.V101.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes


type alias BackendUser =
    { name : Evergreen.V101.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V101.Id.GuildOrDmIdNoThread (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V101.Id.GuildOrDmIdNoThread, Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelMessageId ) (Evergreen.V101.Id.Id Evergreen.V101.Id.ThreadMessageId)
    , lastDmViewed : Maybe ( Evergreen.V101.Id.Id Evergreen.V101.Id.UserId, Evergreen.V101.Id.ThreadRoute )
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) ( Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelId, Evergreen.V101.Id.ThreadRoute )
    , icon : Maybe Evergreen.V101.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) (Evergreen.V101.NonemptyDict.NonemptyDict ( Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelId, Evergreen.V101.Id.ThreadRoute ) Evergreen.V101.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V101.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V101.FileStatus.FileHash
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
