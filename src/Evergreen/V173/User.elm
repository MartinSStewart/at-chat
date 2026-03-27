module Evergreen.V173.User exposing (..)

import Effect.Time
import Evergreen.V173.Discord
import Evergreen.V173.DiscordUserData
import Evergreen.V173.EmailAddress
import Evergreen.V173.Emoji
import Evergreen.V173.FileStatus
import Evergreen.V173.Id
import Evergreen.V173.NonemptyDict
import Evergreen.V173.OneOrGreater
import Evergreen.V173.Pagination
import Evergreen.V173.PersonName
import Evergreen.V173.RichText
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
    = DmChannelLastViewed (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) Evergreen.V173.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V173.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V173.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V173.Id.Id Evergreen.V173.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V173.Id.AnyGuildOrDmId (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V173.Id.AnyGuildOrDmId, Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId ) (Evergreen.V173.Id.Id Evergreen.V173.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) ( Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelId, Evergreen.V173.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) ( Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId, Evergreen.V173.Id.ThreadRoute )
    , icon : Maybe Evergreen.V173.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) (Evergreen.V173.NonemptyDict.NonemptyDict ( Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelId, Evergreen.V173.Id.ThreadRoute ) Evergreen.V173.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.NonemptyDict.NonemptyDict ( Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId, Evergreen.V173.Id.ThreadRoute ) Evergreen.V173.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V173.RichText.Domain
    , emojiConfig : Evergreen.V173.Emoji.EmojiConfig
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V173.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V173.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V173.PersonName.PersonName
    , icon : Maybe Evergreen.V173.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V173.PersonName.PersonName
    , icon : Maybe Evergreen.V173.FileStatus.FileHash
    , email : Maybe Evergreen.V173.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V173.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
