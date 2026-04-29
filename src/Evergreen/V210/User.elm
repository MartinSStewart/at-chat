module Evergreen.V210.User exposing (..)

import Effect.Time
import Evergreen.V210.Discord
import Evergreen.V210.DiscordUserData
import Evergreen.V210.EmailAddress
import Evergreen.V210.Emoji
import Evergreen.V210.FileStatus
import Evergreen.V210.Id
import Evergreen.V210.NonemptyDict
import Evergreen.V210.OneOrGreater
import Evergreen.V210.Pagination
import Evergreen.V210.PersonName
import Evergreen.V210.RichText
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
    = DmChannelLastViewed (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) Evergreen.V210.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V210.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V210.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V210.Id.Id Evergreen.V210.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V210.Id.AnyGuildOrDmId (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V210.Id.AnyGuildOrDmId, Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId ) (Evergreen.V210.Id.Id Evergreen.V210.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) ( Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelId, Evergreen.V210.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) ( Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId, Evergreen.V210.Id.ThreadRoute )
    , icon : Maybe Evergreen.V210.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) (Evergreen.V210.NonemptyDict.NonemptyDict ( Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelId, Evergreen.V210.Id.ThreadRoute ) Evergreen.V210.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.NonemptyDict.NonemptyDict ( Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId, Evergreen.V210.Id.ThreadRoute ) Evergreen.V210.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V210.RichText.Domain
    , emojiConfig : Evergreen.V210.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V210.Id.Id Evergreen.V210.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V210.Id.Id Evergreen.V210.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V210.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V210.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V210.PersonName.PersonName
    , icon : Maybe Evergreen.V210.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V210.PersonName.PersonName
    , icon : Maybe Evergreen.V210.FileStatus.FileHash
    , email : Maybe Evergreen.V210.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V210.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
