module Evergreen.V365.User exposing (..)

import Effect.Time
import Evergreen.V365.CustomEmoji
import Evergreen.V365.Discord
import Evergreen.V365.EmailAddress
import Evergreen.V365.Emoji
import Evergreen.V365.FileStatus
import Evergreen.V365.Id
import Evergreen.V365.LinkedAndOtherDiscordUsers
import Evergreen.V365.MuteSettings
import Evergreen.V365.NonemptyDict
import Evergreen.V365.OneOrGreater
import Evergreen.V365.Pagination
import Evergreen.V365.PersonName
import Evergreen.V365.RichText
import Evergreen.V365.Sticker
import Evergreen.V365.UserAgent
import Evergreen.V365.UserColor
import Evergreen.V365.UserSession
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
    = DmChannelLastViewed (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) Evergreen.V365.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V365.PersonName.PersonName
    , color : Evergreen.V365.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V365.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V365.Id.Id Evergreen.V365.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V365.Id.AnyGuildOrDmId (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V365.Id.AnyGuildOrDmId, Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId ) (Evergreen.V365.Id.Id Evergreen.V365.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) ( Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelId, Evergreen.V365.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) ( Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId, Evergreen.V365.Id.ThreadRoute )
    , icon : Maybe Evergreen.V365.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) (Evergreen.V365.NonemptyDict.NonemptyDict ( Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelId, Evergreen.V365.Id.ThreadRoute ) Evergreen.V365.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.NonemptyDict.NonemptyDict ( Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId, Evergreen.V365.Id.ThreadRoute ) Evergreen.V365.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V365.RichText.Domain
    , emojiConfig : Evergreen.V365.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V365.Id.Id Evergreen.V365.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V365.Id.Id Evergreen.V365.Id.CustomEmojiId)
    , muteSettings : Evergreen.V365.MuteSettings.Model
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V365.PersonName.PersonName
    , color : Evergreen.V365.UserColor.UserColor
    , icon : Maybe Evergreen.V365.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V365.UserSession.UserSession
    , currentlyViewing : Evergreen.V365.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V365.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V365.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.StickerId) Evergreen.V365.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.CustomEmojiId) Evergreen.V365.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V365.Emoji.CachedEmojiData
    }
