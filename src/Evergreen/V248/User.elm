module Evergreen.V248.User exposing (..)

import Effect.Time
import Evergreen.V248.CustomEmoji
import Evergreen.V248.Discord
import Evergreen.V248.DiscordUserData
import Evergreen.V248.EmailAddress
import Evergreen.V248.Emoji
import Evergreen.V248.FileStatus
import Evergreen.V248.Id
import Evergreen.V248.NonemptyDict
import Evergreen.V248.OneOrGreater
import Evergreen.V248.Pagination
import Evergreen.V248.PersonName
import Evergreen.V248.RichText
import Evergreen.V248.Sticker
import Evergreen.V248.UserAgent
import Evergreen.V248.UserSession
import SeqDict
import SeqSet


type AdminUiSection
    = UsersSection
    | LogSection
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


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) Evergreen.V248.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V248.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V248.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V248.Id.Id Evergreen.V248.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V248.Id.AnyGuildOrDmId (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V248.Id.AnyGuildOrDmId, Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId ) (Evergreen.V248.Id.Id Evergreen.V248.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) ( Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelId, Evergreen.V248.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) ( Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId, Evergreen.V248.Id.ThreadRoute )
    , icon : Maybe Evergreen.V248.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) (Evergreen.V248.NonemptyDict.NonemptyDict ( Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelId, Evergreen.V248.Id.ThreadRoute ) Evergreen.V248.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.NonemptyDict.NonemptyDict ( Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId, Evergreen.V248.Id.ThreadRoute ) Evergreen.V248.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V248.RichText.Domain
    , emojiConfig : Evergreen.V248.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V248.Id.Id Evergreen.V248.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V248.Id.Id Evergreen.V248.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V248.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V248.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V248.PersonName.PersonName
    , icon : Maybe Evergreen.V248.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V248.PersonName.PersonName
    , icon : Maybe Evergreen.V248.FileStatus.FileHash
    , email : Maybe Evergreen.V248.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V248.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V248.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V248.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.StickerId) Evergreen.V248.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.CustomEmojiId) Evergreen.V248.CustomEmoji.CustomEmojiData
    }
