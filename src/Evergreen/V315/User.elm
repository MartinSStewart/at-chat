module Evergreen.V315.User exposing (..)

import Effect.Time
import Evergreen.V315.CustomEmoji
import Evergreen.V315.Discord
import Evergreen.V315.EmailAddress
import Evergreen.V315.Emoji
import Evergreen.V315.FileStatus
import Evergreen.V315.Id
import Evergreen.V315.LinkedAndOtherDiscordUsers
import Evergreen.V315.NonemptyDict
import Evergreen.V315.OneOrGreater
import Evergreen.V315.Pagination
import Evergreen.V315.PersonName
import Evergreen.V315.RichText
import Evergreen.V315.Sticker
import Evergreen.V315.UserAgent
import Evergreen.V315.UserSession
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
    = DmChannelLastViewed (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) Evergreen.V315.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V315.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V315.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V315.Id.Id Evergreen.V315.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V315.Id.AnyGuildOrDmId (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V315.Id.AnyGuildOrDmId, Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId ) (Evergreen.V315.Id.Id Evergreen.V315.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) ( Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelId, Evergreen.V315.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) ( Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId, Evergreen.V315.Id.ThreadRoute )
    , icon : Maybe Evergreen.V315.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) (Evergreen.V315.NonemptyDict.NonemptyDict ( Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelId, Evergreen.V315.Id.ThreadRoute ) Evergreen.V315.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.NonemptyDict.NonemptyDict ( Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId, Evergreen.V315.Id.ThreadRoute ) Evergreen.V315.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V315.RichText.Domain
    , emojiConfig : Evergreen.V315.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V315.Id.Id Evergreen.V315.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V315.Id.Id Evergreen.V315.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V315.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V315.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V315.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V315.Id.AnyGuildOrDmId, Evergreen.V315.Id.ThreadRoute )
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V315.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V315.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.StickerId) Evergreen.V315.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.CustomEmojiId) Evergreen.V315.CustomEmoji.CustomEmojiData
    }
