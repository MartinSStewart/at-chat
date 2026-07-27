module Evergreen.V336.User exposing (..)

import Effect.Time
import Evergreen.V336.CustomEmoji
import Evergreen.V336.Discord
import Evergreen.V336.EmailAddress
import Evergreen.V336.Emoji
import Evergreen.V336.FileStatus
import Evergreen.V336.Id
import Evergreen.V336.LinkedAndOtherDiscordUsers
import Evergreen.V336.NonemptyDict
import Evergreen.V336.OneOrGreater
import Evergreen.V336.Pagination
import Evergreen.V336.PersonName
import Evergreen.V336.RichText
import Evergreen.V336.Sticker
import Evergreen.V336.UserAgent
import Evergreen.V336.UserSession
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
    = DmChannelLastViewed (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) Evergreen.V336.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V336.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V336.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V336.Id.Id Evergreen.V336.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V336.Id.AnyGuildOrDmId (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V336.Id.AnyGuildOrDmId, Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId ) (Evergreen.V336.Id.Id Evergreen.V336.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) ( Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelId, Evergreen.V336.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) ( Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId, Evergreen.V336.Id.ThreadRoute )
    , icon : Maybe Evergreen.V336.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) (Evergreen.V336.NonemptyDict.NonemptyDict ( Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelId, Evergreen.V336.Id.ThreadRoute ) Evergreen.V336.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.NonemptyDict.NonemptyDict ( Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId, Evergreen.V336.Id.ThreadRoute ) Evergreen.V336.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V336.RichText.Domain
    , emojiConfig : Evergreen.V336.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V336.Id.Id Evergreen.V336.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V336.Id.Id Evergreen.V336.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V336.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V336.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V336.UserSession.UserSession
    , currentlyViewing : Evergreen.V336.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V336.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V336.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.StickerId) Evergreen.V336.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.CustomEmojiId) Evergreen.V336.CustomEmoji.CustomEmojiData
    }
