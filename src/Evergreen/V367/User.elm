module Evergreen.V367.User exposing (..)

import Effect.Time
import Evergreen.V367.CustomEmoji
import Evergreen.V367.Discord
import Evergreen.V367.EmailAddress
import Evergreen.V367.Emoji
import Evergreen.V367.FileStatus
import Evergreen.V367.Id
import Evergreen.V367.LinkedAndOtherDiscordUsers
import Evergreen.V367.MuteSettings
import Evergreen.V367.NonemptyDict
import Evergreen.V367.OneOrGreater
import Evergreen.V367.Pagination
import Evergreen.V367.PersonName
import Evergreen.V367.RichText
import Evergreen.V367.Sticker
import Evergreen.V367.UserAgent
import Evergreen.V367.UserColor
import Evergreen.V367.UserSession
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
    = DmChannelLastViewed (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) Evergreen.V367.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V367.PersonName.PersonName
    , color : Evergreen.V367.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V367.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V367.Id.Id Evergreen.V367.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V367.Id.AnyGuildOrDmId (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V367.Id.AnyGuildOrDmId, Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId ) (Evergreen.V367.Id.Id Evergreen.V367.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) ( Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelId, Evergreen.V367.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) ( Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId, Evergreen.V367.Id.ThreadRoute )
    , icon : Maybe Evergreen.V367.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) (Evergreen.V367.NonemptyDict.NonemptyDict ( Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelId, Evergreen.V367.Id.ThreadRoute ) Evergreen.V367.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId) (Evergreen.V367.NonemptyDict.NonemptyDict ( Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId, Evergreen.V367.Id.ThreadRoute ) Evergreen.V367.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V367.RichText.Domain
    , emojiConfig : Evergreen.V367.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V367.Id.Id Evergreen.V367.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V367.Id.Id Evergreen.V367.Id.CustomEmojiId)
    , muteSettings : Evergreen.V367.MuteSettings.Model
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V367.PersonName.PersonName
    , color : Evergreen.V367.UserColor.UserColor
    , icon : Maybe Evergreen.V367.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V367.UserSession.UserSession
    , currentlyViewing : Evergreen.V367.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V367.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V367.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.StickerId) Evergreen.V367.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.CustomEmojiId) Evergreen.V367.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V367.Emoji.CachedEmojiData
    }
