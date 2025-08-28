module Evergreen.V42.User exposing (..)

import Effect.Time
import Evergreen.V42.EmailAddress
import Evergreen.V42.FileStatus
import Evergreen.V42.Id
import Evergreen.V42.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredDirectly Evergreen.V42.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes


type alias BackendUser =
    { name : Evergreen.V42.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V42.Id.GuildOrDmIdNoThread (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V42.Id.GuildOrDmIdNoThread, Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId ) (Evergreen.V42.Id.Id Evergreen.V42.Id.ThreadMessageId)
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId) (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelId)
    , icon : Maybe Evergreen.V42.FileStatus.FileHash
    }


type alias FrontendUser =
    { name : Evergreen.V42.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V42.FileStatus.FileHash
    }
