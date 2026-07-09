module Evergreen.V308.User exposing (..)

import Effect.Time
import Evergreen.V308.CustomEmoji
import Evergreen.V308.Discord
import Evergreen.V308.EmailAddress
import Evergreen.V308.Emoji
import Evergreen.V308.FileStatus
import Evergreen.V308.Id
import Evergreen.V308.LinkedAndOtherDiscordUsers
import Evergreen.V308.NonemptyDict
import Evergreen.V308.OneOrGreater
import Evergreen.V308.Pagination
import Evergreen.V308.PersonName
import Evergreen.V308.RichText
import Evergreen.V308.Sticker
import Evergreen.V308.UserAgent
import Evergreen.V308.UserSession
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
    = DmChannelLastViewed (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) Evergreen.V308.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V308.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V308.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V308.Id.Id Evergreen.V308.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V308.Id.AnyGuildOrDmId (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V308.Id.AnyGuildOrDmId, Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId ) (Evergreen.V308.Id.Id Evergreen.V308.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) ( Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelId, Evergreen.V308.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) ( Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId, Evergreen.V308.Id.ThreadRoute )
    , icon : Maybe Evergreen.V308.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) (Evergreen.V308.NonemptyDict.NonemptyDict ( Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelId, Evergreen.V308.Id.ThreadRoute ) Evergreen.V308.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.NonemptyDict.NonemptyDict ( Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId, Evergreen.V308.Id.ThreadRoute ) Evergreen.V308.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V308.RichText.Domain
    , emojiConfig : Evergreen.V308.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V308.Id.Id Evergreen.V308.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V308.Id.Id Evergreen.V308.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V308.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V308.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V308.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V308.Id.AnyGuildOrDmId, Evergreen.V308.Id.ThreadRoute )
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V308.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V308.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.StickerId) Evergreen.V308.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.CustomEmojiId) Evergreen.V308.CustomEmoji.CustomEmojiData
    }
