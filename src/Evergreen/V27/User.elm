module Evergreen.V27.User exposing (..)

import Effect.Time
import Evergreen.V27.EmailAddress
import Evergreen.V27.FileStatus
import Evergreen.V27.Id
import Evergreen.V27.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredDirectly Evergreen.V27.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes


type GuildOrDmId
    = GuildOrDmId_Guild (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId)
    | GuildOrDmId_Dm (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)


type alias BackendUser =
    { name : Evergreen.V27.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict GuildOrDmId Int
    , dmLastViewed : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Int
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId)
    , icon : Maybe Evergreen.V27.FileStatus.FileHash
    }


type alias FrontendUser =
    { name : Evergreen.V27.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V27.FileStatus.FileHash
    }
