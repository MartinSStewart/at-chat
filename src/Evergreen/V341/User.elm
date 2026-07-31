module Evergreen.V341.User exposing (..)

import Effect.Time
import Evergreen.V341.CustomEmoji
import Evergreen.V341.Discord
import Evergreen.V341.EmailAddress
import Evergreen.V341.Emoji
import Evergreen.V341.FileStatus
import Evergreen.V341.Id
import Evergreen.V341.LinkedAndOtherDiscordUsers
import Evergreen.V341.MuteSettings
import Evergreen.V341.NonemptyDict
import Evergreen.V341.OneOrGreater
import Evergreen.V341.Pagination
import Evergreen.V341.PersonName
import Evergreen.V341.RichText
import Evergreen.V341.Sticker
import Evergreen.V341.UserAgent
import Evergreen.V341.UserSession
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
    = DmChannelLastViewed (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) Evergreen.V341.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V341.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V341.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V341.Id.Id Evergreen.V341.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V341.Id.AnyGuildOrDmId (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V341.Id.AnyGuildOrDmId, Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId ) (Evergreen.V341.Id.Id Evergreen.V341.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) ( Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId, Evergreen.V341.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) ( Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId, Evergreen.V341.Id.ThreadRoute )
    , icon : Maybe Evergreen.V341.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) (Evergreen.V341.NonemptyDict.NonemptyDict ( Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId, Evergreen.V341.Id.ThreadRoute ) Evergreen.V341.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.NonemptyDict.NonemptyDict ( Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId, Evergreen.V341.Id.ThreadRoute ) Evergreen.V341.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V341.RichText.Domain
    , emojiConfig : Evergreen.V341.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V341.Id.Id Evergreen.V341.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V341.Id.Id Evergreen.V341.Id.CustomEmojiId)
    , muteSettings : Evergreen.V341.MuteSettings.Model
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V341.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V341.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V341.UserSession.UserSession
    , currentlyViewing : Evergreen.V341.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V341.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V341.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.StickerId) Evergreen.V341.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.CustomEmojiId) Evergreen.V341.CustomEmoji.CustomEmojiData
    }
