module Evergreen.V348.User exposing (..)

import Effect.Time
import Evergreen.V348.CustomEmoji
import Evergreen.V348.Discord
import Evergreen.V348.EmailAddress
import Evergreen.V348.Emoji
import Evergreen.V348.FileStatus
import Evergreen.V348.Id
import Evergreen.V348.LinkedAndOtherDiscordUsers
import Evergreen.V348.MuteSettings
import Evergreen.V348.NonemptyDict
import Evergreen.V348.OneOrGreater
import Evergreen.V348.Pagination
import Evergreen.V348.PersonName
import Evergreen.V348.RichText
import Evergreen.V348.Sticker
import Evergreen.V348.UserAgent
import Evergreen.V348.UserSession
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
    = DmChannelLastViewed (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) Evergreen.V348.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V348.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V348.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V348.Id.Id Evergreen.V348.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V348.Id.AnyGuildOrDmId (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V348.Id.AnyGuildOrDmId, Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId ) (Evergreen.V348.Id.Id Evergreen.V348.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) ( Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId, Evergreen.V348.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) ( Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId, Evergreen.V348.Id.ThreadRoute )
    , icon : Maybe Evergreen.V348.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) (Evergreen.V348.NonemptyDict.NonemptyDict ( Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId, Evergreen.V348.Id.ThreadRoute ) Evergreen.V348.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.NonemptyDict.NonemptyDict ( Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId, Evergreen.V348.Id.ThreadRoute ) Evergreen.V348.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V348.RichText.Domain
    , emojiConfig : Evergreen.V348.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V348.Id.Id Evergreen.V348.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V348.Id.Id Evergreen.V348.Id.CustomEmojiId)
    , muteSettings : Evergreen.V348.MuteSettings.Model
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V348.PersonName.PersonName
    , isAdmin : Bool
    , icon : Maybe Evergreen.V348.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V348.UserSession.UserSession
    , currentlyViewing : Evergreen.V348.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V348.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V348.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.StickerId) Evergreen.V348.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.CustomEmojiId) Evergreen.V348.CustomEmoji.CustomEmojiData
    }
