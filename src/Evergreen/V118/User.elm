module Evergreen.V118.User exposing (..)

import Effect.Time
import Evergreen.V118.Discord.Id
import Evergreen.V118.EmailAddress
import Evergreen.V118.FileStatus
import Evergreen.V118.Id
import Evergreen.V118.NonemptyDict
import Evergreen.V118.OneOrGreater
import Evergreen.V118.PersonName
import SeqDict
import SeqSet


type AdminUiSection
    = UsersSection
    | LogSection


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) Evergreen.V118.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V118.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V118.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V118.Id.AnyGuildOrDmId (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V118.Id.AnyGuildOrDmId, Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId ) (Evergreen.V118.Id.Id Evergreen.V118.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) ( Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelId, Evergreen.V118.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId) ( Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.ChannelId, Evergreen.V118.Id.ThreadRoute )
    , icon : Maybe Evergreen.V118.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) (Evergreen.V118.NonemptyDict.NonemptyDict ( Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelId, Evergreen.V118.Id.ThreadRoute ) Evergreen.V118.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId) (Evergreen.V118.NonemptyDict.NonemptyDict ( Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.ChannelId, Evergreen.V118.Id.ThreadRoute ) Evergreen.V118.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V118.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V118.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V118.PersonName.PersonName
    , icon : Maybe Evergreen.V118.FileStatus.FileHash
    }


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V118.PersonName.PersonName
    , icon : Maybe Evergreen.V118.FileStatus.FileHash
    , email : Maybe Evergreen.V118.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
