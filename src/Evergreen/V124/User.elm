module Evergreen.V124.User exposing (..)

import Effect.Time
import Evergreen.V124.Discord.Id
import Evergreen.V124.EmailAddress
import Evergreen.V124.FileStatus
import Evergreen.V124.Id
import Evergreen.V124.NonemptyDict
import Evergreen.V124.OneOrGreater
import Evergreen.V124.PersonName
import SeqDict
import SeqSet


type AdminUiSection
    = UsersSection
    | LogSection
    | DiscordDmChannelsSection
    | DiscordUsersSection
    | DiscordGuildsSection
    | GuildsSection


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) Evergreen.V124.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V124.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V124.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V124.Id.AnyGuildOrDmId (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V124.Id.AnyGuildOrDmId, Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId ) (Evergreen.V124.Id.Id Evergreen.V124.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) ( Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelId, Evergreen.V124.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId) ( Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.ChannelId, Evergreen.V124.Id.ThreadRoute )
    , icon : Maybe Evergreen.V124.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) (Evergreen.V124.NonemptyDict.NonemptyDict ( Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelId, Evergreen.V124.Id.ThreadRoute ) Evergreen.V124.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId) (Evergreen.V124.NonemptyDict.NonemptyDict ( Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.ChannelId, Evergreen.V124.Id.ThreadRoute ) Evergreen.V124.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    }


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V124.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V124.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V124.PersonName.PersonName
    , icon : Maybe Evergreen.V124.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V124.PersonName.PersonName
    , icon : Maybe Evergreen.V124.FileStatus.FileHash
    , email : Maybe Evergreen.V124.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
