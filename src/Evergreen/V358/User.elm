module Evergreen.V358.User exposing (..)

import Effect.Time
import Evergreen.V358.CustomEmoji
import Evergreen.V358.Discord
import Evergreen.V358.EmailAddress
import Evergreen.V358.Emoji
import Evergreen.V358.FileStatus
import Evergreen.V358.Id
import Evergreen.V358.LinkedAndOtherDiscordUsers
import Evergreen.V358.MuteSettings
import Evergreen.V358.NonemptyDict
import Evergreen.V358.OneOrGreater
import Evergreen.V358.Pagination
import Evergreen.V358.PersonName
import Evergreen.V358.RichText
import Evergreen.V358.Sticker
import Evergreen.V358.UserAgent
import Evergreen.V358.UserSession
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
    | WebsocketCloseEventsSection
    | SessionsSection
    | WordSpellingGameSwedishSection
    | WebCodecsTestSection


type EmailNotifications
    = NeverNotifyMe
    | NotifyMeWhenMentioned


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) Evergreen.V358.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V358.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V358.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V358.Id.Id Evergreen.V358.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V358.Id.AnyGuildOrDmId (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V358.Id.AnyGuildOrDmId, Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId ) (Evergreen.V358.Id.Id Evergreen.V358.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) ( Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelId, Evergreen.V358.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) ( Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId, Evergreen.V358.Id.ThreadRoute )
    , icon : Maybe Evergreen.V358.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) (Evergreen.V358.NonemptyDict.NonemptyDict ( Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelId, Evergreen.V358.Id.ThreadRoute ) Evergreen.V358.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.NonemptyDict.NonemptyDict ( Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId, Evergreen.V358.Id.ThreadRoute ) Evergreen.V358.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V358.RichText.Domain
    , emojiConfig : Evergreen.V358.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V358.Id.Id Evergreen.V358.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V358.Id.Id Evergreen.V358.Id.CustomEmojiId)
    , muteSettings : Evergreen.V358.MuteSettings.Model
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V358.PersonName.PersonName
    , isAdmin : Bool
    , icon : Maybe Evergreen.V358.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V358.UserSession.UserSession
    , currentlyViewing : Evergreen.V358.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V358.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V358.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.StickerId) Evergreen.V358.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.CustomEmojiId) Evergreen.V358.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V358.Emoji.CachedEmojiData
    }
