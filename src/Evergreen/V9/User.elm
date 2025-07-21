module Evergreen.V9.User exposing (..)

import Effect.Time
import Evergreen.V9.EmailAddress
import Evergreen.V9.Id
import Evergreen.V9.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredDirectly Evergreen.V9.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes
    | CheckEveryHour
    | NeverNotifyMe


type alias BackendUser =
    { name : Evergreen.V9.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict ( Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId, Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId ) Int
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId)
    }


type alias FrontendUser =
    { name : Evergreen.V9.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    }
