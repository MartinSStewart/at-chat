module Evergreen.V45.User exposing (..)

import Effect.Time
import Evergreen.V45.EmailAddress
import Evergreen.V45.FileStatus
import Evergreen.V45.Id
import Evergreen.V45.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredDirectly Evergreen.V45.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes


type alias BackendUser =
    { name : Evergreen.V45.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V45.Id.GuildOrDmIdNoThread (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V45.Id.GuildOrDmIdNoThread, Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId ) (Evergreen.V45.Id.Id Evergreen.V45.Id.ThreadMessageId)
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId) (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelId)
    , icon : Maybe Evergreen.V45.FileStatus.FileHash
    }


type alias FrontendUser =
    { name : Evergreen.V45.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V45.FileStatus.FileHash
    }
