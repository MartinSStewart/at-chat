module Evergreen.V309.User exposing (..)

import Effect.Time
import Evergreen.V309.CustomEmoji
import Evergreen.V309.Discord
import Evergreen.V309.EmailAddress
import Evergreen.V309.Emoji
import Evergreen.V309.FileStatus
import Evergreen.V309.Id
import Evergreen.V309.LinkedAndOtherDiscordUsers
import Evergreen.V309.NonemptyDict
import Evergreen.V309.OneOrGreater
import Evergreen.V309.Pagination
import Evergreen.V309.PersonName
import Evergreen.V309.RichText
import Evergreen.V309.Sticker
import Evergreen.V309.UserAgent
import Evergreen.V309.UserSession
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
    = DmChannelLastViewed (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) Evergreen.V309.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V309.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V309.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V309.Id.Id Evergreen.V309.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V309.Id.AnyGuildOrDmId (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V309.Id.AnyGuildOrDmId, Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId ) (Evergreen.V309.Id.Id Evergreen.V309.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) ( Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelId, Evergreen.V309.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) ( Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId, Evergreen.V309.Id.ThreadRoute )
    , icon : Maybe Evergreen.V309.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) (Evergreen.V309.NonemptyDict.NonemptyDict ( Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelId, Evergreen.V309.Id.ThreadRoute ) Evergreen.V309.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.NonemptyDict.NonemptyDict ( Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId, Evergreen.V309.Id.ThreadRoute ) Evergreen.V309.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V309.RichText.Domain
    , emojiConfig : Evergreen.V309.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V309.Id.Id Evergreen.V309.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V309.Id.Id Evergreen.V309.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V309.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V309.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V309.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V309.Id.AnyGuildOrDmId, Evergreen.V309.Id.ThreadRoute )
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V309.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V309.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.StickerId) Evergreen.V309.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.CustomEmojiId) Evergreen.V309.CustomEmoji.CustomEmojiData
    }
