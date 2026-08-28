module Evergreen.V364.User exposing (..)

import Effect.Time
import Evergreen.V364.CustomEmoji
import Evergreen.V364.Discord
import Evergreen.V364.EmailAddress
import Evergreen.V364.Emoji
import Evergreen.V364.FileStatus
import Evergreen.V364.Id
import Evergreen.V364.LinkedAndOtherDiscordUsers
import Evergreen.V364.MuteSettings
import Evergreen.V364.NonemptyDict
import Evergreen.V364.OneOrGreater
import Evergreen.V364.Pagination
import Evergreen.V364.PersonName
import Evergreen.V364.RichText
import Evergreen.V364.Sticker
import Evergreen.V364.UserAgent
import Evergreen.V364.UserColor
import Evergreen.V364.UserSession
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
    = DmChannelLastViewed (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) Evergreen.V364.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V364.PersonName.PersonName
    , color : Evergreen.V364.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V364.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V364.Id.Id Evergreen.V364.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V364.Id.AnyGuildOrDmId (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V364.Id.AnyGuildOrDmId, Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId ) (Evergreen.V364.Id.Id Evergreen.V364.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) ( Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelId, Evergreen.V364.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) ( Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId, Evergreen.V364.Id.ThreadRoute )
    , icon : Maybe Evergreen.V364.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) (Evergreen.V364.NonemptyDict.NonemptyDict ( Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelId, Evergreen.V364.Id.ThreadRoute ) Evergreen.V364.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.NonemptyDict.NonemptyDict ( Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId, Evergreen.V364.Id.ThreadRoute ) Evergreen.V364.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V364.RichText.Domain
    , emojiConfig : Evergreen.V364.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V364.Id.Id Evergreen.V364.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V364.Id.Id Evergreen.V364.Id.CustomEmojiId)
    , muteSettings : Evergreen.V364.MuteSettings.Model
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V364.PersonName.PersonName
    , color : Evergreen.V364.UserColor.UserColor
    , icon : Maybe Evergreen.V364.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V364.UserSession.UserSession
    , currentlyViewing : Evergreen.V364.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V364.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V364.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.StickerId) Evergreen.V364.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.CustomEmojiId) Evergreen.V364.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V364.Emoji.CachedEmojiData
    }
