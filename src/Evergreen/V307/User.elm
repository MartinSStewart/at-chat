module Evergreen.V307.User exposing (..)

import Effect.Time
import Evergreen.V307.CustomEmoji
import Evergreen.V307.Discord
import Evergreen.V307.EmailAddress
import Evergreen.V307.Emoji
import Evergreen.V307.FileStatus
import Evergreen.V307.Id
import Evergreen.V307.LinkedAndOtherDiscordUsers
import Evergreen.V307.NonemptyDict
import Evergreen.V307.OneOrGreater
import Evergreen.V307.Pagination
import Evergreen.V307.PersonName
import Evergreen.V307.RichText
import Evergreen.V307.Sticker
import Evergreen.V307.UserAgent
import Evergreen.V307.UserSession
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
    = DmChannelLastViewed (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) Evergreen.V307.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V307.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V307.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V307.Id.Id Evergreen.V307.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V307.Id.AnyGuildOrDmId (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V307.Id.AnyGuildOrDmId, Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId ) (Evergreen.V307.Id.Id Evergreen.V307.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) ( Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelId, Evergreen.V307.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) ( Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId, Evergreen.V307.Id.ThreadRoute )
    , icon : Maybe Evergreen.V307.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) (Evergreen.V307.NonemptyDict.NonemptyDict ( Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelId, Evergreen.V307.Id.ThreadRoute ) Evergreen.V307.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.NonemptyDict.NonemptyDict ( Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId, Evergreen.V307.Id.ThreadRoute ) Evergreen.V307.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V307.RichText.Domain
    , emojiConfig : Evergreen.V307.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V307.Id.Id Evergreen.V307.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V307.Id.Id Evergreen.V307.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V307.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V307.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V307.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V307.Id.AnyGuildOrDmId, Evergreen.V307.Id.ThreadRoute )
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V307.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V307.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.StickerId) Evergreen.V307.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.CustomEmojiId) Evergreen.V307.CustomEmoji.CustomEmojiData
    }
