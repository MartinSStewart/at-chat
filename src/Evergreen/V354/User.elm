module Evergreen.V354.User exposing (..)

import Effect.Time
import Evergreen.V354.CustomEmoji
import Evergreen.V354.Discord
import Evergreen.V354.EmailAddress
import Evergreen.V354.Emoji
import Evergreen.V354.FileStatus
import Evergreen.V354.Id
import Evergreen.V354.LinkedAndOtherDiscordUsers
import Evergreen.V354.MuteSettings
import Evergreen.V354.NonemptyDict
import Evergreen.V354.OneOrGreater
import Evergreen.V354.Pagination
import Evergreen.V354.PersonName
import Evergreen.V354.RichText
import Evergreen.V354.Sticker
import Evergreen.V354.UserAgent
import Evergreen.V354.UserSession
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
    = DmChannelLastViewed (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) Evergreen.V354.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V354.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V354.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V354.Id.Id Evergreen.V354.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V354.Id.AnyGuildOrDmId (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V354.Id.AnyGuildOrDmId, Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId ) (Evergreen.V354.Id.Id Evergreen.V354.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) ( Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelId, Evergreen.V354.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) ( Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId, Evergreen.V354.Id.ThreadRoute )
    , icon : Maybe Evergreen.V354.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) (Evergreen.V354.NonemptyDict.NonemptyDict ( Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelId, Evergreen.V354.Id.ThreadRoute ) Evergreen.V354.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.NonemptyDict.NonemptyDict ( Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId, Evergreen.V354.Id.ThreadRoute ) Evergreen.V354.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V354.RichText.Domain
    , emojiConfig : Evergreen.V354.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V354.Id.Id Evergreen.V354.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V354.Id.Id Evergreen.V354.Id.CustomEmojiId)
    , muteSettings : Evergreen.V354.MuteSettings.Model
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V354.PersonName.PersonName
    , isAdmin : Bool
    , icon : Maybe Evergreen.V354.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V354.UserSession.UserSession
    , currentlyViewing : Evergreen.V354.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V354.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V354.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.StickerId) Evergreen.V354.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.CustomEmojiId) Evergreen.V354.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V354.Emoji.CachedEmojiData
    }
