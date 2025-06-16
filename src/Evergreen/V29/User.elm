module Evergreen.V29.User exposing (..)

import Effect.Time
import Evergreen.V29.EmailAddress
import Evergreen.V29.Id
import Evergreen.V29.PersonName
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
    { name : Evergreen.V29.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V29.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict ( Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId, Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId ) Int
    }


type alias FrontendUser =
    { name : Evergreen.V29.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    }
