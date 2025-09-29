module Evergreen.V109.User exposing (..)

import Effect.Time
import Evergreen.V109.EmailAddress
import Evergreen.V109.FileStatus
import Evergreen.V109.Id
import Evergreen.V109.NonemptyDict
import Evergreen.V109.OneOrGreater
import Evergreen.V109.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredFromSlack
    | RegisteredDirectly Evergreen.V109.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes


type alias BackendUser =
    { name : Evergreen.V109.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V109.Id.GuildOrDmIdNoThread (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V109.Id.GuildOrDmIdNoThread, Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelMessageId ) (Evergreen.V109.Id.Id Evergreen.V109.Id.ThreadMessageId)
    , lastDmViewed : Maybe ( Evergreen.V109.Id.Id Evergreen.V109.Id.UserId, Evergreen.V109.Id.ThreadRoute )
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) ( Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelId, Evergreen.V109.Id.ThreadRoute )
    , icon : Maybe Evergreen.V109.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) (Evergreen.V109.NonemptyDict.NonemptyDict ( Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelId, Evergreen.V109.Id.ThreadRoute ) Evergreen.V109.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V109.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V109.FileStatus.FileHash
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
