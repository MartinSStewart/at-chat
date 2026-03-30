module Evergreen.V179.User exposing (..)

import Effect.Time
import Evergreen.V179.Discord
import Evergreen.V179.DiscordUserData
import Evergreen.V179.EmailAddress
import Evergreen.V179.Emoji
import Evergreen.V179.FileStatus
import Evergreen.V179.Id
import Evergreen.V179.NonemptyDict
import Evergreen.V179.OneOrGreater
import Evergreen.V179.Pagination
import Evergreen.V179.PersonName
import Evergreen.V179.RichText
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
    = DmChannelLastViewed (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) Evergreen.V179.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V179.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V179.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V179.Id.Id Evergreen.V179.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V179.Id.AnyGuildOrDmId (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V179.Id.AnyGuildOrDmId, Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId ) (Evergreen.V179.Id.Id Evergreen.V179.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) ( Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelId, Evergreen.V179.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) ( Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId, Evergreen.V179.Id.ThreadRoute )
    , icon : Maybe Evergreen.V179.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) (Evergreen.V179.NonemptyDict.NonemptyDict ( Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelId, Evergreen.V179.Id.ThreadRoute ) Evergreen.V179.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.NonemptyDict.NonemptyDict ( Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId, Evergreen.V179.Id.ThreadRoute ) Evergreen.V179.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V179.RichText.Domain
    , emojiConfig : Evergreen.V179.Emoji.EmojiConfig
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V179.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V179.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V179.PersonName.PersonName
    , icon : Maybe Evergreen.V179.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V179.PersonName.PersonName
    , icon : Maybe Evergreen.V179.FileStatus.FileHash
    , email : Maybe Evergreen.V179.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V179.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
