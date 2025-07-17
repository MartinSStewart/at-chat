module Evergreen.V1.User exposing (..)

import Effect.Time
import Evergreen.V1.EmailAddress
import Evergreen.V1.Id
import Evergreen.V1.PersonName
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
    { name : Evergreen.V1.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V1.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict ( Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId, Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId ) Int
    }


type alias FrontendUser =
    { name : Evergreen.V1.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    }
