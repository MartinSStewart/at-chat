module Evergreen.V5.User exposing (..)

import Effect.Time
import Evergreen.V5.EmailAddress
import Evergreen.V5.Id
import Evergreen.V5.PersonName
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
    { name : Evergreen.V5.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V5.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict ( Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId, Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId ) Int
    }


type alias FrontendUser =
    { name : Evergreen.V5.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    }
