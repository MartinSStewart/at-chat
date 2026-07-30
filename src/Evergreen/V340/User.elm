module Evergreen.V340.User exposing (..)

import Effect.Time
import Evergreen.V340.CustomEmoji
import Evergreen.V340.Discord
import Evergreen.V340.EmailAddress
import Evergreen.V340.Emoji
import Evergreen.V340.FileStatus
import Evergreen.V340.Id
import Evergreen.V340.LinkedAndOtherDiscordUsers
import Evergreen.V340.MuteSettings
import Evergreen.V340.NonemptyDict
import Evergreen.V340.OneOrGreater
import Evergreen.V340.Pagination
import Evergreen.V340.PersonName
import Evergreen.V340.RichText
import Evergreen.V340.Sticker
import Evergreen.V340.UserAgent
import Evergreen.V340.UserSession
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
    | VoiceChatSection
    | WebsocketCloseEventsSection
    | SessionsSection
    | WordSpellingGameSwedishSection


type EmailNotifications
    = NeverNotifyMe
    | NotifyMeWhenMentioned


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) Evergreen.V340.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V340.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V340.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V340.Id.Id Evergreen.V340.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V340.Id.AnyGuildOrDmId (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V340.Id.AnyGuildOrDmId, Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId ) (Evergreen.V340.Id.Id Evergreen.V340.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) ( Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId, Evergreen.V340.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) ( Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId, Evergreen.V340.Id.ThreadRoute )
    , icon : Maybe Evergreen.V340.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) (Evergreen.V340.NonemptyDict.NonemptyDict ( Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId, Evergreen.V340.Id.ThreadRoute ) Evergreen.V340.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.NonemptyDict.NonemptyDict ( Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId, Evergreen.V340.Id.ThreadRoute ) Evergreen.V340.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V340.RichText.Domain
    , emojiConfig : Evergreen.V340.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V340.Id.Id Evergreen.V340.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V340.Id.Id Evergreen.V340.Id.CustomEmojiId)
    , muteSettings : Evergreen.V340.MuteSettings.Model
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V340.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V340.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V340.UserSession.UserSession
    , currentlyViewing : Evergreen.V340.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V340.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V340.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.StickerId) Evergreen.V340.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.CustomEmojiId) Evergreen.V340.CustomEmoji.CustomEmojiData
    }
