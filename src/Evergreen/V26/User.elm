module Evergreen.V26.User exposing (..)

import Effect.Time
import Evergreen.V26.EmailAddress
import Evergreen.V26.FileStatus
import Evergreen.V26.Id
import Evergreen.V26.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredDirectly Evergreen.V26.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes


type GuildOrDmId
    = GuildOrDmId_Guild (Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId) (Evergreen.V26.Id.Id Evergreen.V26.Id.ChannelId)
    | GuildOrDmId_Dm (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId)


type alias BackendUser =
    { name : Evergreen.V26.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict GuildOrDmId Int
    , dmLastViewed : SeqDict.SeqDict (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) Int
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId) (Evergreen.V26.Id.Id Evergreen.V26.Id.ChannelId)
    , icon : Maybe Evergreen.V26.FileStatus.FileHash
    }


type alias FrontendUser =
    { name : Evergreen.V26.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V26.FileStatus.FileHash
    }
