module Evergreen.V242.User exposing (..)

import Effect.Time
import Evergreen.V242.CustomEmoji
import Evergreen.V242.Discord
import Evergreen.V242.DiscordUserData
import Evergreen.V242.EmailAddress
import Evergreen.V242.Emoji
import Evergreen.V242.FileStatus
import Evergreen.V242.Id
import Evergreen.V242.NonemptyDict
import Evergreen.V242.OneOrGreater
import Evergreen.V242.Pagination
import Evergreen.V242.PersonName
import Evergreen.V242.RichText
import Evergreen.V242.Sticker
import Evergreen.V242.UserAgent
import Evergreen.V242.UserSession
import SeqDict
import SeqSet


type AdminUiSection
    = UsersSection
    | LogSection
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
    | WebsocketDisconnectsSection


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) Evergreen.V242.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V242.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V242.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V242.Id.Id Evergreen.V242.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V242.Id.AnyGuildOrDmId (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V242.Id.AnyGuildOrDmId, Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId ) (Evergreen.V242.Id.Id Evergreen.V242.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) ( Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelId, Evergreen.V242.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) ( Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId, Evergreen.V242.Id.ThreadRoute )
    , icon : Maybe Evergreen.V242.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) (Evergreen.V242.NonemptyDict.NonemptyDict ( Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelId, Evergreen.V242.Id.ThreadRoute ) Evergreen.V242.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.NonemptyDict.NonemptyDict ( Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId, Evergreen.V242.Id.ThreadRoute ) Evergreen.V242.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V242.RichText.Domain
    , emojiConfig : Evergreen.V242.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V242.Id.Id Evergreen.V242.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V242.Id.Id Evergreen.V242.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V242.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V242.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V242.PersonName.PersonName
    , icon : Maybe Evergreen.V242.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V242.PersonName.PersonName
    , icon : Maybe Evergreen.V242.FileStatus.FileHash
    , email : Maybe Evergreen.V242.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V242.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V242.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V242.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.StickerId) Evergreen.V242.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.CustomEmojiId) Evergreen.V242.CustomEmoji.CustomEmojiData
    }
