module Evergreen.V16.User exposing (..)

import Effect.Time
import Evergreen.V16.EmailAddress
import Evergreen.V16.Id
import Evergreen.V16.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredDirectly Evergreen.V16.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes
    | CheckEveryHour
    | NeverNotifyMe


type GuildOrDmId
    = GuildOrDmId_Guild (Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId) (Evergreen.V16.Id.Id Evergreen.V16.Id.ChannelId)
    | GuildOrDmId_Dm (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId)


type alias BackendUser =
    { name : Evergreen.V16.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict GuildOrDmId Int
    , dmLastViewed : SeqDict.SeqDict (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) Int
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId) (Evergreen.V16.Id.Id Evergreen.V16.Id.ChannelId)
    }


type alias FrontendUser =
    { name : Evergreen.V16.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    }
