module Evergreen.V316.User exposing (..)

import Effect.Time
import Evergreen.V316.CustomEmoji
import Evergreen.V316.Discord
import Evergreen.V316.EmailAddress
import Evergreen.V316.Emoji
import Evergreen.V316.FileStatus
import Evergreen.V316.Id
import Evergreen.V316.LinkedAndOtherDiscordUsers
import Evergreen.V316.NonemptyDict
import Evergreen.V316.OneOrGreater
import Evergreen.V316.Pagination
import Evergreen.V316.PersonName
import Evergreen.V316.RichText
import Evergreen.V316.Sticker
import Evergreen.V316.UserAgent
import Evergreen.V316.UserSession
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
    = DmChannelLastViewed (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) Evergreen.V316.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V316.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V316.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V316.Id.Id Evergreen.V316.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V316.Id.AnyGuildOrDmId (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V316.Id.AnyGuildOrDmId, Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId ) (Evergreen.V316.Id.Id Evergreen.V316.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) ( Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelId, Evergreen.V316.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) ( Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId, Evergreen.V316.Id.ThreadRoute )
    , icon : Maybe Evergreen.V316.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) (Evergreen.V316.NonemptyDict.NonemptyDict ( Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelId, Evergreen.V316.Id.ThreadRoute ) Evergreen.V316.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.NonemptyDict.NonemptyDict ( Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId, Evergreen.V316.Id.ThreadRoute ) Evergreen.V316.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V316.RichText.Domain
    , emojiConfig : Evergreen.V316.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V316.Id.Id Evergreen.V316.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V316.Id.Id Evergreen.V316.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V316.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V316.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V316.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V316.Id.AnyGuildOrDmId, Evergreen.V316.Id.ThreadRoute )
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V316.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V316.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.StickerId) Evergreen.V316.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.CustomEmojiId) Evergreen.V316.CustomEmoji.CustomEmojiData
    }
