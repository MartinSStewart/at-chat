module Evergreen.V326.User exposing (..)

import Effect.Time
import Evergreen.V326.CustomEmoji
import Evergreen.V326.Discord
import Evergreen.V326.EmailAddress
import Evergreen.V326.Emoji
import Evergreen.V326.FileStatus
import Evergreen.V326.Id
import Evergreen.V326.LinkedAndOtherDiscordUsers
import Evergreen.V326.NonemptyDict
import Evergreen.V326.OneOrGreater
import Evergreen.V326.Pagination
import Evergreen.V326.PersonName
import Evergreen.V326.RichText
import Evergreen.V326.Sticker
import Evergreen.V326.UserAgent
import Evergreen.V326.UserSession
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
    = DmChannelLastViewed (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) Evergreen.V326.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V326.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V326.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V326.Id.Id Evergreen.V326.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V326.Id.AnyGuildOrDmId (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V326.Id.AnyGuildOrDmId, Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId ) (Evergreen.V326.Id.Id Evergreen.V326.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) ( Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelId, Evergreen.V326.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) ( Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId, Evergreen.V326.Id.ThreadRoute )
    , icon : Maybe Evergreen.V326.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) (Evergreen.V326.NonemptyDict.NonemptyDict ( Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelId, Evergreen.V326.Id.ThreadRoute ) Evergreen.V326.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.NonemptyDict.NonemptyDict ( Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId, Evergreen.V326.Id.ThreadRoute ) Evergreen.V326.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V326.RichText.Domain
    , emojiConfig : Evergreen.V326.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V326.Id.Id Evergreen.V326.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V326.Id.Id Evergreen.V326.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V326.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V326.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V326.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V326.Id.AnyGuildOrDmId, Evergreen.V326.Id.ThreadRoute )
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V326.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V326.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.StickerId) Evergreen.V326.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.CustomEmojiId) Evergreen.V326.CustomEmoji.CustomEmojiData
    }
