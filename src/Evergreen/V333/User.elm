module Evergreen.V333.User exposing (..)

import Effect.Time
import Evergreen.V333.CustomEmoji
import Evergreen.V333.Discord
import Evergreen.V333.EmailAddress
import Evergreen.V333.Emoji
import Evergreen.V333.FileStatus
import Evergreen.V333.Id
import Evergreen.V333.LinkedAndOtherDiscordUsers
import Evergreen.V333.NonemptyDict
import Evergreen.V333.OneOrGreater
import Evergreen.V333.Pagination
import Evergreen.V333.PersonName
import Evergreen.V333.RichText
import Evergreen.V333.Sticker
import Evergreen.V333.UserAgent
import Evergreen.V333.UserSession
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
    = DmChannelLastViewed (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) Evergreen.V333.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V333.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V333.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V333.Id.Id Evergreen.V333.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V333.Id.AnyGuildOrDmId (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V333.Id.AnyGuildOrDmId, Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId ) (Evergreen.V333.Id.Id Evergreen.V333.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) ( Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelId, Evergreen.V333.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) ( Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId, Evergreen.V333.Id.ThreadRoute )
    , icon : Maybe Evergreen.V333.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) (Evergreen.V333.NonemptyDict.NonemptyDict ( Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelId, Evergreen.V333.Id.ThreadRoute ) Evergreen.V333.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.NonemptyDict.NonemptyDict ( Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId, Evergreen.V333.Id.ThreadRoute ) Evergreen.V333.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V333.RichText.Domain
    , emojiConfig : Evergreen.V333.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V333.Id.Id Evergreen.V333.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V333.Id.Id Evergreen.V333.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V333.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V333.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V333.UserSession.UserSession
    , currentlyViewing : Evergreen.V333.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V333.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V333.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.StickerId) Evergreen.V333.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.CustomEmojiId) Evergreen.V333.CustomEmoji.CustomEmojiData
    }
