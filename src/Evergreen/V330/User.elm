module Evergreen.V330.User exposing (..)

import Effect.Time
import Evergreen.V330.CustomEmoji
import Evergreen.V330.Discord
import Evergreen.V330.EmailAddress
import Evergreen.V330.Emoji
import Evergreen.V330.FileStatus
import Evergreen.V330.Id
import Evergreen.V330.LinkedAndOtherDiscordUsers
import Evergreen.V330.NonemptyDict
import Evergreen.V330.OneOrGreater
import Evergreen.V330.Pagination
import Evergreen.V330.PersonName
import Evergreen.V330.RichText
import Evergreen.V330.Sticker
import Evergreen.V330.UserAgent
import Evergreen.V330.UserSession
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
    = DmChannelLastViewed (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) Evergreen.V330.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V330.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V330.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V330.Id.Id Evergreen.V330.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V330.Id.AnyGuildOrDmId (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V330.Id.AnyGuildOrDmId, Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId ) (Evergreen.V330.Id.Id Evergreen.V330.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) ( Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelId, Evergreen.V330.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) ( Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId, Evergreen.V330.Id.ThreadRoute )
    , icon : Maybe Evergreen.V330.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) (Evergreen.V330.NonemptyDict.NonemptyDict ( Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelId, Evergreen.V330.Id.ThreadRoute ) Evergreen.V330.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.NonemptyDict.NonemptyDict ( Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId, Evergreen.V330.Id.ThreadRoute ) Evergreen.V330.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V330.RichText.Domain
    , emojiConfig : Evergreen.V330.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V330.Id.Id Evergreen.V330.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V330.Id.Id Evergreen.V330.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V330.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V330.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V330.UserSession.UserSession
    , currentlyViewing : Evergreen.V330.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V330.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V330.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.StickerId) Evergreen.V330.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.CustomEmojiId) Evergreen.V330.CustomEmoji.CustomEmojiData
    }
