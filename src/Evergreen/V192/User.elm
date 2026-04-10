module Evergreen.V192.User exposing (..)

import Effect.Time
import Evergreen.V192.Discord
import Evergreen.V192.DiscordUserData
import Evergreen.V192.EmailAddress
import Evergreen.V192.Emoji
import Evergreen.V192.FileStatus
import Evergreen.V192.Id
import Evergreen.V192.NonemptyDict
import Evergreen.V192.OneOrGreater
import Evergreen.V192.Pagination
import Evergreen.V192.PersonName
import Evergreen.V192.RichText
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


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) Evergreen.V192.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V192.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V192.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V192.Id.Id Evergreen.V192.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V192.Id.AnyGuildOrDmId (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V192.Id.AnyGuildOrDmId, Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId ) (Evergreen.V192.Id.Id Evergreen.V192.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) ( Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelId, Evergreen.V192.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) ( Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId, Evergreen.V192.Id.ThreadRoute )
    , icon : Maybe Evergreen.V192.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) (Evergreen.V192.NonemptyDict.NonemptyDict ( Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelId, Evergreen.V192.Id.ThreadRoute ) Evergreen.V192.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.NonemptyDict.NonemptyDict ( Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId, Evergreen.V192.Id.ThreadRoute ) Evergreen.V192.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V192.RichText.Domain
    , emojiConfig : Evergreen.V192.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V192.Id.Id Evergreen.V192.Id.StickerId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V192.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V192.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V192.PersonName.PersonName
    , icon : Maybe Evergreen.V192.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V192.PersonName.PersonName
    , icon : Maybe Evergreen.V192.FileStatus.FileHash
    , email : Maybe Evergreen.V192.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V192.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
