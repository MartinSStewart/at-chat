module Evergreen.V266.User exposing (..)

import Effect.Time
import Evergreen.V266.CustomEmoji
import Evergreen.V266.Discord
import Evergreen.V266.DiscordUserData
import Evergreen.V266.EmailAddress
import Evergreen.V266.Emoji
import Evergreen.V266.FileStatus
import Evergreen.V266.Id
import Evergreen.V266.NonemptyDict
import Evergreen.V266.OneOrGreater
import Evergreen.V266.Pagination
import Evergreen.V266.PersonName
import Evergreen.V266.RichText
import Evergreen.V266.Sticker
import Evergreen.V266.UserAgent
import Evergreen.V266.UserSession
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


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) Evergreen.V266.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V266.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V266.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V266.Id.Id Evergreen.V266.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V266.Id.AnyGuildOrDmId (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V266.Id.AnyGuildOrDmId, Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId ) (Evergreen.V266.Id.Id Evergreen.V266.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) ( Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelId, Evergreen.V266.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) ( Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId, Evergreen.V266.Id.ThreadRoute )
    , icon : Maybe Evergreen.V266.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) (Evergreen.V266.NonemptyDict.NonemptyDict ( Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelId, Evergreen.V266.Id.ThreadRoute ) Evergreen.V266.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.NonemptyDict.NonemptyDict ( Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId, Evergreen.V266.Id.ThreadRoute ) Evergreen.V266.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V266.RichText.Domain
    , emojiConfig : Evergreen.V266.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V266.Id.Id Evergreen.V266.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V266.Id.Id Evergreen.V266.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V266.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V266.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V266.PersonName.PersonName
    , icon : Maybe Evergreen.V266.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V266.PersonName.PersonName
    , icon : Maybe Evergreen.V266.FileStatus.FileHash
    , email : Maybe Evergreen.V266.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V266.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V266.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V266.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.StickerId) Evergreen.V266.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.CustomEmojiId) Evergreen.V266.CustomEmoji.CustomEmojiData
    }
