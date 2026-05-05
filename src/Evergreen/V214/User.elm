module Evergreen.V214.User exposing (..)

import Effect.Time
import Evergreen.V214.Discord
import Evergreen.V214.DiscordUserData
import Evergreen.V214.EmailAddress
import Evergreen.V214.Emoji
import Evergreen.V214.FileStatus
import Evergreen.V214.Id
import Evergreen.V214.NonemptyDict
import Evergreen.V214.OneOrGreater
import Evergreen.V214.Pagination
import Evergreen.V214.PersonName
import Evergreen.V214.RichText
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
    = DmChannelLastViewed (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId) Evergreen.V214.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V214.Discord.Id Evergreen.V214.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V214.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V214.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V214.Id.Id Evergreen.V214.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V214.Id.AnyGuildOrDmId (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V214.Id.AnyGuildOrDmId, Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelMessageId ) (Evergreen.V214.Id.Id Evergreen.V214.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.GuildId) ( Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelId, Evergreen.V214.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V214.Discord.Id Evergreen.V214.Discord.GuildId) ( Evergreen.V214.Discord.Id Evergreen.V214.Discord.ChannelId, Evergreen.V214.Id.ThreadRoute )
    , icon : Maybe Evergreen.V214.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V214.Id.Id Evergreen.V214.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V214.Discord.Id Evergreen.V214.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.GuildId) (Evergreen.V214.NonemptyDict.NonemptyDict ( Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelId, Evergreen.V214.Id.ThreadRoute ) Evergreen.V214.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V214.Discord.Id Evergreen.V214.Discord.GuildId) (Evergreen.V214.NonemptyDict.NonemptyDict ( Evergreen.V214.Discord.Id Evergreen.V214.Discord.ChannelId, Evergreen.V214.Id.ThreadRoute ) Evergreen.V214.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V214.Id.Id Evergreen.V214.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V214.Discord.Id Evergreen.V214.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V214.RichText.Domain
    , emojiConfig : Evergreen.V214.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V214.Id.Id Evergreen.V214.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V214.Id.Id Evergreen.V214.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V214.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V214.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V214.PersonName.PersonName
    , icon : Maybe Evergreen.V214.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V214.PersonName.PersonName
    , icon : Maybe Evergreen.V214.FileStatus.FileHash
    , email : Maybe Evergreen.V214.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V214.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
