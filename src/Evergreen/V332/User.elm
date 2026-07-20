module Evergreen.V332.User exposing (..)

import Effect.Time
import Evergreen.V332.CustomEmoji
import Evergreen.V332.Discord
import Evergreen.V332.EmailAddress
import Evergreen.V332.Emoji
import Evergreen.V332.FileStatus
import Evergreen.V332.Id
import Evergreen.V332.LinkedAndOtherDiscordUsers
import Evergreen.V332.NonemptyDict
import Evergreen.V332.OneOrGreater
import Evergreen.V332.Pagination
import Evergreen.V332.PersonName
import Evergreen.V332.RichText
import Evergreen.V332.Sticker
import Evergreen.V332.UserAgent
import Evergreen.V332.UserSession
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
    = DmChannelLastViewed (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) Evergreen.V332.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V332.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V332.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V332.Id.Id Evergreen.V332.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V332.Id.AnyGuildOrDmId (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V332.Id.AnyGuildOrDmId, Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId ) (Evergreen.V332.Id.Id Evergreen.V332.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) ( Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelId, Evergreen.V332.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) ( Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId, Evergreen.V332.Id.ThreadRoute )
    , icon : Maybe Evergreen.V332.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) (Evergreen.V332.NonemptyDict.NonemptyDict ( Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelId, Evergreen.V332.Id.ThreadRoute ) Evergreen.V332.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.NonemptyDict.NonemptyDict ( Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId, Evergreen.V332.Id.ThreadRoute ) Evergreen.V332.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V332.RichText.Domain
    , emojiConfig : Evergreen.V332.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V332.Id.Id Evergreen.V332.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V332.Id.Id Evergreen.V332.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V332.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V332.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V332.UserSession.UserSession
    , currentlyViewing : Evergreen.V332.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V332.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V332.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.StickerId) Evergreen.V332.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.CustomEmojiId) Evergreen.V332.CustomEmoji.CustomEmojiData
    }
