module Evergreen.V176.User exposing (..)

import Effect.Time
import Evergreen.V176.Discord
import Evergreen.V176.DiscordUserData
import Evergreen.V176.EmailAddress
import Evergreen.V176.Emoji
import Evergreen.V176.FileStatus
import Evergreen.V176.Id
import Evergreen.V176.NonemptyDict
import Evergreen.V176.OneOrGreater
import Evergreen.V176.Pagination
import Evergreen.V176.PersonName
import Evergreen.V176.RichText
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
    = DmChannelLastViewed (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) Evergreen.V176.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V176.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V176.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V176.Id.Id Evergreen.V176.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V176.Id.AnyGuildOrDmId (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V176.Id.AnyGuildOrDmId, Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId ) (Evergreen.V176.Id.Id Evergreen.V176.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) ( Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelId, Evergreen.V176.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) ( Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId, Evergreen.V176.Id.ThreadRoute )
    , icon : Maybe Evergreen.V176.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) (Evergreen.V176.NonemptyDict.NonemptyDict ( Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelId, Evergreen.V176.Id.ThreadRoute ) Evergreen.V176.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.NonemptyDict.NonemptyDict ( Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId, Evergreen.V176.Id.ThreadRoute ) Evergreen.V176.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V176.RichText.Domain
    , emojiConfig : Evergreen.V176.Emoji.EmojiConfig
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V176.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V176.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V176.PersonName.PersonName
    , icon : Maybe Evergreen.V176.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V176.PersonName.PersonName
    , icon : Maybe Evergreen.V176.FileStatus.FileHash
    , email : Maybe Evergreen.V176.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V176.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
