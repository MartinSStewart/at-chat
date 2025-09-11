module Evergreen.V54.User exposing (..)

import Effect.Time
import Evergreen.V54.EmailAddress
import Evergreen.V54.FileStatus
import Evergreen.V54.Id
import Evergreen.V54.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredFromSlack
    | RegisteredDirectly Evergreen.V54.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes


type alias BackendUser =
    { name : Evergreen.V54.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V54.Id.GuildOrDmIdNoThread (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V54.Id.GuildOrDmIdNoThread, Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelMessageId ) (Evergreen.V54.Id.Id Evergreen.V54.Id.ThreadMessageId)
    , lastDmViewed : Maybe ( Evergreen.V54.Id.Id Evergreen.V54.Id.UserId, Evergreen.V54.Id.ThreadRoute )
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) ( Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelId, Evergreen.V54.Id.ThreadRoute )
    , icon : Maybe Evergreen.V54.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId)
    }


type alias FrontendUser =
    { name : Evergreen.V54.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V54.FileStatus.FileHash
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
