module Evergreen.V166.User exposing (..)

import Effect.Time
import Evergreen.V166.Discord
import Evergreen.V166.DiscordUserData
import Evergreen.V166.EmailAddress
import Evergreen.V166.FileStatus
import Evergreen.V166.Id
import Evergreen.V166.NonemptyDict
import Evergreen.V166.OneOrGreater
import Evergreen.V166.Pagination
import Evergreen.V166.PersonName
import Evergreen.V166.RichText
import SeqDict
import SeqSet


type AdminUiSection
    = UsersSection
    | LogSection
    | DiscordDmChannelsSection
    | DiscordUsersSection
    | DiscordGuildsSection
    | GuildsSection
    | ApiKeysSection
    | ExportSection
    | ConnectionsSection


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) Evergreen.V166.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V166.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V166.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V166.Id.Id Evergreen.V166.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V166.Id.AnyGuildOrDmId (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V166.Id.AnyGuildOrDmId, Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId ) (Evergreen.V166.Id.Id Evergreen.V166.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) ( Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelId, Evergreen.V166.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) ( Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId, Evergreen.V166.Id.ThreadRoute )
    , icon : Maybe Evergreen.V166.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) (Evergreen.V166.NonemptyDict.NonemptyDict ( Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelId, Evergreen.V166.Id.ThreadRoute ) Evergreen.V166.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.NonemptyDict.NonemptyDict ( Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId, Evergreen.V166.Id.ThreadRoute ) Evergreen.V166.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V166.RichText.Domain
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V166.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V166.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V166.PersonName.PersonName
    , icon : Maybe Evergreen.V166.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V166.PersonName.PersonName
    , icon : Maybe Evergreen.V166.FileStatus.FileHash
    , email : Maybe Evergreen.V166.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V166.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
