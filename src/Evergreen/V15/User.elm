module Evergreen.V15.User exposing (..)

import Effect.Time
import Evergreen.V15.EmailAddress
import Evergreen.V15.Id
import Evergreen.V15.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredDirectly Evergreen.V15.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes
    | CheckEveryHour
    | NeverNotifyMe


type GuildOrDmId
    = GuildOrDmId_Guild (Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId) (Evergreen.V15.Id.Id Evergreen.V15.Id.ChannelId)
    | GuildOrDmId_Dm (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId)


type alias BackendUser =
    { name : Evergreen.V15.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict GuildOrDmId Int
    , dmLastViewed : SeqDict.SeqDict (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) Int
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId) (Evergreen.V15.Id.Id Evergreen.V15.Id.ChannelId)
    }


type alias FrontendUser =
    { name : Evergreen.V15.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    }
