module Evergreen.V334.User exposing (..)

import Effect.Time
import Evergreen.V334.CustomEmoji
import Evergreen.V334.Discord
import Evergreen.V334.EmailAddress
import Evergreen.V334.Emoji
import Evergreen.V334.FileStatus
import Evergreen.V334.Id
import Evergreen.V334.LinkedAndOtherDiscordUsers
import Evergreen.V334.NonemptyDict
import Evergreen.V334.OneOrGreater
import Evergreen.V334.Pagination
import Evergreen.V334.PersonName
import Evergreen.V334.RichText
import Evergreen.V334.Sticker
import Evergreen.V334.UserAgent
import Evergreen.V334.UserSession
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
    = DmChannelLastViewed (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId) Evergreen.V334.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V334.Discord.Id Evergreen.V334.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V334.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V334.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V334.Id.Id Evergreen.V334.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V334.Id.AnyGuildOrDmId (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V334.Id.AnyGuildOrDmId, Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId ) (Evergreen.V334.Id.Id Evergreen.V334.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.GuildId) ( Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelId, Evergreen.V334.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId) ( Evergreen.V334.Discord.Id Evergreen.V334.Discord.ChannelId, Evergreen.V334.Id.ThreadRoute )
    , icon : Maybe Evergreen.V334.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V334.Id.Id Evergreen.V334.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.GuildId) (Evergreen.V334.NonemptyDict.NonemptyDict ( Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelId, Evergreen.V334.Id.ThreadRoute ) Evergreen.V334.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId) (Evergreen.V334.NonemptyDict.NonemptyDict ( Evergreen.V334.Discord.Id Evergreen.V334.Discord.ChannelId, Evergreen.V334.Id.ThreadRoute ) Evergreen.V334.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V334.Id.Id Evergreen.V334.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V334.RichText.Domain
    , emojiConfig : Evergreen.V334.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V334.Id.Id Evergreen.V334.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V334.Id.Id Evergreen.V334.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V334.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V334.FileStatus.FileHash
    }


type alias LocalUser =
    { session : Evergreen.V334.UserSession.UserSession
    , currentlyViewing : Evergreen.V334.UserSession.Viewing
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId) FrontendUser
    , discordUsers : Evergreen.V334.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V334.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.StickerId) Evergreen.V334.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.CustomEmojiId) Evergreen.V334.CustomEmoji.CustomEmojiData
    }
