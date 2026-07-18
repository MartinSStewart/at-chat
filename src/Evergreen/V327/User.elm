module Evergreen.V327.User exposing (..)

import Effect.Time
import Evergreen.V327.CustomEmoji
import Evergreen.V327.Discord
import Evergreen.V327.EmailAddress
import Evergreen.V327.Emoji
import Evergreen.V327.FileStatus
import Evergreen.V327.Id
import Evergreen.V327.LinkedAndOtherDiscordUsers
import Evergreen.V327.NonemptyDict
import Evergreen.V327.OneOrGreater
import Evergreen.V327.Pagination
import Evergreen.V327.PersonName
import Evergreen.V327.RichText
import Evergreen.V327.Sticker
import Evergreen.V327.UserAgent
import Evergreen.V327.UserSession
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
    = DmChannelLastViewed (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) Evergreen.V327.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V327.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V327.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V327.Id.Id Evergreen.V327.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V327.Id.AnyGuildOrDmId (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V327.Id.AnyGuildOrDmId, Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId ) (Evergreen.V327.Id.Id Evergreen.V327.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) ( Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelId, Evergreen.V327.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) ( Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId, Evergreen.V327.Id.ThreadRoute )
    , icon : Maybe Evergreen.V327.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) (Evergreen.V327.NonemptyDict.NonemptyDict ( Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelId, Evergreen.V327.Id.ThreadRoute ) Evergreen.V327.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.NonemptyDict.NonemptyDict ( Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId, Evergreen.V327.Id.ThreadRoute ) Evergreen.V327.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V327.RichText.Domain
    , emojiConfig : Evergreen.V327.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V327.Id.Id Evergreen.V327.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V327.Id.Id Evergreen.V327.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V327.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V327.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V327.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V327.Id.AnyGuildOrDmId, Evergreen.V327.Id.ThreadRoute )
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V327.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V327.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.StickerId) Evergreen.V327.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.CustomEmojiId) Evergreen.V327.CustomEmoji.CustomEmojiData
    }
