module Evergreen.V346.User exposing (..)

import Effect.Time
import Evergreen.V346.CustomEmoji
import Evergreen.V346.Discord
import Evergreen.V346.EmailAddress
import Evergreen.V346.Emoji
import Evergreen.V346.FileStatus
import Evergreen.V346.Id
import Evergreen.V346.LinkedAndOtherDiscordUsers
import Evergreen.V346.MuteSettings
import Evergreen.V346.NonemptyDict
import Evergreen.V346.OneOrGreater
import Evergreen.V346.Pagination
import Evergreen.V346.PersonName
import Evergreen.V346.RichText
import Evergreen.V346.Sticker
import Evergreen.V346.UserAgent
import Evergreen.V346.UserSession
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
    = DmChannelLastViewed (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) Evergreen.V346.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V346.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V346.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V346.Id.Id Evergreen.V346.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V346.Id.AnyGuildOrDmId (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V346.Id.AnyGuildOrDmId, Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId ) (Evergreen.V346.Id.Id Evergreen.V346.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) ( Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId, Evergreen.V346.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) ( Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId, Evergreen.V346.Id.ThreadRoute )
    , icon : Maybe Evergreen.V346.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) (Evergreen.V346.NonemptyDict.NonemptyDict ( Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId, Evergreen.V346.Id.ThreadRoute ) Evergreen.V346.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.NonemptyDict.NonemptyDict ( Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId, Evergreen.V346.Id.ThreadRoute ) Evergreen.V346.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V346.RichText.Domain
    , emojiConfig : Evergreen.V346.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V346.Id.Id Evergreen.V346.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V346.Id.Id Evergreen.V346.Id.CustomEmojiId)
    , muteSettings : Evergreen.V346.MuteSettings.Model
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V346.PersonName.PersonName
    , isAdmin : Bool
    , icon : Maybe Evergreen.V346.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V346.UserSession.UserSession
    , currentlyViewing : Evergreen.V346.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V346.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V346.UserAgent.UserAgent
    , devicePixelRatio : Float
    , stickers : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.StickerId) Evergreen.V346.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.CustomEmojiId) Evergreen.V346.CustomEmoji.CustomEmojiData
    }
