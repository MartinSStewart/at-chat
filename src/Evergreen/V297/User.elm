module Evergreen.V297.User exposing (..)

import Effect.Time
import Evergreen.V297.CustomEmoji
import Evergreen.V297.Discord
import Evergreen.V297.EmailAddress
import Evergreen.V297.Emoji
import Evergreen.V297.FileStatus
import Evergreen.V297.Id
import Evergreen.V297.LinkedAndOtherDiscordUsers
import Evergreen.V297.NonemptyDict
import Evergreen.V297.OneOrGreater
import Evergreen.V297.Pagination
import Evergreen.V297.PersonName
import Evergreen.V297.RichText
import Evergreen.V297.Sticker
import Evergreen.V297.UserAgent
import Evergreen.V297.UserSession
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


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) Evergreen.V297.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V297.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V297.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V297.Id.Id Evergreen.V297.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V297.Id.AnyGuildOrDmId (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V297.Id.AnyGuildOrDmId, Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId ) (Evergreen.V297.Id.Id Evergreen.V297.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) ( Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelId, Evergreen.V297.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) ( Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId, Evergreen.V297.Id.ThreadRoute )
    , icon : Maybe Evergreen.V297.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) (Evergreen.V297.NonemptyDict.NonemptyDict ( Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelId, Evergreen.V297.Id.ThreadRoute ) Evergreen.V297.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.NonemptyDict.NonemptyDict ( Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId, Evergreen.V297.Id.ThreadRoute ) Evergreen.V297.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V297.RichText.Domain
    , emojiConfig : Evergreen.V297.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V297.Id.Id Evergreen.V297.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V297.Id.Id Evergreen.V297.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V297.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V297.FileStatus.FileHash
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V297.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V297.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V297.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.StickerId) Evergreen.V297.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.CustomEmojiId) Evergreen.V297.CustomEmoji.CustomEmojiData
    }
