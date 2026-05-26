module Evergreen.V255.User exposing (..)

import Effect.Time
import Evergreen.V255.CustomEmoji
import Evergreen.V255.Discord
import Evergreen.V255.DiscordUserData
import Evergreen.V255.EmailAddress
import Evergreen.V255.Emoji
import Evergreen.V255.FileStatus
import Evergreen.V255.Id
import Evergreen.V255.NonemptyDict
import Evergreen.V255.OneOrGreater
import Evergreen.V255.Pagination
import Evergreen.V255.PersonName
import Evergreen.V255.RichText
import Evergreen.V255.Sticker
import Evergreen.V255.UserAgent
import Evergreen.V255.UserSession
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
    = DmChannelLastViewed (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) Evergreen.V255.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V255.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V255.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V255.Id.Id Evergreen.V255.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V255.Id.AnyGuildOrDmId (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V255.Id.AnyGuildOrDmId, Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId ) (Evergreen.V255.Id.Id Evergreen.V255.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) ( Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelId, Evergreen.V255.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) ( Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId, Evergreen.V255.Id.ThreadRoute )
    , icon : Maybe Evergreen.V255.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) (Evergreen.V255.NonemptyDict.NonemptyDict ( Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelId, Evergreen.V255.Id.ThreadRoute ) Evergreen.V255.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.NonemptyDict.NonemptyDict ( Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId, Evergreen.V255.Id.ThreadRoute ) Evergreen.V255.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V255.RichText.Domain
    , emojiConfig : Evergreen.V255.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V255.Id.Id Evergreen.V255.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V255.Id.Id Evergreen.V255.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V255.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V255.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V255.PersonName.PersonName
    , icon : Maybe Evergreen.V255.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V255.PersonName.PersonName
    , icon : Maybe Evergreen.V255.FileStatus.FileHash
    , email : Maybe Evergreen.V255.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V255.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V255.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V255.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.StickerId) Evergreen.V255.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.CustomEmojiId) Evergreen.V255.CustomEmoji.CustomEmojiData
    }
