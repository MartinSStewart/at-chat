module Evergreen.V213.User exposing (..)

import Effect.Time
import Evergreen.V213.Discord
import Evergreen.V213.DiscordUserData
import Evergreen.V213.EmailAddress
import Evergreen.V213.Emoji
import Evergreen.V213.FileStatus
import Evergreen.V213.Id
import Evergreen.V213.NonemptyDict
import Evergreen.V213.OneOrGreater
import Evergreen.V213.Pagination
import Evergreen.V213.PersonName
import Evergreen.V213.RichText
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
    | StickersAndEmojisSection


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) Evergreen.V213.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V213.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V213.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V213.Id.Id Evergreen.V213.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V213.Id.AnyGuildOrDmId (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V213.Id.AnyGuildOrDmId, Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId ) (Evergreen.V213.Id.Id Evergreen.V213.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) ( Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelId, Evergreen.V213.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) ( Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId, Evergreen.V213.Id.ThreadRoute )
    , icon : Maybe Evergreen.V213.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) (Evergreen.V213.NonemptyDict.NonemptyDict ( Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelId, Evergreen.V213.Id.ThreadRoute ) Evergreen.V213.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.NonemptyDict.NonemptyDict ( Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId, Evergreen.V213.Id.ThreadRoute ) Evergreen.V213.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V213.RichText.Domain
    , emojiConfig : Evergreen.V213.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V213.Id.Id Evergreen.V213.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V213.Id.Id Evergreen.V213.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V213.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V213.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V213.PersonName.PersonName
    , icon : Maybe Evergreen.V213.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V213.PersonName.PersonName
    , icon : Maybe Evergreen.V213.FileStatus.FileHash
    , email : Maybe Evergreen.V213.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V213.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
