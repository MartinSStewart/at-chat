module Evergreen.V299.User exposing (..)

import Effect.Time
import Evergreen.V299.CustomEmoji
import Evergreen.V299.Discord
import Evergreen.V299.EmailAddress
import Evergreen.V299.Emoji
import Evergreen.V299.FileStatus
import Evergreen.V299.Id
import Evergreen.V299.LinkedAndOtherDiscordUsers
import Evergreen.V299.NonemptyDict
import Evergreen.V299.OneOrGreater
import Evergreen.V299.Pagination
import Evergreen.V299.PersonName
import Evergreen.V299.RichText
import Evergreen.V299.Sticker
import Evergreen.V299.UserAgent
import Evergreen.V299.UserSession
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
    = NeverNotifyMe
    | NotifyMeWhenMentioned


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) Evergreen.V299.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V299.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V299.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V299.Id.Id Evergreen.V299.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V299.Id.AnyGuildOrDmId (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V299.Id.AnyGuildOrDmId, Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId ) (Evergreen.V299.Id.Id Evergreen.V299.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) ( Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelId, Evergreen.V299.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) ( Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId, Evergreen.V299.Id.ThreadRoute )
    , icon : Maybe Evergreen.V299.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) (Evergreen.V299.NonemptyDict.NonemptyDict ( Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelId, Evergreen.V299.Id.ThreadRoute ) Evergreen.V299.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.NonemptyDict.NonemptyDict ( Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId, Evergreen.V299.Id.ThreadRoute ) Evergreen.V299.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V299.RichText.Domain
    , emojiConfig : Evergreen.V299.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V299.Id.Id Evergreen.V299.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V299.Id.Id Evergreen.V299.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V299.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V299.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V299.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V299.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V299.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.StickerId) Evergreen.V299.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.CustomEmojiId) Evergreen.V299.CustomEmoji.CustomEmojiData
    }
