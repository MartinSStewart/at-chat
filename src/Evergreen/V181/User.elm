module Evergreen.V181.User exposing (..)

import Effect.Time
import Evergreen.V181.Discord
import Evergreen.V181.DiscordUserData
import Evergreen.V181.EmailAddress
import Evergreen.V181.Emoji
import Evergreen.V181.FileStatus
import Evergreen.V181.Id
import Evergreen.V181.NonemptyDict
import Evergreen.V181.OneOrGreater
import Evergreen.V181.Pagination
import Evergreen.V181.PersonName
import Evergreen.V181.RichText
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
    = DmChannelLastViewed (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) Evergreen.V181.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V181.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V181.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V181.Id.Id Evergreen.V181.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V181.Id.AnyGuildOrDmId (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V181.Id.AnyGuildOrDmId, Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId ) (Evergreen.V181.Id.Id Evergreen.V181.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) ( Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelId, Evergreen.V181.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) ( Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId, Evergreen.V181.Id.ThreadRoute )
    , icon : Maybe Evergreen.V181.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) (Evergreen.V181.NonemptyDict.NonemptyDict ( Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelId, Evergreen.V181.Id.ThreadRoute ) Evergreen.V181.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.NonemptyDict.NonemptyDict ( Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId, Evergreen.V181.Id.ThreadRoute ) Evergreen.V181.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V181.RichText.Domain
    , emojiConfig : Evergreen.V181.Emoji.EmojiConfig
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V181.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V181.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V181.PersonName.PersonName
    , icon : Maybe Evergreen.V181.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V181.PersonName.PersonName
    , icon : Maybe Evergreen.V181.FileStatus.FileHash
    , email : Maybe Evergreen.V181.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V181.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
