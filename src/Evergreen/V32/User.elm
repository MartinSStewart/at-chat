module Evergreen.V32.User exposing (..)

import Effect.Time
import Evergreen.V32.EmailAddress
import Evergreen.V32.Id
import Evergreen.V32.PersonName
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
    { name : Evergreen.V32.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V32.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict ( Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId, Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId ) Int
    }


type alias FrontendUser =
    { name : Evergreen.V32.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    }
