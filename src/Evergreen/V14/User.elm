module Evergreen.V14.User exposing (..)

import Effect.Time
import Evergreen.V14.EmailAddress
import Evergreen.V14.Id
import Evergreen.V14.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredDirectly Evergreen.V14.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes
    | CheckEveryHour
    | NeverNotifyMe


type alias BackendUser =
    { name : Evergreen.V14.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict ( Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId, Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId ) Int
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId)
    }


type alias FrontendUser =
    { name : Evergreen.V14.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    }
