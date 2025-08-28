module Evergreen.V39.User exposing (..)

import Effect.Time
import Evergreen.V39.EmailAddress
import Evergreen.V39.FileStatus
import Evergreen.V39.Id
import Evergreen.V39.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredDirectly Evergreen.V39.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes


type alias BackendUser =
    { name : Evergreen.V39.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V39.Id.GuildOrDmIdNoThread (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V39.Id.GuildOrDmIdNoThread, Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId ) (Evergreen.V39.Id.Id Evergreen.V39.Id.ThreadMessageId)
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId) (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelId)
    , icon : Maybe Evergreen.V39.FileStatus.FileHash
    }


type alias FrontendUser =
    { name : Evergreen.V39.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V39.FileStatus.FileHash
    }
