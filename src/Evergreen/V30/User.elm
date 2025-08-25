module Evergreen.V30.User exposing (..)

import Effect.Time
import Evergreen.V30.EmailAddress
import Evergreen.V30.FileStatus
import Evergreen.V30.Id
import Evergreen.V30.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredDirectly Evergreen.V30.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes


type GuildOrDmId
    = GuildOrDmId_Guild (Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId) (Evergreen.V30.Id.Id Evergreen.V30.Id.ChannelId)
    | GuildOrDmId_Dm (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)


type alias BackendUser =
    { name : Evergreen.V30.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict GuildOrDmId Int
    , dmLastViewed : SeqDict.SeqDict (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) Int
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId) (Evergreen.V30.Id.Id Evergreen.V30.Id.ChannelId)
    , icon : Maybe Evergreen.V30.FileStatus.FileHash
    }


type alias FrontendUser =
    { name : Evergreen.V30.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V30.FileStatus.FileHash
    }
