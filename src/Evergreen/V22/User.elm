module Evergreen.V22.User exposing (..)

import Effect.Time
import Evergreen.V22.EmailAddress
import Evergreen.V22.Id
import Evergreen.V22.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredDirectly Evergreen.V22.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes
    | CheckEveryHour
    | NeverNotifyMe


type GuildOrDmId
    = GuildOrDmId_Guild (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId)
    | GuildOrDmId_Dm (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId)


type alias BackendUser =
    { name : Evergreen.V22.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict GuildOrDmId Int
    , dmLastViewed : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) Int
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId)
    }


type alias FrontendUser =
    { name : Evergreen.V22.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    }
