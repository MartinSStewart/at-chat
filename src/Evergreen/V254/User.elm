module Evergreen.V254.User exposing (..)

import Effect.Time
import Evergreen.V254.CustomEmoji
import Evergreen.V254.Discord
import Evergreen.V254.DiscordUserData
import Evergreen.V254.EmailAddress
import Evergreen.V254.Emoji
import Evergreen.V254.FileStatus
import Evergreen.V254.Id
import Evergreen.V254.NonemptyDict
import Evergreen.V254.OneOrGreater
import Evergreen.V254.Pagination
import Evergreen.V254.PersonName
import Evergreen.V254.RichText
import Evergreen.V254.Sticker
import Evergreen.V254.UserAgent
import Evergreen.V254.UserSession
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
    = DmChannelLastViewed (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId) Evergreen.V254.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V254.Discord.Id Evergreen.V254.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V254.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V254.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V254.Id.Id Evergreen.V254.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V254.Id.AnyGuildOrDmId (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V254.Id.AnyGuildOrDmId, Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelMessageId ) (Evergreen.V254.Id.Id Evergreen.V254.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.GuildId) ( Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelId, Evergreen.V254.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V254.Discord.Id Evergreen.V254.Discord.GuildId) ( Evergreen.V254.Discord.Id Evergreen.V254.Discord.ChannelId, Evergreen.V254.Id.ThreadRoute )
    , icon : Maybe Evergreen.V254.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V254.Id.Id Evergreen.V254.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V254.Discord.Id Evergreen.V254.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.GuildId) (Evergreen.V254.NonemptyDict.NonemptyDict ( Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelId, Evergreen.V254.Id.ThreadRoute ) Evergreen.V254.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V254.Discord.Id Evergreen.V254.Discord.GuildId) (Evergreen.V254.NonemptyDict.NonemptyDict ( Evergreen.V254.Discord.Id Evergreen.V254.Discord.ChannelId, Evergreen.V254.Id.ThreadRoute ) Evergreen.V254.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V254.Id.Id Evergreen.V254.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V254.Discord.Id Evergreen.V254.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V254.RichText.Domain
    , emojiConfig : Evergreen.V254.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V254.Id.Id Evergreen.V254.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V254.Id.Id Evergreen.V254.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V254.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V254.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V254.PersonName.PersonName
    , icon : Maybe Evergreen.V254.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V254.PersonName.PersonName
    , icon : Maybe Evergreen.V254.FileStatus.FileHash
    , email : Maybe Evergreen.V254.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V254.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V254.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V254.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.StickerId) Evergreen.V254.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.CustomEmojiId) Evergreen.V254.CustomEmoji.CustomEmojiData
    }
