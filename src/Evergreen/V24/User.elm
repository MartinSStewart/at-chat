module Evergreen.V24.User exposing (..)

import Effect.Time
import Evergreen.V24.EmailAddress
import Evergreen.V24.FileStatus
import Evergreen.V24.Id
import Evergreen.V24.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredDirectly Evergreen.V24.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes
    | CheckEveryHour
    | NeverNotifyMe


type GuildOrDmId
    = GuildOrDmId_Guild (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId) (Evergreen.V24.Id.Id Evergreen.V24.Id.ChannelId)
    | GuildOrDmId_Dm (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId)


type alias BackendUser =
    { name : Evergreen.V24.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict GuildOrDmId Int
    , dmLastViewed : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) Int
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId) (Evergreen.V24.Id.Id Evergreen.V24.Id.ChannelId)
    , icon : Maybe Evergreen.V24.FileStatus.FileHash
    }


type alias FrontendUser =
    { name : Evergreen.V24.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V24.FileStatus.FileHash
    }
