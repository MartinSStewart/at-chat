module Evergreen.V38.User exposing (..)

import Effect.Time
import Evergreen.V38.EmailAddress
import Evergreen.V38.FileStatus
import Evergreen.V38.Id
import Evergreen.V38.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredDirectly Evergreen.V38.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes


type alias BackendUser =
    { name : Evergreen.V38.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V38.Id.GuildOrDmIdNoThread (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V38.Id.GuildOrDmIdNoThread, Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId ) (Evergreen.V38.Id.Id Evergreen.V38.Id.ThreadMessageId)
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId) (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelId)
    , icon : Maybe Evergreen.V38.FileStatus.FileHash
    }


type alias FrontendUser =
    { name : Evergreen.V38.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V38.FileStatus.FileHash
    }
