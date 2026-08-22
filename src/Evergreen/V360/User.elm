module Evergreen.V360.User exposing (..)

import Effect.Time
import Evergreen.V360.CustomEmoji
import Evergreen.V360.Discord
import Evergreen.V360.EmailAddress
import Evergreen.V360.Emoji
import Evergreen.V360.FileStatus
import Evergreen.V360.Id
import Evergreen.V360.LinkedAndOtherDiscordUsers
import Evergreen.V360.MuteSettings
import Evergreen.V360.NonemptyDict
import Evergreen.V360.OneOrGreater
import Evergreen.V360.Pagination
import Evergreen.V360.PersonName
import Evergreen.V360.RichText
import Evergreen.V360.Sticker
import Evergreen.V360.UserAgent
import Evergreen.V360.UserColor
import Evergreen.V360.UserSession
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
    = DmChannelLastViewed (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) Evergreen.V360.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V360.PersonName.PersonName
    , color : Evergreen.V360.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V360.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V360.Id.Id Evergreen.V360.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V360.Id.AnyGuildOrDmId (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V360.Id.AnyGuildOrDmId, Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId ) (Evergreen.V360.Id.Id Evergreen.V360.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) ( Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelId, Evergreen.V360.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) ( Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId, Evergreen.V360.Id.ThreadRoute )
    , icon : Maybe Evergreen.V360.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) (Evergreen.V360.NonemptyDict.NonemptyDict ( Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelId, Evergreen.V360.Id.ThreadRoute ) Evergreen.V360.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.NonemptyDict.NonemptyDict ( Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId, Evergreen.V360.Id.ThreadRoute ) Evergreen.V360.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V360.RichText.Domain
    , emojiConfig : Evergreen.V360.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V360.Id.Id Evergreen.V360.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V360.Id.Id Evergreen.V360.Id.CustomEmojiId)
    , muteSettings : Evergreen.V360.MuteSettings.Model
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V360.PersonName.PersonName
    , color : Evergreen.V360.UserColor.UserColor
    , icon : Maybe Evergreen.V360.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V360.UserSession.UserSession
    , currentlyViewing : Evergreen.V360.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V360.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V360.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.StickerId) Evergreen.V360.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.CustomEmojiId) Evergreen.V360.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V360.Emoji.CachedEmojiData
    }
