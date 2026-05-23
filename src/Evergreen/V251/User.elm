module Evergreen.V251.User exposing (..)

import Effect.Time
import Evergreen.V251.CustomEmoji
import Evergreen.V251.Discord
import Evergreen.V251.DiscordUserData
import Evergreen.V251.EmailAddress
import Evergreen.V251.Emoji
import Evergreen.V251.FileStatus
import Evergreen.V251.Id
import Evergreen.V251.NonemptyDict
import Evergreen.V251.OneOrGreater
import Evergreen.V251.Pagination
import Evergreen.V251.PersonName
import Evergreen.V251.RichText
import Evergreen.V251.Sticker
import Evergreen.V251.UserAgent
import Evergreen.V251.UserSession
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
    | WebsocketCloseEventsSection


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) Evergreen.V251.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V251.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V251.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V251.Id.Id Evergreen.V251.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V251.Id.AnyGuildOrDmId (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V251.Id.AnyGuildOrDmId, Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId ) (Evergreen.V251.Id.Id Evergreen.V251.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) ( Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelId, Evergreen.V251.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) ( Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId, Evergreen.V251.Id.ThreadRoute )
    , icon : Maybe Evergreen.V251.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) (Evergreen.V251.NonemptyDict.NonemptyDict ( Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelId, Evergreen.V251.Id.ThreadRoute ) Evergreen.V251.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.NonemptyDict.NonemptyDict ( Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId, Evergreen.V251.Id.ThreadRoute ) Evergreen.V251.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V251.RichText.Domain
    , emojiConfig : Evergreen.V251.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V251.Id.Id Evergreen.V251.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V251.Id.Id Evergreen.V251.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V251.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V251.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V251.PersonName.PersonName
    , icon : Maybe Evergreen.V251.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V251.PersonName.PersonName
    , icon : Maybe Evergreen.V251.FileStatus.FileHash
    , email : Maybe Evergreen.V251.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V251.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V251.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V251.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.StickerId) Evergreen.V251.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.CustomEmojiId) Evergreen.V251.CustomEmoji.CustomEmojiData
    }
