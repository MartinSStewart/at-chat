module Evergreen.V293.User exposing (..)

import Effect.Time
import Evergreen.V293.CustomEmoji
import Evergreen.V293.Discord
import Evergreen.V293.EmailAddress
import Evergreen.V293.Emoji
import Evergreen.V293.FileStatus
import Evergreen.V293.Id
import Evergreen.V293.LinkedAndOtherDiscordUsers
import Evergreen.V293.NonemptyDict
import Evergreen.V293.OneOrGreater
import Evergreen.V293.Pagination
import Evergreen.V293.PersonName
import Evergreen.V293.RichText
import Evergreen.V293.Sticker
import Evergreen.V293.UserAgent
import Evergreen.V293.UserSession
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
    = DmChannelLastViewed (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) Evergreen.V293.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V293.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V293.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V293.Id.Id Evergreen.V293.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V293.Id.AnyGuildOrDmId (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V293.Id.AnyGuildOrDmId, Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId ) (Evergreen.V293.Id.Id Evergreen.V293.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) ( Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelId, Evergreen.V293.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) ( Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId, Evergreen.V293.Id.ThreadRoute )
    , icon : Maybe Evergreen.V293.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) (Evergreen.V293.NonemptyDict.NonemptyDict ( Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelId, Evergreen.V293.Id.ThreadRoute ) Evergreen.V293.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.NonemptyDict.NonemptyDict ( Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId, Evergreen.V293.Id.ThreadRoute ) Evergreen.V293.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V293.RichText.Domain
    , emojiConfig : Evergreen.V293.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V293.Id.Id Evergreen.V293.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V293.Id.Id Evergreen.V293.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V293.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V293.FileStatus.FileHash
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V293.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V293.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V293.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.StickerId) Evergreen.V293.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.CustomEmojiId) Evergreen.V293.CustomEmoji.CustomEmojiData
    }
