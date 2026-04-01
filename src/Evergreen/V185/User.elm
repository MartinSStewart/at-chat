module Evergreen.V185.User exposing (..)

import Effect.Time
import Evergreen.V185.Discord
import Evergreen.V185.DiscordUserData
import Evergreen.V185.EmailAddress
import Evergreen.V185.Emoji
import Evergreen.V185.FileStatus
import Evergreen.V185.Id
import Evergreen.V185.NonemptyDict
import Evergreen.V185.OneOrGreater
import Evergreen.V185.Pagination
import Evergreen.V185.PersonName
import Evergreen.V185.RichText
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
    = DmChannelLastViewed (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) Evergreen.V185.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V185.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V185.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V185.Id.Id Evergreen.V185.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V185.Id.AnyGuildOrDmId (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V185.Id.AnyGuildOrDmId, Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId ) (Evergreen.V185.Id.Id Evergreen.V185.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) ( Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelId, Evergreen.V185.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) ( Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId, Evergreen.V185.Id.ThreadRoute )
    , icon : Maybe Evergreen.V185.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) (Evergreen.V185.NonemptyDict.NonemptyDict ( Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelId, Evergreen.V185.Id.ThreadRoute ) Evergreen.V185.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.NonemptyDict.NonemptyDict ( Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId, Evergreen.V185.Id.ThreadRoute ) Evergreen.V185.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V185.RichText.Domain
    , emojiConfig : Evergreen.V185.Emoji.EmojiConfig
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V185.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V185.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V185.PersonName.PersonName
    , icon : Maybe Evergreen.V185.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V185.PersonName.PersonName
    , icon : Maybe Evergreen.V185.FileStatus.FileHash
    , email : Maybe Evergreen.V185.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V185.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
