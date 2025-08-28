module Evergreen.V41.User exposing (..)

import Effect.Time
import Evergreen.V41.EmailAddress
import Evergreen.V41.FileStatus
import Evergreen.V41.Id
import Evergreen.V41.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredDirectly Evergreen.V41.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes


type alias BackendUser =
    { name : Evergreen.V41.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V41.Id.GuildOrDmIdNoThread (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V41.Id.GuildOrDmIdNoThread, Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId ) (Evergreen.V41.Id.Id Evergreen.V41.Id.ThreadMessageId)
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId) (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelId)
    , icon : Maybe Evergreen.V41.FileStatus.FileHash
    }


type alias FrontendUser =
    { name : Evergreen.V41.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V41.FileStatus.FileHash
    }
