module Evergreen.V12.User exposing (..)

import Effect.Time
import Evergreen.V12.EmailAddress
import Evergreen.V12.Id
import Evergreen.V12.PersonName
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
    { name : Evergreen.V12.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V12.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict ( Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId, Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId ) Int
    }


type alias FrontendUser =
    { name : Evergreen.V12.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    }
