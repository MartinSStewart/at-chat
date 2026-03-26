module Evergreen.V171.User exposing (..)

import Effect.Time
import Evergreen.V171.Discord
import Evergreen.V171.DiscordUserData
import Evergreen.V171.EmailAddress
import Evergreen.V171.Emoji
import Evergreen.V171.FileStatus
import Evergreen.V171.Id
import Evergreen.V171.NonemptyDict
import Evergreen.V171.OneOrGreater
import Evergreen.V171.Pagination
import Evergreen.V171.PersonName
import Evergreen.V171.RichText
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
    = DmChannelLastViewed (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId) Evergreen.V171.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V171.Discord.Id Evergreen.V171.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V171.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V171.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V171.Id.Id Evergreen.V171.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V171.Id.AnyGuildOrDmId (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V171.Id.AnyGuildOrDmId, Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelMessageId ) (Evergreen.V171.Id.Id Evergreen.V171.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.GuildId) ( Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelId, Evergreen.V171.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V171.Discord.Id Evergreen.V171.Discord.GuildId) ( Evergreen.V171.Discord.Id Evergreen.V171.Discord.ChannelId, Evergreen.V171.Id.ThreadRoute )
    , icon : Maybe Evergreen.V171.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V171.Id.Id Evergreen.V171.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V171.Discord.Id Evergreen.V171.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.GuildId) (Evergreen.V171.NonemptyDict.NonemptyDict ( Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelId, Evergreen.V171.Id.ThreadRoute ) Evergreen.V171.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V171.Discord.Id Evergreen.V171.Discord.GuildId) (Evergreen.V171.NonemptyDict.NonemptyDict ( Evergreen.V171.Discord.Id Evergreen.V171.Discord.ChannelId, Evergreen.V171.Id.ThreadRoute ) Evergreen.V171.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V171.Id.Id Evergreen.V171.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V171.Discord.Id Evergreen.V171.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V171.RichText.Domain
    , emojiConfig : Evergreen.V171.Emoji.EmojiConfig
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V171.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V171.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V171.PersonName.PersonName
    , icon : Maybe Evergreen.V171.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V171.PersonName.PersonName
    , icon : Maybe Evergreen.V171.FileStatus.FileHash
    , email : Maybe Evergreen.V171.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V171.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
