module Evergreen.V304.User exposing (..)

import Effect.Time
import Evergreen.V304.CustomEmoji
import Evergreen.V304.Discord
import Evergreen.V304.EmailAddress
import Evergreen.V304.Emoji
import Evergreen.V304.FileStatus
import Evergreen.V304.Id
import Evergreen.V304.LinkedAndOtherDiscordUsers
import Evergreen.V304.NonemptyDict
import Evergreen.V304.OneOrGreater
import Evergreen.V304.Pagination
import Evergreen.V304.PersonName
import Evergreen.V304.RichText
import Evergreen.V304.Sticker
import Evergreen.V304.UserAgent
import Evergreen.V304.UserSession
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
    = DmChannelLastViewed (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) Evergreen.V304.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V304.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V304.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V304.Id.Id Evergreen.V304.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V304.Id.AnyGuildOrDmId (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V304.Id.AnyGuildOrDmId, Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId ) (Evergreen.V304.Id.Id Evergreen.V304.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) ( Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelId, Evergreen.V304.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) ( Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId, Evergreen.V304.Id.ThreadRoute )
    , icon : Maybe Evergreen.V304.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) (Evergreen.V304.NonemptyDict.NonemptyDict ( Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelId, Evergreen.V304.Id.ThreadRoute ) Evergreen.V304.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.NonemptyDict.NonemptyDict ( Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId, Evergreen.V304.Id.ThreadRoute ) Evergreen.V304.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V304.RichText.Domain
    , emojiConfig : Evergreen.V304.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V304.Id.Id Evergreen.V304.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V304.Id.Id Evergreen.V304.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V304.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V304.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V304.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V304.Id.AnyGuildOrDmId, Evergreen.V304.Id.ThreadRoute )
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V304.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V304.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.StickerId) Evergreen.V304.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.CustomEmojiId) Evergreen.V304.CustomEmoji.CustomEmojiData
    }
