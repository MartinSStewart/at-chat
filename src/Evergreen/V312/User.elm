module Evergreen.V312.User exposing (..)

import Effect.Time
import Evergreen.V312.CustomEmoji
import Evergreen.V312.Discord
import Evergreen.V312.EmailAddress
import Evergreen.V312.Emoji
import Evergreen.V312.FileStatus
import Evergreen.V312.Id
import Evergreen.V312.LinkedAndOtherDiscordUsers
import Evergreen.V312.NonemptyDict
import Evergreen.V312.OneOrGreater
import Evergreen.V312.Pagination
import Evergreen.V312.PersonName
import Evergreen.V312.RichText
import Evergreen.V312.Sticker
import Evergreen.V312.UserAgent
import Evergreen.V312.UserSession
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
    = DmChannelLastViewed (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) Evergreen.V312.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V312.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V312.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V312.Id.Id Evergreen.V312.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V312.Id.AnyGuildOrDmId (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V312.Id.AnyGuildOrDmId, Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId ) (Evergreen.V312.Id.Id Evergreen.V312.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) ( Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelId, Evergreen.V312.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) ( Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId, Evergreen.V312.Id.ThreadRoute )
    , icon : Maybe Evergreen.V312.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) (Evergreen.V312.NonemptyDict.NonemptyDict ( Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelId, Evergreen.V312.Id.ThreadRoute ) Evergreen.V312.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.NonemptyDict.NonemptyDict ( Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId, Evergreen.V312.Id.ThreadRoute ) Evergreen.V312.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V312.RichText.Domain
    , emojiConfig : Evergreen.V312.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V312.Id.Id Evergreen.V312.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V312.Id.Id Evergreen.V312.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V312.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V312.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V312.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V312.Id.AnyGuildOrDmId, Evergreen.V312.Id.ThreadRoute )
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V312.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V312.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.StickerId) Evergreen.V312.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.CustomEmojiId) Evergreen.V312.CustomEmoji.CustomEmojiData
    }
