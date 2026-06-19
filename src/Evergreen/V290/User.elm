module Evergreen.V290.User exposing (..)

import Effect.Time
import Evergreen.V290.CustomEmoji
import Evergreen.V290.Discord
import Evergreen.V290.EmailAddress
import Evergreen.V290.Emoji
import Evergreen.V290.FileStatus
import Evergreen.V290.Id
import Evergreen.V290.LinkedAndOtherDiscordUsers
import Evergreen.V290.NonemptyDict
import Evergreen.V290.OneOrGreater
import Evergreen.V290.Pagination
import Evergreen.V290.PersonName
import Evergreen.V290.RichText
import Evergreen.V290.Sticker
import Evergreen.V290.UserAgent
import Evergreen.V290.UserSession
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
    = DmChannelLastViewed (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) Evergreen.V290.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V290.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V290.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V290.Id.Id Evergreen.V290.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V290.Id.AnyGuildOrDmId (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V290.Id.AnyGuildOrDmId, Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId ) (Evergreen.V290.Id.Id Evergreen.V290.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) ( Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelId, Evergreen.V290.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) ( Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId, Evergreen.V290.Id.ThreadRoute )
    , icon : Maybe Evergreen.V290.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) (Evergreen.V290.NonemptyDict.NonemptyDict ( Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelId, Evergreen.V290.Id.ThreadRoute ) Evergreen.V290.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.NonemptyDict.NonemptyDict ( Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId, Evergreen.V290.Id.ThreadRoute ) Evergreen.V290.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V290.RichText.Domain
    , emojiConfig : Evergreen.V290.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V290.Id.Id Evergreen.V290.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V290.Id.Id Evergreen.V290.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V290.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V290.FileStatus.FileHash
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V290.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V290.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V290.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.StickerId) Evergreen.V290.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.CustomEmojiId) Evergreen.V290.CustomEmoji.CustomEmojiData
    }
