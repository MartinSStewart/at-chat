module Evergreen.V201.User exposing (..)

import Effect.Time
import Evergreen.V201.Discord
import Evergreen.V201.DiscordUserData
import Evergreen.V201.EmailAddress
import Evergreen.V201.Emoji
import Evergreen.V201.FileStatus
import Evergreen.V201.Id
import Evergreen.V201.NonemptyDict
import Evergreen.V201.OneOrGreater
import Evergreen.V201.Pagination
import Evergreen.V201.PersonName
import Evergreen.V201.RichText
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
    = DmChannelLastViewed (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) Evergreen.V201.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V201.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V201.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V201.Id.Id Evergreen.V201.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V201.Id.AnyGuildOrDmId (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V201.Id.AnyGuildOrDmId, Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId ) (Evergreen.V201.Id.Id Evergreen.V201.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) ( Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelId, Evergreen.V201.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) ( Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId, Evergreen.V201.Id.ThreadRoute )
    , icon : Maybe Evergreen.V201.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) (Evergreen.V201.NonemptyDict.NonemptyDict ( Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelId, Evergreen.V201.Id.ThreadRoute ) Evergreen.V201.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.NonemptyDict.NonemptyDict ( Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId, Evergreen.V201.Id.ThreadRoute ) Evergreen.V201.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V201.RichText.Domain
    , emojiConfig : Evergreen.V201.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V201.Id.Id Evergreen.V201.Id.StickerId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V201.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V201.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V201.PersonName.PersonName
    , icon : Maybe Evergreen.V201.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V201.PersonName.PersonName
    , icon : Maybe Evergreen.V201.FileStatus.FileHash
    , email : Maybe Evergreen.V201.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V201.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
