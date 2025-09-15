module Evergreen.V60.User exposing (..)

import Effect.Time
import Evergreen.V60.EmailAddress
import Evergreen.V60.FileStatus
import Evergreen.V60.Id
import Evergreen.V60.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredFromSlack
    | RegisteredDirectly Evergreen.V60.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes


type alias BackendUser =
    { name : Evergreen.V60.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V60.Id.GuildOrDmIdNoThread (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V60.Id.GuildOrDmIdNoThread, Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelMessageId ) (Evergreen.V60.Id.Id Evergreen.V60.Id.ThreadMessageId)
    , lastDmViewed : Maybe ( Evergreen.V60.Id.Id Evergreen.V60.Id.UserId, Evergreen.V60.Id.ThreadRoute )
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) ( Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelId, Evergreen.V60.Id.ThreadRoute )
    , icon : Maybe Evergreen.V60.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId)
    }


type alias FrontendUser =
    { name : Evergreen.V60.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V60.FileStatus.FileHash
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
