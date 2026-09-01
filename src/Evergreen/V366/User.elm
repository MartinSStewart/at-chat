module Evergreen.V366.User exposing (..)

import Effect.Time
import Evergreen.V366.CustomEmoji
import Evergreen.V366.Discord
import Evergreen.V366.EmailAddress
import Evergreen.V366.Emoji
import Evergreen.V366.FileStatus
import Evergreen.V366.Id
import Evergreen.V366.LinkedAndOtherDiscordUsers
import Evergreen.V366.MuteSettings
import Evergreen.V366.NonemptyDict
import Evergreen.V366.OneOrGreater
import Evergreen.V366.Pagination
import Evergreen.V366.PersonName
import Evergreen.V366.RichText
import Evergreen.V366.Sticker
import Evergreen.V366.UserAgent
import Evergreen.V366.UserColor
import Evergreen.V366.UserSession
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
    = DmChannelLastViewed (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) Evergreen.V366.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V366.PersonName.PersonName
    , color : Evergreen.V366.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V366.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V366.Id.Id Evergreen.V366.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V366.Id.AnyGuildOrDmId (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V366.Id.AnyGuildOrDmId, Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId ) (Evergreen.V366.Id.Id Evergreen.V366.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) ( Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelId, Evergreen.V366.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) ( Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId, Evergreen.V366.Id.ThreadRoute )
    , icon : Maybe Evergreen.V366.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) (Evergreen.V366.NonemptyDict.NonemptyDict ( Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelId, Evergreen.V366.Id.ThreadRoute ) Evergreen.V366.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.NonemptyDict.NonemptyDict ( Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId, Evergreen.V366.Id.ThreadRoute ) Evergreen.V366.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V366.RichText.Domain
    , emojiConfig : Evergreen.V366.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V366.Id.Id Evergreen.V366.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V366.Id.Id Evergreen.V366.Id.CustomEmojiId)
    , muteSettings : Evergreen.V366.MuteSettings.Model
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V366.PersonName.PersonName
    , color : Evergreen.V366.UserColor.UserColor
    , icon : Maybe Evergreen.V366.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V366.UserSession.UserSession
    , currentlyViewing : Evergreen.V366.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V366.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V366.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.StickerId) Evergreen.V366.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.CustomEmojiId) Evergreen.V366.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V366.Emoji.CachedEmojiData
    }
