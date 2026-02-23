module Evergreen.V120.User exposing (..)

import Effect.Time
import Evergreen.V120.Discord.Id
import Evergreen.V120.EmailAddress
import Evergreen.V120.FileStatus
import Evergreen.V120.Id
import Evergreen.V120.NonemptyDict
import Evergreen.V120.OneOrGreater
import Evergreen.V120.PersonName
import SeqDict
import SeqSet


type AdminUiSection
    = UsersSection
    | LogSection
    | DiscordDmChannelsSection
    | DiscordUsersSection


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) Evergreen.V120.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V120.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V120.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V120.Id.AnyGuildOrDmId (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V120.Id.AnyGuildOrDmId, Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId ) (Evergreen.V120.Id.Id Evergreen.V120.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) ( Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelId, Evergreen.V120.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId) ( Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.ChannelId, Evergreen.V120.Id.ThreadRoute )
    , icon : Maybe Evergreen.V120.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) (Evergreen.V120.NonemptyDict.NonemptyDict ( Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelId, Evergreen.V120.Id.ThreadRoute ) Evergreen.V120.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId) (Evergreen.V120.NonemptyDict.NonemptyDict ( Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.ChannelId, Evergreen.V120.Id.ThreadRoute ) Evergreen.V120.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    }


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V120.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V120.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V120.PersonName.PersonName
    , icon : Maybe Evergreen.V120.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V120.PersonName.PersonName
    , icon : Maybe Evergreen.V120.FileStatus.FileHash
    , email : Maybe Evergreen.V120.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
