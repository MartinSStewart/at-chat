module Evergreen.V204.User exposing (..)

import Effect.Time
import Evergreen.V204.Discord
import Evergreen.V204.DiscordUserData
import Evergreen.V204.EmailAddress
import Evergreen.V204.Emoji
import Evergreen.V204.FileStatus
import Evergreen.V204.Id
import Evergreen.V204.NonemptyDict
import Evergreen.V204.OneOrGreater
import Evergreen.V204.Pagination
import Evergreen.V204.PersonName
import Evergreen.V204.RichText
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
    = DmChannelLastViewed (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) Evergreen.V204.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V204.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V204.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V204.Id.Id Evergreen.V204.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V204.Id.AnyGuildOrDmId (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V204.Id.AnyGuildOrDmId, Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId ) (Evergreen.V204.Id.Id Evergreen.V204.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) ( Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelId, Evergreen.V204.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) ( Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId, Evergreen.V204.Id.ThreadRoute )
    , icon : Maybe Evergreen.V204.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) (Evergreen.V204.NonemptyDict.NonemptyDict ( Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelId, Evergreen.V204.Id.ThreadRoute ) Evergreen.V204.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.NonemptyDict.NonemptyDict ( Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId, Evergreen.V204.Id.ThreadRoute ) Evergreen.V204.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V204.RichText.Domain
    , emojiConfig : Evergreen.V204.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V204.Id.Id Evergreen.V204.Id.StickerId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V204.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V204.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V204.PersonName.PersonName
    , icon : Maybe Evergreen.V204.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V204.PersonName.PersonName
    , icon : Maybe Evergreen.V204.FileStatus.FileHash
    , email : Maybe Evergreen.V204.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V204.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
