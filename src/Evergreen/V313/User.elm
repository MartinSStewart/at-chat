module Evergreen.V313.User exposing (..)

import Effect.Time
import Evergreen.V313.CustomEmoji
import Evergreen.V313.Discord
import Evergreen.V313.EmailAddress
import Evergreen.V313.Emoji
import Evergreen.V313.FileStatus
import Evergreen.V313.Id
import Evergreen.V313.LinkedAndOtherDiscordUsers
import Evergreen.V313.NonemptyDict
import Evergreen.V313.OneOrGreater
import Evergreen.V313.Pagination
import Evergreen.V313.PersonName
import Evergreen.V313.RichText
import Evergreen.V313.Sticker
import Evergreen.V313.UserAgent
import Evergreen.V313.UserSession
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
    = DmChannelLastViewed (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) Evergreen.V313.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V313.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V313.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V313.Id.Id Evergreen.V313.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V313.Id.AnyGuildOrDmId (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V313.Id.AnyGuildOrDmId, Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId ) (Evergreen.V313.Id.Id Evergreen.V313.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) ( Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelId, Evergreen.V313.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) ( Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId, Evergreen.V313.Id.ThreadRoute )
    , icon : Maybe Evergreen.V313.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) (Evergreen.V313.NonemptyDict.NonemptyDict ( Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelId, Evergreen.V313.Id.ThreadRoute ) Evergreen.V313.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.NonemptyDict.NonemptyDict ( Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId, Evergreen.V313.Id.ThreadRoute ) Evergreen.V313.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V313.RichText.Domain
    , emojiConfig : Evergreen.V313.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V313.Id.Id Evergreen.V313.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V313.Id.Id Evergreen.V313.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V313.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V313.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V313.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V313.Id.AnyGuildOrDmId, Evergreen.V313.Id.ThreadRoute )
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V313.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V313.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.StickerId) Evergreen.V313.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.CustomEmojiId) Evergreen.V313.CustomEmoji.CustomEmojiData
    }
