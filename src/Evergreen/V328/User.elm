module Evergreen.V328.User exposing (..)

import Effect.Time
import Evergreen.V328.CustomEmoji
import Evergreen.V328.Discord
import Evergreen.V328.EmailAddress
import Evergreen.V328.Emoji
import Evergreen.V328.FileStatus
import Evergreen.V328.Id
import Evergreen.V328.LinkedAndOtherDiscordUsers
import Evergreen.V328.NonemptyDict
import Evergreen.V328.OneOrGreater
import Evergreen.V328.Pagination
import Evergreen.V328.PersonName
import Evergreen.V328.RichText
import Evergreen.V328.Sticker
import Evergreen.V328.UserAgent
import Evergreen.V328.UserSession
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
    = DmChannelLastViewed (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId) Evergreen.V328.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V328.Discord.Id Evergreen.V328.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V328.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V328.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V328.Id.Id Evergreen.V328.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V328.Id.AnyGuildOrDmId (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V328.Id.AnyGuildOrDmId, Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId ) (Evergreen.V328.Id.Id Evergreen.V328.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.GuildId) ( Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelId, Evergreen.V328.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V328.Discord.Id Evergreen.V328.Discord.GuildId) ( Evergreen.V328.Discord.Id Evergreen.V328.Discord.ChannelId, Evergreen.V328.Id.ThreadRoute )
    , icon : Maybe Evergreen.V328.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V328.Id.Id Evergreen.V328.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V328.Discord.Id Evergreen.V328.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.GuildId) (Evergreen.V328.NonemptyDict.NonemptyDict ( Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelId, Evergreen.V328.Id.ThreadRoute ) Evergreen.V328.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V328.Discord.Id Evergreen.V328.Discord.GuildId) (Evergreen.V328.NonemptyDict.NonemptyDict ( Evergreen.V328.Discord.Id Evergreen.V328.Discord.ChannelId, Evergreen.V328.Id.ThreadRoute ) Evergreen.V328.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V328.Id.Id Evergreen.V328.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V328.Discord.Id Evergreen.V328.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V328.RichText.Domain
    , emojiConfig : Evergreen.V328.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V328.Id.Id Evergreen.V328.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V328.Id.Id Evergreen.V328.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V328.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V328.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V328.UserSession.UserSession
    , currentlyViewing : Evergreen.V328.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V328.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V328.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.StickerId) Evergreen.V328.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.CustomEmojiId) Evergreen.V328.CustomEmoji.CustomEmojiData
    }
