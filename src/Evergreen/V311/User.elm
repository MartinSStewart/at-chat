module Evergreen.V311.User exposing (..)

import Effect.Time
import Evergreen.V311.CustomEmoji
import Evergreen.V311.Discord
import Evergreen.V311.EmailAddress
import Evergreen.V311.Emoji
import Evergreen.V311.FileStatus
import Evergreen.V311.Id
import Evergreen.V311.LinkedAndOtherDiscordUsers
import Evergreen.V311.NonemptyDict
import Evergreen.V311.OneOrGreater
import Evergreen.V311.Pagination
import Evergreen.V311.PersonName
import Evergreen.V311.RichText
import Evergreen.V311.Sticker
import Evergreen.V311.UserAgent
import Evergreen.V311.UserSession
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
    | WordSpellingGameSwedishSection


type EmailNotifications
    = NeverNotifyMe
    | NotifyMeWhenMentioned


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) Evergreen.V311.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V311.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V311.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V311.Id.Id Evergreen.V311.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V311.Id.AnyGuildOrDmId (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V311.Id.AnyGuildOrDmId, Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId ) (Evergreen.V311.Id.Id Evergreen.V311.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) ( Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelId, Evergreen.V311.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) ( Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId, Evergreen.V311.Id.ThreadRoute )
    , icon : Maybe Evergreen.V311.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) (Evergreen.V311.NonemptyDict.NonemptyDict ( Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelId, Evergreen.V311.Id.ThreadRoute ) Evergreen.V311.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.NonemptyDict.NonemptyDict ( Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId, Evergreen.V311.Id.ThreadRoute ) Evergreen.V311.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V311.RichText.Domain
    , emojiConfig : Evergreen.V311.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V311.Id.Id Evergreen.V311.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V311.Id.Id Evergreen.V311.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V311.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V311.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V311.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V311.Id.AnyGuildOrDmId, Evergreen.V311.Id.ThreadRoute )
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V311.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V311.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.StickerId) Evergreen.V311.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.CustomEmojiId) Evergreen.V311.CustomEmoji.CustomEmojiData
    }
