module Evergreen.V343.User exposing (..)

import Effect.Time
import Evergreen.V343.CustomEmoji
import Evergreen.V343.Discord
import Evergreen.V343.EmailAddress
import Evergreen.V343.Emoji
import Evergreen.V343.FileStatus
import Evergreen.V343.Id
import Evergreen.V343.LinkedAndOtherDiscordUsers
import Evergreen.V343.MuteSettings
import Evergreen.V343.NonemptyDict
import Evergreen.V343.OneOrGreater
import Evergreen.V343.Pagination
import Evergreen.V343.PersonName
import Evergreen.V343.RichText
import Evergreen.V343.Sticker
import Evergreen.V343.UserAgent
import Evergreen.V343.UserSession
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
    = DmChannelLastViewed (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) Evergreen.V343.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V343.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V343.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V343.Id.Id Evergreen.V343.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V343.Id.AnyGuildOrDmId (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V343.Id.AnyGuildOrDmId, Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId ) (Evergreen.V343.Id.Id Evergreen.V343.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) ( Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId, Evergreen.V343.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) ( Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId, Evergreen.V343.Id.ThreadRoute )
    , icon : Maybe Evergreen.V343.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) (Evergreen.V343.NonemptyDict.NonemptyDict ( Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId, Evergreen.V343.Id.ThreadRoute ) Evergreen.V343.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.NonemptyDict.NonemptyDict ( Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId, Evergreen.V343.Id.ThreadRoute ) Evergreen.V343.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V343.RichText.Domain
    , emojiConfig : Evergreen.V343.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V343.Id.Id Evergreen.V343.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V343.Id.Id Evergreen.V343.Id.CustomEmojiId)
    , muteSettings : Evergreen.V343.MuteSettings.Model
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V343.PersonName.PersonName
    , isAdmin : Bool
    , icon : Maybe Evergreen.V343.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V343.UserSession.UserSession
    , currentlyViewing : Evergreen.V343.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V343.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V343.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.StickerId) Evergreen.V343.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.CustomEmojiId) Evergreen.V343.CustomEmoji.CustomEmojiData
    }
