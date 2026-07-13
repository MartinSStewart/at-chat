module Evergreen.V317.User exposing (..)

import Effect.Time
import Evergreen.V317.CustomEmoji
import Evergreen.V317.Discord
import Evergreen.V317.EmailAddress
import Evergreen.V317.Emoji
import Evergreen.V317.FileStatus
import Evergreen.V317.Id
import Evergreen.V317.LinkedAndOtherDiscordUsers
import Evergreen.V317.NonemptyDict
import Evergreen.V317.OneOrGreater
import Evergreen.V317.Pagination
import Evergreen.V317.PersonName
import Evergreen.V317.RichText
import Evergreen.V317.Sticker
import Evergreen.V317.UserAgent
import Evergreen.V317.UserSession
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
    = DmChannelLastViewed (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) Evergreen.V317.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V317.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V317.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V317.Id.Id Evergreen.V317.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V317.Id.AnyGuildOrDmId (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V317.Id.AnyGuildOrDmId, Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId ) (Evergreen.V317.Id.Id Evergreen.V317.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) ( Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelId, Evergreen.V317.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) ( Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId, Evergreen.V317.Id.ThreadRoute )
    , icon : Maybe Evergreen.V317.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) (Evergreen.V317.NonemptyDict.NonemptyDict ( Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelId, Evergreen.V317.Id.ThreadRoute ) Evergreen.V317.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.NonemptyDict.NonemptyDict ( Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId, Evergreen.V317.Id.ThreadRoute ) Evergreen.V317.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V317.RichText.Domain
    , emojiConfig : Evergreen.V317.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V317.Id.Id Evergreen.V317.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V317.Id.Id Evergreen.V317.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V317.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V317.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V317.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V317.Id.AnyGuildOrDmId, Evergreen.V317.Id.ThreadRoute )
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V317.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V317.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.StickerId) Evergreen.V317.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.CustomEmojiId) Evergreen.V317.CustomEmoji.CustomEmojiData
    }
