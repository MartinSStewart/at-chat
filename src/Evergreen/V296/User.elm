module Evergreen.V296.User exposing (..)

import Effect.Time
import Evergreen.V296.CustomEmoji
import Evergreen.V296.Discord
import Evergreen.V296.EmailAddress
import Evergreen.V296.Emoji
import Evergreen.V296.FileStatus
import Evergreen.V296.Id
import Evergreen.V296.LinkedAndOtherDiscordUsers
import Evergreen.V296.NonemptyDict
import Evergreen.V296.OneOrGreater
import Evergreen.V296.Pagination
import Evergreen.V296.PersonName
import Evergreen.V296.RichText
import Evergreen.V296.Sticker
import Evergreen.V296.UserAgent
import Evergreen.V296.UserSession
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
    = DmChannelLastViewed (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) Evergreen.V296.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V296.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V296.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V296.Id.Id Evergreen.V296.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V296.Id.AnyGuildOrDmId (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V296.Id.AnyGuildOrDmId, Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId ) (Evergreen.V296.Id.Id Evergreen.V296.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) ( Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelId, Evergreen.V296.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) ( Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId, Evergreen.V296.Id.ThreadRoute )
    , icon : Maybe Evergreen.V296.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) (Evergreen.V296.NonemptyDict.NonemptyDict ( Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelId, Evergreen.V296.Id.ThreadRoute ) Evergreen.V296.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.NonemptyDict.NonemptyDict ( Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId, Evergreen.V296.Id.ThreadRoute ) Evergreen.V296.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V296.RichText.Domain
    , emojiConfig : Evergreen.V296.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V296.Id.Id Evergreen.V296.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V296.Id.Id Evergreen.V296.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V296.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V296.FileStatus.FileHash
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V296.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V296.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V296.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.StickerId) Evergreen.V296.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.CustomEmojiId) Evergreen.V296.CustomEmoji.CustomEmojiData
    }
