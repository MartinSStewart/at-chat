module Evergreen.V338.User exposing (..)

import Effect.Time
import Evergreen.V338.CustomEmoji
import Evergreen.V338.Discord
import Evergreen.V338.EmailAddress
import Evergreen.V338.Emoji
import Evergreen.V338.FileStatus
import Evergreen.V338.Id
import Evergreen.V338.LinkedAndOtherDiscordUsers
import Evergreen.V338.NonemptyDict
import Evergreen.V338.OneOrGreater
import Evergreen.V338.Pagination
import Evergreen.V338.PersonName
import Evergreen.V338.RichText
import Evergreen.V338.Sticker
import Evergreen.V338.UserAgent
import Evergreen.V338.UserSession
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
    = DmChannelLastViewed (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) Evergreen.V338.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V338.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V338.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V338.Id.Id Evergreen.V338.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V338.Id.AnyGuildOrDmId (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V338.Id.AnyGuildOrDmId, Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId ) (Evergreen.V338.Id.Id Evergreen.V338.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) ( Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelId, Evergreen.V338.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) ( Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId, Evergreen.V338.Id.ThreadRoute )
    , icon : Maybe Evergreen.V338.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) (Evergreen.V338.NonemptyDict.NonemptyDict ( Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelId, Evergreen.V338.Id.ThreadRoute ) Evergreen.V338.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.NonemptyDict.NonemptyDict ( Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId, Evergreen.V338.Id.ThreadRoute ) Evergreen.V338.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V338.RichText.Domain
    , emojiConfig : Evergreen.V338.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V338.Id.Id Evergreen.V338.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V338.Id.Id Evergreen.V338.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V338.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V338.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V338.UserSession.UserSession
    , currentlyViewing : Evergreen.V338.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V338.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V338.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.StickerId) Evergreen.V338.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.CustomEmojiId) Evergreen.V338.CustomEmoji.CustomEmojiData
    }
