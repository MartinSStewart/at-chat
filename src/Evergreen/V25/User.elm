module Evergreen.V25.User exposing (..)

import Effect.Time
import Evergreen.V25.EmailAddress
import Evergreen.V25.Id
import Evergreen.V25.PersonName
import SeqDict
import SeqSet


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes
    | CheckEveryHour
    | NeverNotifyMe


type alias BackendUser =
    { name : Evergreen.V25.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V25.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict ( Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId, Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId ) Int
    }


type alias FrontendUser =
    { name : Evergreen.V25.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    }
