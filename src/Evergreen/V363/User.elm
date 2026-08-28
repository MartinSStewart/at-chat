module Evergreen.V363.User exposing (..)

import Effect.Time
import Evergreen.V363.CustomEmoji
import Evergreen.V363.Discord
import Evergreen.V363.EmailAddress
import Evergreen.V363.Emoji
import Evergreen.V363.FileStatus
import Evergreen.V363.Id
import Evergreen.V363.LinkedAndOtherDiscordUsers
import Evergreen.V363.MuteSettings
import Evergreen.V363.NonemptyDict
import Evergreen.V363.OneOrGreater
import Evergreen.V363.Pagination
import Evergreen.V363.PersonName
import Evergreen.V363.RichText
import Evergreen.V363.Sticker
import Evergreen.V363.UserAgent
import Evergreen.V363.UserColor
import Evergreen.V363.UserSession
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
    = DmChannelLastViewed (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) Evergreen.V363.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V363.PersonName.PersonName
    , color : Evergreen.V363.UserColor.UserColor
    , isAdmin : Bool
    , email : Evergreen.V363.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V363.Id.Id Evergreen.V363.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V363.Id.AnyGuildOrDmId (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V363.Id.AnyGuildOrDmId, Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId ) (Evergreen.V363.Id.Id Evergreen.V363.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) ( Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelId, Evergreen.V363.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) ( Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId, Evergreen.V363.Id.ThreadRoute )
    , icon : Maybe Evergreen.V363.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) (Evergreen.V363.NonemptyDict.NonemptyDict ( Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelId, Evergreen.V363.Id.ThreadRoute ) Evergreen.V363.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.NonemptyDict.NonemptyDict ( Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId, Evergreen.V363.Id.ThreadRoute ) Evergreen.V363.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V363.RichText.Domain
    , emojiConfig : Evergreen.V363.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V363.Id.Id Evergreen.V363.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V363.Id.Id Evergreen.V363.Id.CustomEmojiId)
    , muteSettings : Evergreen.V363.MuteSettings.Model
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V363.PersonName.PersonName
    , color : Evergreen.V363.UserColor.UserColor
    , icon : Maybe Evergreen.V363.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V363.UserSession.UserSession
    , currentlyViewing : Evergreen.V363.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V363.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V363.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.StickerId) Evergreen.V363.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.CustomEmojiId) Evergreen.V363.CustomEmoji.CustomEmojiData
    , emojiData : Maybe Evergreen.V363.Emoji.CachedEmojiData
    }
