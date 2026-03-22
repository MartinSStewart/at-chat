module Evergreen.V167.User exposing (..)

import Effect.Time
import Evergreen.V167.Discord
import Evergreen.V167.DiscordUserData
import Evergreen.V167.EmailAddress
import Evergreen.V167.FileStatus
import Evergreen.V167.Id
import Evergreen.V167.NonemptyDict
import Evergreen.V167.OneOrGreater
import Evergreen.V167.Pagination
import Evergreen.V167.PersonName
import Evergreen.V167.RichText
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
    = DmChannelLastViewed (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) Evergreen.V167.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V167.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V167.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V167.Id.Id Evergreen.V167.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V167.Id.AnyGuildOrDmId (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V167.Id.AnyGuildOrDmId, Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId ) (Evergreen.V167.Id.Id Evergreen.V167.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) ( Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelId, Evergreen.V167.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) ( Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId, Evergreen.V167.Id.ThreadRoute )
    , icon : Maybe Evergreen.V167.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) (Evergreen.V167.NonemptyDict.NonemptyDict ( Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelId, Evergreen.V167.Id.ThreadRoute ) Evergreen.V167.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.NonemptyDict.NonemptyDict ( Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId, Evergreen.V167.Id.ThreadRoute ) Evergreen.V167.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V167.RichText.Domain
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V167.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V167.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V167.PersonName.PersonName
    , icon : Maybe Evergreen.V167.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V167.PersonName.PersonName
    , icon : Maybe Evergreen.V167.FileStatus.FileHash
    , email : Maybe Evergreen.V167.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V167.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
