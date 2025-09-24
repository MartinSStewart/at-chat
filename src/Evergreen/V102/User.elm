module Evergreen.V102.User exposing (..)

import Effect.Time
import Evergreen.V102.EmailAddress
import Evergreen.V102.FileStatus
import Evergreen.V102.Id
import Evergreen.V102.NonemptyDict
import Evergreen.V102.OneOrGreater
import Evergreen.V102.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredFromSlack
    | RegisteredDirectly Evergreen.V102.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes


type alias BackendUser =
    { name : Evergreen.V102.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V102.Id.GuildOrDmIdNoThread (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V102.Id.GuildOrDmIdNoThread, Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelMessageId ) (Evergreen.V102.Id.Id Evergreen.V102.Id.ThreadMessageId)
    , lastDmViewed : Maybe ( Evergreen.V102.Id.Id Evergreen.V102.Id.UserId, Evergreen.V102.Id.ThreadRoute )
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) ( Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelId, Evergreen.V102.Id.ThreadRoute )
    , icon : Maybe Evergreen.V102.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) (Evergreen.V102.NonemptyDict.NonemptyDict ( Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelId, Evergreen.V102.Id.ThreadRoute ) Evergreen.V102.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V102.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V102.FileStatus.FileHash
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
