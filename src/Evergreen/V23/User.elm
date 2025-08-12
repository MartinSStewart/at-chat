module Evergreen.V23.User exposing (..)

import Effect.Time
import Evergreen.V23.EmailAddress
import Evergreen.V23.Id
import Evergreen.V23.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredDirectly Evergreen.V23.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes
    | CheckEveryHour
    | NeverNotifyMe


type GuildOrDmId
    = GuildOrDmId_Guild (Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId) (Evergreen.V23.Id.Id Evergreen.V23.Id.ChannelId)
    | GuildOrDmId_Dm (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId)


type alias BackendUser =
    { name : Evergreen.V23.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict GuildOrDmId Int
    , dmLastViewed : SeqDict.SeqDict (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) Int
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId) (Evergreen.V23.Id.Id Evergreen.V23.Id.ChannelId)
    }


type alias FrontendUser =
    { name : Evergreen.V23.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    }
