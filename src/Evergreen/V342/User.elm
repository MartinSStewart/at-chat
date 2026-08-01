module Evergreen.V342.User exposing (..)

import Effect.Time
import Evergreen.V342.CustomEmoji
import Evergreen.V342.Discord
import Evergreen.V342.EmailAddress
import Evergreen.V342.Emoji
import Evergreen.V342.FileStatus
import Evergreen.V342.Id
import Evergreen.V342.LinkedAndOtherDiscordUsers
import Evergreen.V342.MuteSettings
import Evergreen.V342.NonemptyDict
import Evergreen.V342.OneOrGreater
import Evergreen.V342.Pagination
import Evergreen.V342.PersonName
import Evergreen.V342.RichText
import Evergreen.V342.Sticker
import Evergreen.V342.UserAgent
import Evergreen.V342.UserSession
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
    = DmChannelLastViewed (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) Evergreen.V342.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V342.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V342.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V342.Id.Id Evergreen.V342.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V342.Id.AnyGuildOrDmId (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V342.Id.AnyGuildOrDmId, Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId ) (Evergreen.V342.Id.Id Evergreen.V342.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) ( Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId, Evergreen.V342.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) ( Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId, Evergreen.V342.Id.ThreadRoute )
    , icon : Maybe Evergreen.V342.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) (Evergreen.V342.NonemptyDict.NonemptyDict ( Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId, Evergreen.V342.Id.ThreadRoute ) Evergreen.V342.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.NonemptyDict.NonemptyDict ( Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId, Evergreen.V342.Id.ThreadRoute ) Evergreen.V342.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V342.RichText.Domain
    , emojiConfig : Evergreen.V342.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V342.Id.Id Evergreen.V342.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V342.Id.Id Evergreen.V342.Id.CustomEmojiId)
    , muteSettings : Evergreen.V342.MuteSettings.Model
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V342.PersonName.PersonName
    , isAdmin : Bool
    , icon : Maybe Evergreen.V342.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V342.UserSession.UserSession
    , currentlyViewing : Evergreen.V342.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V342.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V342.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.StickerId) Evergreen.V342.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.CustomEmojiId) Evergreen.V342.CustomEmoji.CustomEmojiData
    }
