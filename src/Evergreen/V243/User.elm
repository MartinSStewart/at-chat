module Evergreen.V243.User exposing (..)

import Effect.Time
import Evergreen.V243.CustomEmoji
import Evergreen.V243.Discord
import Evergreen.V243.DiscordUserData
import Evergreen.V243.EmailAddress
import Evergreen.V243.Emoji
import Evergreen.V243.FileStatus
import Evergreen.V243.Id
import Evergreen.V243.NonemptyDict
import Evergreen.V243.OneOrGreater
import Evergreen.V243.Pagination
import Evergreen.V243.PersonName
import Evergreen.V243.RichText
import Evergreen.V243.Sticker
import Evergreen.V243.UserAgent
import Evergreen.V243.UserSession
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
    = DmChannelLastViewed (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) Evergreen.V243.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V243.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V243.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V243.Id.Id Evergreen.V243.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V243.Id.AnyGuildOrDmId (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V243.Id.AnyGuildOrDmId, Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId ) (Evergreen.V243.Id.Id Evergreen.V243.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) ( Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelId, Evergreen.V243.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) ( Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId, Evergreen.V243.Id.ThreadRoute )
    , icon : Maybe Evergreen.V243.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) (Evergreen.V243.NonemptyDict.NonemptyDict ( Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelId, Evergreen.V243.Id.ThreadRoute ) Evergreen.V243.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.NonemptyDict.NonemptyDict ( Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId, Evergreen.V243.Id.ThreadRoute ) Evergreen.V243.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V243.RichText.Domain
    , emojiConfig : Evergreen.V243.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V243.Id.Id Evergreen.V243.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V243.Id.Id Evergreen.V243.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V243.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V243.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V243.PersonName.PersonName
    , icon : Maybe Evergreen.V243.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V243.PersonName.PersonName
    , icon : Maybe Evergreen.V243.FileStatus.FileHash
    , email : Maybe Evergreen.V243.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V243.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V243.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V243.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.StickerId) Evergreen.V243.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.CustomEmojiId) Evergreen.V243.CustomEmoji.CustomEmojiData
    }
