module Evergreen.V294.User exposing (..)

import Effect.Time
import Evergreen.V294.CustomEmoji
import Evergreen.V294.Discord
import Evergreen.V294.EmailAddress
import Evergreen.V294.Emoji
import Evergreen.V294.FileStatus
import Evergreen.V294.Id
import Evergreen.V294.LinkedAndOtherDiscordUsers
import Evergreen.V294.NonemptyDict
import Evergreen.V294.OneOrGreater
import Evergreen.V294.Pagination
import Evergreen.V294.PersonName
import Evergreen.V294.RichText
import Evergreen.V294.Sticker
import Evergreen.V294.UserAgent
import Evergreen.V294.UserSession
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
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) Evergreen.V294.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V294.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V294.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V294.Id.Id Evergreen.V294.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V294.Id.AnyGuildOrDmId (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V294.Id.AnyGuildOrDmId, Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId ) (Evergreen.V294.Id.Id Evergreen.V294.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) ( Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelId, Evergreen.V294.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) ( Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId, Evergreen.V294.Id.ThreadRoute )
    , icon : Maybe Evergreen.V294.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) (Evergreen.V294.NonemptyDict.NonemptyDict ( Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelId, Evergreen.V294.Id.ThreadRoute ) Evergreen.V294.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.NonemptyDict.NonemptyDict ( Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId, Evergreen.V294.Id.ThreadRoute ) Evergreen.V294.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V294.RichText.Domain
    , emojiConfig : Evergreen.V294.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V294.Id.Id Evergreen.V294.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V294.Id.Id Evergreen.V294.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V294.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V294.FileStatus.FileHash
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V294.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V294.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V294.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.StickerId) Evergreen.V294.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.CustomEmojiId) Evergreen.V294.CustomEmoji.CustomEmojiData
    }
