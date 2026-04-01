module Evergreen.V184.User exposing (..)

import Effect.Time
import Evergreen.V184.Discord
import Evergreen.V184.DiscordUserData
import Evergreen.V184.EmailAddress
import Evergreen.V184.Emoji
import Evergreen.V184.FileStatus
import Evergreen.V184.Id
import Evergreen.V184.NonemptyDict
import Evergreen.V184.OneOrGreater
import Evergreen.V184.Pagination
import Evergreen.V184.PersonName
import Evergreen.V184.RichText
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
    = DmChannelLastViewed (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) Evergreen.V184.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V184.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V184.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V184.Id.Id Evergreen.V184.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V184.Id.AnyGuildOrDmId (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V184.Id.AnyGuildOrDmId, Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId ) (Evergreen.V184.Id.Id Evergreen.V184.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) ( Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelId, Evergreen.V184.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) ( Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId, Evergreen.V184.Id.ThreadRoute )
    , icon : Maybe Evergreen.V184.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) (Evergreen.V184.NonemptyDict.NonemptyDict ( Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelId, Evergreen.V184.Id.ThreadRoute ) Evergreen.V184.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.NonemptyDict.NonemptyDict ( Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId, Evergreen.V184.Id.ThreadRoute ) Evergreen.V184.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V184.RichText.Domain
    , emojiConfig : Evergreen.V184.Emoji.EmojiConfig
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V184.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V184.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V184.PersonName.PersonName
    , icon : Maybe Evergreen.V184.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V184.PersonName.PersonName
    , icon : Maybe Evergreen.V184.FileStatus.FileHash
    , email : Maybe Evergreen.V184.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V184.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
