module Evergreen.V17.User exposing (..)

import Effect.Time
import Evergreen.V17.EmailAddress
import Evergreen.V17.Id
import Evergreen.V17.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredDirectly Evergreen.V17.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes
    | CheckEveryHour
    | NeverNotifyMe


type GuildOrDmId
    = GuildOrDmId_Guild (Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId) (Evergreen.V17.Id.Id Evergreen.V17.Id.ChannelId)
    | GuildOrDmId_Dm (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)


type alias BackendUser =
    { name : Evergreen.V17.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict GuildOrDmId Int
    , dmLastViewed : SeqDict.SeqDict (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) Int
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId) (Evergreen.V17.Id.Id Evergreen.V17.Id.ChannelId)
    }


type alias FrontendUser =
    { name : Evergreen.V17.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    }
