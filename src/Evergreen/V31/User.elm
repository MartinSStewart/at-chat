module Evergreen.V31.User exposing (..)

import Effect.Time
import Evergreen.V31.EmailAddress
import Evergreen.V31.FileStatus
import Evergreen.V31.Id
import Evergreen.V31.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredDirectly Evergreen.V31.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes


type alias BackendUser =
    { name : Evergreen.V31.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V31.Id.GuildOrDmId Int
    , dmLastViewed : SeqDict.SeqDict (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId) Int
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId) (Evergreen.V31.Id.Id Evergreen.V31.Id.ChannelId)
    , icon : Maybe Evergreen.V31.FileStatus.FileHash
    }


type alias FrontendUser =
    { name : Evergreen.V31.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V31.FileStatus.FileHash
    }
