module Evergreen.V24.User exposing (..)

import Effect.Time
import Evergreen.V24.EmailAddress
import Evergreen.V24.Id
import Evergreen.V24.PersonName
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
    { name : Evergreen.V24.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V24.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict ( Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId, Evergreen.V24.Id.Id Evergreen.V24.Id.ChannelId ) Int
    }


type alias FrontendUser =
    { name : Evergreen.V24.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    }
