module Evergreen.V323.User exposing (..)

import Effect.Time
import Evergreen.V323.CustomEmoji
import Evergreen.V323.Discord
import Evergreen.V323.EmailAddress
import Evergreen.V323.Emoji
import Evergreen.V323.FileStatus
import Evergreen.V323.Id
import Evergreen.V323.LinkedAndOtherDiscordUsers
import Evergreen.V323.NonemptyDict
import Evergreen.V323.OneOrGreater
import Evergreen.V323.Pagination
import Evergreen.V323.PersonName
import Evergreen.V323.RichText
import Evergreen.V323.Sticker
import Evergreen.V323.UserAgent
import Evergreen.V323.UserSession
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
    = DmChannelLastViewed (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) Evergreen.V323.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V323.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V323.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V323.Id.Id Evergreen.V323.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V323.Id.AnyGuildOrDmId (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V323.Id.AnyGuildOrDmId, Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId ) (Evergreen.V323.Id.Id Evergreen.V323.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) ( Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelId, Evergreen.V323.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) ( Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId, Evergreen.V323.Id.ThreadRoute )
    , icon : Maybe Evergreen.V323.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) (Evergreen.V323.NonemptyDict.NonemptyDict ( Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelId, Evergreen.V323.Id.ThreadRoute ) Evergreen.V323.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.NonemptyDict.NonemptyDict ( Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId, Evergreen.V323.Id.ThreadRoute ) Evergreen.V323.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V323.RichText.Domain
    , emojiConfig : Evergreen.V323.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V323.Id.Id Evergreen.V323.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V323.Id.Id Evergreen.V323.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V323.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V323.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V323.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V323.Id.AnyGuildOrDmId, Evergreen.V323.Id.ThreadRoute )
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V323.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V323.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.StickerId) Evergreen.V323.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.CustomEmojiId) Evergreen.V323.CustomEmoji.CustomEmojiData
    }
