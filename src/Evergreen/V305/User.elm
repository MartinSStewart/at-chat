module Evergreen.V305.User exposing (..)

import Effect.Time
import Evergreen.V305.CustomEmoji
import Evergreen.V305.Discord
import Evergreen.V305.EmailAddress
import Evergreen.V305.Emoji
import Evergreen.V305.FileStatus
import Evergreen.V305.Id
import Evergreen.V305.LinkedAndOtherDiscordUsers
import Evergreen.V305.NonemptyDict
import Evergreen.V305.OneOrGreater
import Evergreen.V305.Pagination
import Evergreen.V305.PersonName
import Evergreen.V305.RichText
import Evergreen.V305.Sticker
import Evergreen.V305.UserAgent
import Evergreen.V305.UserSession
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
    = DmChannelLastViewed (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId) Evergreen.V305.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V305.Discord.Id Evergreen.V305.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V305.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V305.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V305.Id.Id Evergreen.V305.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V305.Id.AnyGuildOrDmId (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V305.Id.AnyGuildOrDmId, Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId ) (Evergreen.V305.Id.Id Evergreen.V305.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.GuildId) ( Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelId, Evergreen.V305.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V305.Discord.Id Evergreen.V305.Discord.GuildId) ( Evergreen.V305.Discord.Id Evergreen.V305.Discord.ChannelId, Evergreen.V305.Id.ThreadRoute )
    , icon : Maybe Evergreen.V305.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V305.Id.Id Evergreen.V305.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V305.Discord.Id Evergreen.V305.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.GuildId) (Evergreen.V305.NonemptyDict.NonemptyDict ( Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelId, Evergreen.V305.Id.ThreadRoute ) Evergreen.V305.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V305.Discord.Id Evergreen.V305.Discord.GuildId) (Evergreen.V305.NonemptyDict.NonemptyDict ( Evergreen.V305.Discord.Id Evergreen.V305.Discord.ChannelId, Evergreen.V305.Id.ThreadRoute ) Evergreen.V305.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V305.Id.Id Evergreen.V305.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V305.Discord.Id Evergreen.V305.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V305.RichText.Domain
    , emojiConfig : Evergreen.V305.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V305.Id.Id Evergreen.V305.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V305.Id.Id Evergreen.V305.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V305.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V305.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V305.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V305.Id.AnyGuildOrDmId, Evergreen.V305.Id.ThreadRoute )
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V305.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V305.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.StickerId) Evergreen.V305.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.CustomEmojiId) Evergreen.V305.CustomEmoji.CustomEmojiData
    }
