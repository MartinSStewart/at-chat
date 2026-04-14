module Evergreen.V197.User exposing (..)

import Effect.Time
import Evergreen.V197.Discord
import Evergreen.V197.DiscordUserData
import Evergreen.V197.EmailAddress
import Evergreen.V197.Emoji
import Evergreen.V197.FileStatus
import Evergreen.V197.Id
import Evergreen.V197.NonemptyDict
import Evergreen.V197.OneOrGreater
import Evergreen.V197.Pagination
import Evergreen.V197.PersonName
import Evergreen.V197.RichText
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
    | FilesSection
    | ToBackendLogsSection
    | StickersSection


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) Evergreen.V197.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V197.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V197.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V197.Id.Id Evergreen.V197.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V197.Id.AnyGuildOrDmId (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V197.Id.AnyGuildOrDmId, Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId ) (Evergreen.V197.Id.Id Evergreen.V197.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) ( Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelId, Evergreen.V197.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) ( Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId, Evergreen.V197.Id.ThreadRoute )
    , icon : Maybe Evergreen.V197.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) (Evergreen.V197.NonemptyDict.NonemptyDict ( Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelId, Evergreen.V197.Id.ThreadRoute ) Evergreen.V197.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.NonemptyDict.NonemptyDict ( Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId, Evergreen.V197.Id.ThreadRoute ) Evergreen.V197.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V197.RichText.Domain
    , emojiConfig : Evergreen.V197.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V197.Id.Id Evergreen.V197.Id.StickerId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V197.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V197.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V197.PersonName.PersonName
    , icon : Maybe Evergreen.V197.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V197.PersonName.PersonName
    , icon : Maybe Evergreen.V197.FileStatus.FileHash
    , email : Maybe Evergreen.V197.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V197.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
