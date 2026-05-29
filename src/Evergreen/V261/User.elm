module Evergreen.V261.User exposing (..)

import Effect.Time
import Evergreen.V261.CustomEmoji
import Evergreen.V261.Discord
import Evergreen.V261.DiscordUserData
import Evergreen.V261.EmailAddress
import Evergreen.V261.Emoji
import Evergreen.V261.FileStatus
import Evergreen.V261.Id
import Evergreen.V261.NonemptyDict
import Evergreen.V261.OneOrGreater
import Evergreen.V261.Pagination
import Evergreen.V261.PersonName
import Evergreen.V261.RichText
import Evergreen.V261.Sticker
import Evergreen.V261.UserAgent
import Evergreen.V261.UserSession
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


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) Evergreen.V261.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V261.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V261.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V261.Id.Id Evergreen.V261.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V261.Id.AnyGuildOrDmId (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V261.Id.AnyGuildOrDmId, Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId ) (Evergreen.V261.Id.Id Evergreen.V261.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) ( Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelId, Evergreen.V261.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) ( Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId, Evergreen.V261.Id.ThreadRoute )
    , icon : Maybe Evergreen.V261.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) (Evergreen.V261.NonemptyDict.NonemptyDict ( Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelId, Evergreen.V261.Id.ThreadRoute ) Evergreen.V261.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.NonemptyDict.NonemptyDict ( Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId, Evergreen.V261.Id.ThreadRoute ) Evergreen.V261.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V261.RichText.Domain
    , emojiConfig : Evergreen.V261.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V261.Id.Id Evergreen.V261.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V261.Id.Id Evergreen.V261.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V261.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V261.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V261.PersonName.PersonName
    , icon : Maybe Evergreen.V261.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V261.PersonName.PersonName
    , icon : Maybe Evergreen.V261.FileStatus.FileHash
    , email : Maybe Evergreen.V261.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V261.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V261.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V261.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.StickerId) Evergreen.V261.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.CustomEmojiId) Evergreen.V261.CustomEmoji.CustomEmojiData
    }
