module Evergreen.V319.User exposing (..)

import Effect.Time
import Evergreen.V319.CustomEmoji
import Evergreen.V319.Discord
import Evergreen.V319.EmailAddress
import Evergreen.V319.Emoji
import Evergreen.V319.FileStatus
import Evergreen.V319.Id
import Evergreen.V319.LinkedAndOtherDiscordUsers
import Evergreen.V319.NonemptyDict
import Evergreen.V319.OneOrGreater
import Evergreen.V319.Pagination
import Evergreen.V319.PersonName
import Evergreen.V319.RichText
import Evergreen.V319.Sticker
import Evergreen.V319.UserAgent
import Evergreen.V319.UserSession
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
    = DmChannelLastViewed (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) Evergreen.V319.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V319.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V319.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V319.Id.Id Evergreen.V319.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V319.Id.AnyGuildOrDmId (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V319.Id.AnyGuildOrDmId, Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId ) (Evergreen.V319.Id.Id Evergreen.V319.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) ( Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelId, Evergreen.V319.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) ( Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId, Evergreen.V319.Id.ThreadRoute )
    , icon : Maybe Evergreen.V319.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) (Evergreen.V319.NonemptyDict.NonemptyDict ( Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelId, Evergreen.V319.Id.ThreadRoute ) Evergreen.V319.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.NonemptyDict.NonemptyDict ( Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId, Evergreen.V319.Id.ThreadRoute ) Evergreen.V319.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V319.RichText.Domain
    , emojiConfig : Evergreen.V319.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V319.Id.Id Evergreen.V319.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V319.Id.Id Evergreen.V319.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V319.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V319.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V319.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V319.Id.AnyGuildOrDmId, Evergreen.V319.Id.ThreadRoute )
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V319.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V319.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.StickerId) Evergreen.V319.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.CustomEmojiId) Evergreen.V319.CustomEmoji.CustomEmojiData
    }
