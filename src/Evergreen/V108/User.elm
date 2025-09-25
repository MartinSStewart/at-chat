module Evergreen.V108.User exposing (..)

import Effect.Time
import Evergreen.V108.EmailAddress
import Evergreen.V108.FileStatus
import Evergreen.V108.Id
import Evergreen.V108.NonemptyDict
import Evergreen.V108.OneOrGreater
import Evergreen.V108.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredFromSlack
    | RegisteredDirectly Evergreen.V108.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes


type alias BackendUser =
    { name : Evergreen.V108.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V108.Id.GuildOrDmIdNoThread (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V108.Id.GuildOrDmIdNoThread, Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelMessageId ) (Evergreen.V108.Id.Id Evergreen.V108.Id.ThreadMessageId)
    , lastDmViewed : Maybe ( Evergreen.V108.Id.Id Evergreen.V108.Id.UserId, Evergreen.V108.Id.ThreadRoute )
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) ( Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelId, Evergreen.V108.Id.ThreadRoute )
    , icon : Maybe Evergreen.V108.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) (Evergreen.V108.NonemptyDict.NonemptyDict ( Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelId, Evergreen.V108.Id.ThreadRoute ) Evergreen.V108.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    }


type alias FrontendUser =
    { name : Evergreen.V108.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V108.FileStatus.FileHash
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
