module Evergreen.V295.User exposing (..)

import Effect.Time
import Evergreen.V295.CustomEmoji
import Evergreen.V295.Discord
import Evergreen.V295.EmailAddress
import Evergreen.V295.Emoji
import Evergreen.V295.FileStatus
import Evergreen.V295.Id
import Evergreen.V295.LinkedAndOtherDiscordUsers
import Evergreen.V295.NonemptyDict
import Evergreen.V295.OneOrGreater
import Evergreen.V295.Pagination
import Evergreen.V295.PersonName
import Evergreen.V295.RichText
import Evergreen.V295.Sticker
import Evergreen.V295.UserAgent
import Evergreen.V295.UserSession
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
    = DmChannelLastViewed (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) Evergreen.V295.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V295.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V295.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V295.Id.Id Evergreen.V295.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V295.Id.AnyGuildOrDmId (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V295.Id.AnyGuildOrDmId, Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId ) (Evergreen.V295.Id.Id Evergreen.V295.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) ( Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelId, Evergreen.V295.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) ( Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId, Evergreen.V295.Id.ThreadRoute )
    , icon : Maybe Evergreen.V295.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) (Evergreen.V295.NonemptyDict.NonemptyDict ( Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelId, Evergreen.V295.Id.ThreadRoute ) Evergreen.V295.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.NonemptyDict.NonemptyDict ( Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId, Evergreen.V295.Id.ThreadRoute ) Evergreen.V295.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V295.RichText.Domain
    , emojiConfig : Evergreen.V295.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V295.Id.Id Evergreen.V295.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V295.Id.Id Evergreen.V295.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V295.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V295.FileStatus.FileHash
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V295.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V295.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V295.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.StickerId) Evergreen.V295.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.CustomEmojiId) Evergreen.V295.CustomEmoji.CustomEmojiData
    }
