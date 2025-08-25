module Evergreen.V33.User exposing (..)

import Effect.Time
import Evergreen.V33.EmailAddress
import Evergreen.V33.FileStatus
import Evergreen.V33.Id
import Evergreen.V33.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredDirectly Evergreen.V33.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes


type alias BackendUser =
    { name : Evergreen.V33.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V33.Id.GuildOrDmId Int
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId) (Evergreen.V33.Id.Id Evergreen.V33.Id.ChannelId)
    , icon : Maybe Evergreen.V33.FileStatus.FileHash
    }


type alias FrontendUser =
    { name : Evergreen.V33.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V33.FileStatus.FileHash
    }
