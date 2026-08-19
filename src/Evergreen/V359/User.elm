module Evergreen.V359.User exposing (..)

import Effect.Time
import Evergreen.V359.CustomEmoji
import Evergreen.V359.Discord
import Evergreen.V359.EmailAddress
import Evergreen.V359.Emoji
import Evergreen.V359.FileStatus
import Evergreen.V359.Id
import Evergreen.V359.LinkedAndOtherDiscordUsers
import Evergreen.V359.MuteSettings
import Evergreen.V359.NonemptyDict
import Evergreen.V359.OneOrGreater
import Evergreen.V359.Pagination
import Evergreen.V359.PersonName
import Evergreen.V359.RichText
import Evergreen.V359.Sticker
import Evergreen.V359.UserAgent
import Evergreen.V359.UserSession
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
    = DmChannelLastViewed (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) Evergreen.V359.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V359.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V359.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V359.Id.Id Evergreen.V359.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V359.Id.AnyGuildOrDmId (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V359.Id.AnyGuildOrDmId, Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId ) (Evergreen.V359.Id.Id Evergreen.V359.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) ( Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelId, Evergreen.V359.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) ( Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId, Evergreen.V359.Id.ThreadRoute )
    , icon : Maybe Evergreen.V359.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) (Evergreen.V359.NonemptyDict.NonemptyDict ( Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelId, Evergreen.V359.Id.ThreadRoute ) Evergreen.V359.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.NonemptyDict.NonemptyDict ( Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId, Evergreen.V359.Id.ThreadRoute ) Evergreen.V359.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V359.RichText.Domain
    , emojiConfig : Evergreen.V359.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V359.Id.Id Evergreen.V359.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V359.Id.Id Evergreen.V359.Id.CustomEmojiId)
    , muteSettings : Evergreen.V359.MuteSettings.Model
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V359.PersonName.PersonName
    , isAdmin : Bool
    , icon : Maybe Evergreen.V359.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V359.UserSession.UserSession
    , currentlyViewing : Evergreen.V359.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V359.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V359.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.StickerId) Evergreen.V359.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.CustomEmojiId) Evergreen.V359.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V359.Emoji.CachedEmojiData
    }
