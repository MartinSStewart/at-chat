module Evergreen.V27.User exposing (..)

import Effect.Time
import Evergreen.V27.EmailAddress
import Evergreen.V27.Id
import Evergreen.V27.PersonName
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
    { name : Evergreen.V27.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V27.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict ( Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId, Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId ) Int
    }


type alias FrontendUser =
    { name : Evergreen.V27.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    }
