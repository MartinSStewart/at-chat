module Evergreen.V267.User exposing (..)

import Effect.Time
import Evergreen.V267.CustomEmoji
import Evergreen.V267.Discord
import Evergreen.V267.DiscordUserData
import Evergreen.V267.EmailAddress
import Evergreen.V267.Emoji
import Evergreen.V267.FileStatus
import Evergreen.V267.Id
import Evergreen.V267.NonemptyDict
import Evergreen.V267.OneOrGreater
import Evergreen.V267.Pagination
import Evergreen.V267.PersonName
import Evergreen.V267.RichText
import Evergreen.V267.Sticker
import Evergreen.V267.UserAgent
import Evergreen.V267.UserSession
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
    = DmChannelLastViewed (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) Evergreen.V267.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V267.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V267.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V267.Id.Id Evergreen.V267.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V267.Id.AnyGuildOrDmId (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V267.Id.AnyGuildOrDmId, Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId ) (Evergreen.V267.Id.Id Evergreen.V267.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) ( Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelId, Evergreen.V267.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) ( Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId, Evergreen.V267.Id.ThreadRoute )
    , icon : Maybe Evergreen.V267.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) (Evergreen.V267.NonemptyDict.NonemptyDict ( Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelId, Evergreen.V267.Id.ThreadRoute ) Evergreen.V267.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.NonemptyDict.NonemptyDict ( Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId, Evergreen.V267.Id.ThreadRoute ) Evergreen.V267.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V267.RichText.Domain
    , emojiConfig : Evergreen.V267.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V267.Id.Id Evergreen.V267.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V267.Id.Id Evergreen.V267.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V267.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V267.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V267.PersonName.PersonName
    , icon : Maybe Evergreen.V267.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V267.PersonName.PersonName
    , icon : Maybe Evergreen.V267.FileStatus.FileHash
    , email : Maybe Evergreen.V267.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V267.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V267.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V267.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.StickerId) Evergreen.V267.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.CustomEmojiId) Evergreen.V267.CustomEmoji.CustomEmojiData
    }
