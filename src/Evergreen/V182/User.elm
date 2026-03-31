module Evergreen.V182.User exposing (..)

import Effect.Time
import Evergreen.V182.Discord
import Evergreen.V182.DiscordUserData
import Evergreen.V182.EmailAddress
import Evergreen.V182.Emoji
import Evergreen.V182.FileStatus
import Evergreen.V182.Id
import Evergreen.V182.NonemptyDict
import Evergreen.V182.OneOrGreater
import Evergreen.V182.Pagination
import Evergreen.V182.PersonName
import Evergreen.V182.RichText
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
    = DmChannelLastViewed (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId) Evergreen.V182.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V182.Discord.Id Evergreen.V182.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V182.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V182.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V182.Id.Id Evergreen.V182.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V182.Id.AnyGuildOrDmId (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V182.Id.AnyGuildOrDmId, Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelMessageId ) (Evergreen.V182.Id.Id Evergreen.V182.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.GuildId) ( Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelId, Evergreen.V182.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V182.Discord.Id Evergreen.V182.Discord.GuildId) ( Evergreen.V182.Discord.Id Evergreen.V182.Discord.ChannelId, Evergreen.V182.Id.ThreadRoute )
    , icon : Maybe Evergreen.V182.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V182.Id.Id Evergreen.V182.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V182.Discord.Id Evergreen.V182.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.GuildId) (Evergreen.V182.NonemptyDict.NonemptyDict ( Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelId, Evergreen.V182.Id.ThreadRoute ) Evergreen.V182.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V182.Discord.Id Evergreen.V182.Discord.GuildId) (Evergreen.V182.NonemptyDict.NonemptyDict ( Evergreen.V182.Discord.Id Evergreen.V182.Discord.ChannelId, Evergreen.V182.Id.ThreadRoute ) Evergreen.V182.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V182.Id.Id Evergreen.V182.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V182.Discord.Id Evergreen.V182.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V182.RichText.Domain
    , emojiConfig : Evergreen.V182.Emoji.EmojiConfig
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V182.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V182.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V182.PersonName.PersonName
    , icon : Maybe Evergreen.V182.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V182.PersonName.PersonName
    , icon : Maybe Evergreen.V182.FileStatus.FileHash
    , email : Maybe Evergreen.V182.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V182.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
