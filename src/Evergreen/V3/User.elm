module Evergreen.V3.User exposing (..)

import Effect.Time
import Evergreen.V3.EmailAddress
import Evergreen.V3.Id
import Evergreen.V3.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredDirectly Evergreen.V3.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes
    | CheckEveryHour
    | NeverNotifyMe


type alias BackendUser =
    { name : Evergreen.V3.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict ( Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId, Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId ) Int
    }


type alias FrontendUser =
    { name : Evergreen.V3.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    }
