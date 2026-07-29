module Evergreen.V339.User exposing (..)

import Effect.Time
import Evergreen.V339.CustomEmoji
import Evergreen.V339.Discord
import Evergreen.V339.EmailAddress
import Evergreen.V339.Emoji
import Evergreen.V339.FileStatus
import Evergreen.V339.Id
import Evergreen.V339.LinkedAndOtherDiscordUsers
import Evergreen.V339.NonemptyDict
import Evergreen.V339.OneOrGreater
import Evergreen.V339.Pagination
import Evergreen.V339.PersonName
import Evergreen.V339.RichText
import Evergreen.V339.Sticker
import Evergreen.V339.UserAgent
import Evergreen.V339.UserSession
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
    = DmChannelLastViewed (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) Evergreen.V339.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V339.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V339.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V339.Id.Id Evergreen.V339.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V339.Id.AnyGuildOrDmId (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V339.Id.AnyGuildOrDmId, Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId ) (Evergreen.V339.Id.Id Evergreen.V339.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) ( Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelId, Evergreen.V339.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) ( Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId, Evergreen.V339.Id.ThreadRoute )
    , icon : Maybe Evergreen.V339.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) (Evergreen.V339.NonemptyDict.NonemptyDict ( Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelId, Evergreen.V339.Id.ThreadRoute ) Evergreen.V339.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.NonemptyDict.NonemptyDict ( Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId, Evergreen.V339.Id.ThreadRoute ) Evergreen.V339.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V339.RichText.Domain
    , emojiConfig : Evergreen.V339.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V339.Id.Id Evergreen.V339.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V339.Id.Id Evergreen.V339.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V339.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V339.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V339.UserSession.UserSession
    , currentlyViewing : Evergreen.V339.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V339.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V339.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.StickerId) Evergreen.V339.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.CustomEmojiId) Evergreen.V339.CustomEmoji.CustomEmojiData
    }
