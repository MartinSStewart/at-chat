module Evergreen.V298.User exposing (..)

import Effect.Time
import Evergreen.V298.CustomEmoji
import Evergreen.V298.Discord
import Evergreen.V298.EmailAddress
import Evergreen.V298.Emoji
import Evergreen.V298.FileStatus
import Evergreen.V298.Id
import Evergreen.V298.LinkedAndOtherDiscordUsers
import Evergreen.V298.NonemptyDict
import Evergreen.V298.OneOrGreater
import Evergreen.V298.Pagination
import Evergreen.V298.PersonName
import Evergreen.V298.RichText
import Evergreen.V298.Sticker
import Evergreen.V298.UserAgent
import Evergreen.V298.UserSession
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
    = DmChannelLastViewed (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) Evergreen.V298.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V298.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V298.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V298.Id.Id Evergreen.V298.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V298.Id.AnyGuildOrDmId (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V298.Id.AnyGuildOrDmId, Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId ) (Evergreen.V298.Id.Id Evergreen.V298.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) ( Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelId, Evergreen.V298.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) ( Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId, Evergreen.V298.Id.ThreadRoute )
    , icon : Maybe Evergreen.V298.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) (Evergreen.V298.NonemptyDict.NonemptyDict ( Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelId, Evergreen.V298.Id.ThreadRoute ) Evergreen.V298.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId) (Evergreen.V298.NonemptyDict.NonemptyDict ( Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId, Evergreen.V298.Id.ThreadRoute ) Evergreen.V298.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V298.RichText.Domain
    , emojiConfig : Evergreen.V298.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V298.Id.Id Evergreen.V298.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V298.Id.Id Evergreen.V298.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V298.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V298.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V298.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V298.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V298.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.StickerId) Evergreen.V298.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.CustomEmojiId) Evergreen.V298.CustomEmoji.CustomEmojiData
    }
