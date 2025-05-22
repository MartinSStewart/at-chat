module Evergreen.V4.User exposing (..)

import Effect.Time
import Evergreen.V4.EmailAddress
import Evergreen.V4.Id
import Evergreen.V4.PersonName
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
    { name : Evergreen.V4.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V4.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict ( Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId, Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId ) Int
    }


type alias FrontendUser =
    { name : Evergreen.V4.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    }
