module Evergreen.V46.User exposing (..)

import Effect.Time
import Evergreen.V46.EmailAddress
import Evergreen.V46.FileStatus
import Evergreen.V46.Id
import Evergreen.V46.PersonName
import SeqDict
import SeqSet


type EmailStatus
    = RegisteredFromDiscord
    | RegisteredDirectly Evergreen.V46.EmailAddress.EmailAddress


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes


type alias BackendUser =
    { name : Evergreen.V46.PersonName.PersonName
    , isAdmin : Bool
    , email : EmailStatus
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V46.Id.GuildOrDmIdNoThread (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V46.Id.GuildOrDmIdNoThread, Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelMessageId ) (Evergreen.V46.Id.Id Evergreen.V46.Id.ThreadMessageId)
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId) (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelId)
    , icon : Maybe Evergreen.V46.FileStatus.FileHash
    }


type alias FrontendUser =
    { name : Evergreen.V46.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V46.FileStatus.FileHash
    }
