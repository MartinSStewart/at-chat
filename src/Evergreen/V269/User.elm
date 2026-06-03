module Evergreen.V269.User exposing (..)

import Effect.Time
import Evergreen.V269.CustomEmoji
import Evergreen.V269.Discord
import Evergreen.V269.DiscordUserData
import Evergreen.V269.EmailAddress
import Evergreen.V269.Emoji
import Evergreen.V269.FileStatus
import Evergreen.V269.Id
import Evergreen.V269.NonemptyDict
import Evergreen.V269.OneOrGreater
import Evergreen.V269.Pagination
import Evergreen.V269.PersonName
import Evergreen.V269.RichText
import Evergreen.V269.Sticker
import Evergreen.V269.UserAgent
import Evergreen.V269.UserSession
import SeqDict
import SeqSet


type AdminUiSection
    = UsersSection
    | LogSection
    | DmChannelsSection
    | DiscordDmChannelsSection
    | DiscordUsersSection
    | DiscordGuildsSection
    | GuildsSection
    | DeletedGuildsSection
    | ApiKeysSection
    | ExportSection
    | ConnectionsSection
    | FilesSection
    | ToBackendLogsSection
    | StickersAndEmojisSection
    | VoiceChatSection
    | WebsocketCloseEventsSection
    | SessionsSection


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) Evergreen.V269.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V269.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V269.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V269.Id.Id Evergreen.V269.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V269.Id.AnyGuildOrDmId (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V269.Id.AnyGuildOrDmId, Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId ) (Evergreen.V269.Id.Id Evergreen.V269.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) ( Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelId, Evergreen.V269.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) ( Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId, Evergreen.V269.Id.ThreadRoute )
    , icon : Maybe Evergreen.V269.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) (Evergreen.V269.NonemptyDict.NonemptyDict ( Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelId, Evergreen.V269.Id.ThreadRoute ) Evergreen.V269.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.NonemptyDict.NonemptyDict ( Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId, Evergreen.V269.Id.ThreadRoute ) Evergreen.V269.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V269.RichText.Domain
    , emojiConfig : Evergreen.V269.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V269.Id.Id Evergreen.V269.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V269.Id.Id Evergreen.V269.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V269.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V269.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V269.PersonName.PersonName
    , icon : Maybe Evergreen.V269.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V269.PersonName.PersonName
    , icon : Maybe Evergreen.V269.FileStatus.FileHash
    , email : Maybe Evergreen.V269.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V269.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V269.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V269.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.StickerId) Evergreen.V269.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.CustomEmojiId) Evergreen.V269.CustomEmoji.CustomEmojiData
    }
