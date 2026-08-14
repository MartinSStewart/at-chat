module Evergreen.V352.User exposing (..)

import Effect.Time
import Evergreen.V352.CustomEmoji
import Evergreen.V352.Discord
import Evergreen.V352.EmailAddress
import Evergreen.V352.Emoji
import Evergreen.V352.FileStatus
import Evergreen.V352.Id
import Evergreen.V352.LinkedAndOtherDiscordUsers
import Evergreen.V352.MuteSettings
import Evergreen.V352.NonemptyDict
import Evergreen.V352.OneOrGreater
import Evergreen.V352.Pagination
import Evergreen.V352.PersonName
import Evergreen.V352.RichText
import Evergreen.V352.Sticker
import Evergreen.V352.UserAgent
import Evergreen.V352.UserSession
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
    = DmChannelLastViewed (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) Evergreen.V352.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V352.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V352.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V352.Id.Id Evergreen.V352.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewedMessage : SeqDict.SeqDict Evergreen.V352.Id.AnyGuildOrDmId (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId)
    , lastViewedThreadMessage : SeqDict.SeqDict ( Evergreen.V352.Id.AnyGuildOrDmId, Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId ) (Evergreen.V352.Id.Id Evergreen.V352.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) ( Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelId, Evergreen.V352.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) ( Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId, Evergreen.V352.Id.ThreadRoute )
    , icon : Maybe Evergreen.V352.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) (Evergreen.V352.NonemptyDict.NonemptyDict ( Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelId, Evergreen.V352.Id.ThreadRoute ) Evergreen.V352.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.NonemptyDict.NonemptyDict ( Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId, Evergreen.V352.Id.ThreadRoute ) Evergreen.V352.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V352.RichText.Domain
    , emojiConfig : Evergreen.V352.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V352.Id.Id Evergreen.V352.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V352.Id.Id Evergreen.V352.Id.CustomEmojiId)
    , muteSettings : Evergreen.V352.MuteSettings.Model
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V352.PersonName.PersonName
    , isAdmin : Bool
    , icon : Maybe Evergreen.V352.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V352.UserSession.UserSession
    , currentlyViewing : Evergreen.V352.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V352.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V352.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.StickerId) Evergreen.V352.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.CustomEmojiId) Evergreen.V352.CustomEmoji.CustomEmojiData
    }
