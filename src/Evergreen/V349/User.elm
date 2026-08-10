module Evergreen.V349.User exposing (..)

import Effect.Time
import Evergreen.V349.CustomEmoji
import Evergreen.V349.Discord
import Evergreen.V349.EmailAddress
import Evergreen.V349.Emoji
import Evergreen.V349.FileStatus
import Evergreen.V349.Id
import Evergreen.V349.LinkedAndOtherDiscordUsers
import Evergreen.V349.MuteSettings
import Evergreen.V349.NonemptyDict
import Evergreen.V349.OneOrGreater
import Evergreen.V349.Pagination
import Evergreen.V349.PersonName
import Evergreen.V349.RichText
import Evergreen.V349.Sticker
import Evergreen.V349.UserAgent
import Evergreen.V349.UserSession
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
    | WebCodecsTestSection


type EmailNotifications
    = NeverNotifyMe
    | NotifyMeWhenMentioned


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) Evergreen.V349.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V349.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V349.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V349.Id.Id Evergreen.V349.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V349.Id.AnyGuildOrDmId (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V349.Id.AnyGuildOrDmId, Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId ) (Evergreen.V349.Id.Id Evergreen.V349.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) ( Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId, Evergreen.V349.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) ( Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId, Evergreen.V349.Id.ThreadRoute )
    , icon : Maybe Evergreen.V349.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) (Evergreen.V349.NonemptyDict.NonemptyDict ( Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId, Evergreen.V349.Id.ThreadRoute ) Evergreen.V349.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.NonemptyDict.NonemptyDict ( Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId, Evergreen.V349.Id.ThreadRoute ) Evergreen.V349.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V349.RichText.Domain
    , emojiConfig : Evergreen.V349.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V349.Id.Id Evergreen.V349.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V349.Id.Id Evergreen.V349.Id.CustomEmojiId)
    , muteSettings : Evergreen.V349.MuteSettings.Model
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V349.PersonName.PersonName
    , isAdmin : Bool
    , icon : Maybe Evergreen.V349.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V349.UserSession.UserSession
    , currentlyViewing : Evergreen.V349.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V349.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V349.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.StickerId) Evergreen.V349.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.CustomEmojiId) Evergreen.V349.CustomEmoji.CustomEmojiData
    }
