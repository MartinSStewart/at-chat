module Evergreen.V357.User exposing (..)

import Effect.Time
import Evergreen.V357.CustomEmoji
import Evergreen.V357.Discord
import Evergreen.V357.EmailAddress
import Evergreen.V357.Emoji
import Evergreen.V357.FileStatus
import Evergreen.V357.Id
import Evergreen.V357.LinkedAndOtherDiscordUsers
import Evergreen.V357.MuteSettings
import Evergreen.V357.NonemptyDict
import Evergreen.V357.OneOrGreater
import Evergreen.V357.Pagination
import Evergreen.V357.PersonName
import Evergreen.V357.RichText
import Evergreen.V357.Sticker
import Evergreen.V357.UserAgent
import Evergreen.V357.UserSession
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
    = DmChannelLastViewed (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Evergreen.V357.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V357.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V357.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V357.Id.Id Evergreen.V357.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V357.Id.AnyGuildOrDmId (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V357.Id.AnyGuildOrDmId, Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId ) (Evergreen.V357.Id.Id Evergreen.V357.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) ( Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelId, Evergreen.V357.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) ( Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId, Evergreen.V357.Id.ThreadRoute )
    , icon : Maybe Evergreen.V357.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) (Evergreen.V357.NonemptyDict.NonemptyDict ( Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelId, Evergreen.V357.Id.ThreadRoute ) Evergreen.V357.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.NonemptyDict.NonemptyDict ( Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId, Evergreen.V357.Id.ThreadRoute ) Evergreen.V357.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V357.RichText.Domain
    , emojiConfig : Evergreen.V357.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V357.Id.Id Evergreen.V357.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V357.Id.Id Evergreen.V357.Id.CustomEmojiId)
    , muteSettings : Evergreen.V357.MuteSettings.Model
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V357.PersonName.PersonName
    , isAdmin : Bool
    , icon : Maybe Evergreen.V357.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V357.UserSession.UserSession
    , currentlyViewing : Evergreen.V357.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V357.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V357.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.StickerId) Evergreen.V357.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.CustomEmojiId) Evergreen.V357.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V357.Emoji.CachedEmojiData
    }
