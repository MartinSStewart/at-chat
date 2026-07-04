module Evergreen.V302.User exposing (..)

import Effect.Time
import Evergreen.V302.CustomEmoji
import Evergreen.V302.Discord
import Evergreen.V302.EmailAddress
import Evergreen.V302.Emoji
import Evergreen.V302.FileStatus
import Evergreen.V302.Id
import Evergreen.V302.LinkedAndOtherDiscordUsers
import Evergreen.V302.NonemptyDict
import Evergreen.V302.OneOrGreater
import Evergreen.V302.Pagination
import Evergreen.V302.PersonName
import Evergreen.V302.RichText
import Evergreen.V302.Sticker
import Evergreen.V302.UserAgent
import Evergreen.V302.UserSession
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
    = DmChannelLastViewed (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) Evergreen.V302.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V302.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V302.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V302.Id.Id Evergreen.V302.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V302.Id.AnyGuildOrDmId (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V302.Id.AnyGuildOrDmId, Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId ) (Evergreen.V302.Id.Id Evergreen.V302.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) ( Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelId, Evergreen.V302.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) ( Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId, Evergreen.V302.Id.ThreadRoute )
    , icon : Maybe Evergreen.V302.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) (Evergreen.V302.NonemptyDict.NonemptyDict ( Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelId, Evergreen.V302.Id.ThreadRoute ) Evergreen.V302.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.NonemptyDict.NonemptyDict ( Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId, Evergreen.V302.Id.ThreadRoute ) Evergreen.V302.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V302.RichText.Domain
    , emojiConfig : Evergreen.V302.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V302.Id.Id Evergreen.V302.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V302.Id.Id Evergreen.V302.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V302.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V302.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V302.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V302.Id.AnyGuildOrDmId, Evergreen.V302.Id.ThreadRoute )
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V302.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V302.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.StickerId) Evergreen.V302.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.CustomEmojiId) Evergreen.V302.CustomEmoji.CustomEmojiData
    }
