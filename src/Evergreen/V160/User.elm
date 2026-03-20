module Evergreen.V160.User exposing (..)

import Effect.Time
import Evergreen.V160.Discord
import Evergreen.V160.DiscordUserData
import Evergreen.V160.EmailAddress
import Evergreen.V160.FileStatus
import Evergreen.V160.Id
import Evergreen.V160.NonemptyDict
import Evergreen.V160.OneOrGreater
import Evergreen.V160.Pagination
import Evergreen.V160.PersonName
import Evergreen.V160.RichText
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
    = DmChannelLastViewed (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) Evergreen.V160.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V160.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V160.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V160.Id.Id Evergreen.V160.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V160.Id.AnyGuildOrDmId (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V160.Id.AnyGuildOrDmId, Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId ) (Evergreen.V160.Id.Id Evergreen.V160.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) ( Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelId, Evergreen.V160.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) ( Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId, Evergreen.V160.Id.ThreadRoute )
    , icon : Maybe Evergreen.V160.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) (Evergreen.V160.NonemptyDict.NonemptyDict ( Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelId, Evergreen.V160.Id.ThreadRoute ) Evergreen.V160.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.NonemptyDict.NonemptyDict ( Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId, Evergreen.V160.Id.ThreadRoute ) Evergreen.V160.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V160.RichText.Domain
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V160.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V160.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V160.PersonName.PersonName
    , icon : Maybe Evergreen.V160.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V160.PersonName.PersonName
    , icon : Maybe Evergreen.V160.FileStatus.FileHash
    , email : Maybe Evergreen.V160.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V160.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
