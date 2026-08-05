module Evergreen.V345.User exposing (..)

import Effect.Time
import Evergreen.V345.CustomEmoji
import Evergreen.V345.Discord
import Evergreen.V345.EmailAddress
import Evergreen.V345.Emoji
import Evergreen.V345.FileStatus
import Evergreen.V345.Id
import Evergreen.V345.LinkedAndOtherDiscordUsers
import Evergreen.V345.MuteSettings
import Evergreen.V345.NonemptyDict
import Evergreen.V345.OneOrGreater
import Evergreen.V345.Pagination
import Evergreen.V345.PersonName
import Evergreen.V345.RichText
import Evergreen.V345.Sticker
import Evergreen.V345.UserAgent
import Evergreen.V345.UserSession
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
    = DmChannelLastViewed (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) Evergreen.V345.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V345.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V345.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V345.Id.Id Evergreen.V345.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V345.Id.AnyGuildOrDmId (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V345.Id.AnyGuildOrDmId, Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId ) (Evergreen.V345.Id.Id Evergreen.V345.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) ( Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId, Evergreen.V345.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) ( Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId, Evergreen.V345.Id.ThreadRoute )
    , icon : Maybe Evergreen.V345.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) (Evergreen.V345.NonemptyDict.NonemptyDict ( Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId, Evergreen.V345.Id.ThreadRoute ) Evergreen.V345.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.NonemptyDict.NonemptyDict ( Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId, Evergreen.V345.Id.ThreadRoute ) Evergreen.V345.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V345.RichText.Domain
    , emojiConfig : Evergreen.V345.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V345.Id.Id Evergreen.V345.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V345.Id.Id Evergreen.V345.Id.CustomEmojiId)
    , muteSettings : Evergreen.V345.MuteSettings.Model
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V345.PersonName.PersonName
    , isAdmin : Bool
    , icon : Maybe Evergreen.V345.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V345.UserSession.UserSession
    , currentlyViewing : Evergreen.V345.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V345.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V345.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.StickerId) Evergreen.V345.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.CustomEmojiId) Evergreen.V345.CustomEmoji.CustomEmojiData
    }
