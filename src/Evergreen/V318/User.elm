module Evergreen.V318.User exposing (..)

import Effect.Time
import Evergreen.V318.CustomEmoji
import Evergreen.V318.Discord
import Evergreen.V318.EmailAddress
import Evergreen.V318.Emoji
import Evergreen.V318.FileStatus
import Evergreen.V318.Id
import Evergreen.V318.LinkedAndOtherDiscordUsers
import Evergreen.V318.NonemptyDict
import Evergreen.V318.OneOrGreater
import Evergreen.V318.Pagination
import Evergreen.V318.PersonName
import Evergreen.V318.RichText
import Evergreen.V318.Sticker
import Evergreen.V318.UserAgent
import Evergreen.V318.UserSession
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
    = DmChannelLastViewed (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) Evergreen.V318.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V318.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V318.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V318.Id.Id Evergreen.V318.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V318.Id.AnyGuildOrDmId (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V318.Id.AnyGuildOrDmId, Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId ) (Evergreen.V318.Id.Id Evergreen.V318.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) ( Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelId, Evergreen.V318.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) ( Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId, Evergreen.V318.Id.ThreadRoute )
    , icon : Maybe Evergreen.V318.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) (Evergreen.V318.NonemptyDict.NonemptyDict ( Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelId, Evergreen.V318.Id.ThreadRoute ) Evergreen.V318.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.NonemptyDict.NonemptyDict ( Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId, Evergreen.V318.Id.ThreadRoute ) Evergreen.V318.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V318.RichText.Domain
    , emojiConfig : Evergreen.V318.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V318.Id.Id Evergreen.V318.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V318.Id.Id Evergreen.V318.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V318.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V318.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V318.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V318.Id.AnyGuildOrDmId, Evergreen.V318.Id.ThreadRoute )
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V318.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V318.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.StickerId) Evergreen.V318.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.CustomEmojiId) Evergreen.V318.CustomEmoji.CustomEmojiData
    }
