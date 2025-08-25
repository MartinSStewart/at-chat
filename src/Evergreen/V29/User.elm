module Evergreen.V29.User exposing (..)

import Effect.Time
import Evergreen.V29.EmailAddress
import Evergreen.V29.FileStatus
import Evergreen.V29.Id
import Evergreen.V29.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredDirectly Evergreen.V29.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes


type GuildOrDmId
    = GuildOrDmId_Guild (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId)
    | GuildOrDmId_Dm (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)


type alias BackendUser =
    { name : Evergreen.V29.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict GuildOrDmId Int
    , dmLastViewed : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Int
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId)
    , icon : Maybe Evergreen.V29.FileStatus.FileHash
    }


type alias FrontendUser =
    { name : Evergreen.V29.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V29.FileStatus.FileHash
    }
