module Evergreen.V52.User exposing (..)

import Effect.Time
import Evergreen.V52.EmailAddress
import Evergreen.V52.FileStatus
import Evergreen.V52.Id
import Evergreen.V52.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredFromSlack
    | RegisteredDirectly Evergreen.V52.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes


type alias BackendUser =
    { name : Evergreen.V52.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V52.Id.GuildOrDmIdNoThread (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V52.Id.GuildOrDmIdNoThread, Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelMessageId ) (Evergreen.V52.Id.Id Evergreen.V52.Id.ThreadMessageId)
    , lastDmViewed : Maybe ( Evergreen.V52.Id.Id Evergreen.V52.Id.UserId, Evergreen.V52.Id.ThreadRoute )
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId) ( Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelId, Evergreen.V52.Id.ThreadRoute )
    , icon : Maybe Evergreen.V52.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId)
    }


type alias FrontendUser =
    { name : Evergreen.V52.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V52.FileStatus.FileHash
    }
