module Evergreen.V217.User exposing (..)

import Effect.Time
import Evergreen.V217.CustomEmoji
import Evergreen.V217.Discord
import Evergreen.V217.DiscordUserData
import Evergreen.V217.EmailAddress
import Evergreen.V217.Emoji
import Evergreen.V217.FileStatus
import Evergreen.V217.Id
import Evergreen.V217.NonemptyDict
import Evergreen.V217.OneOrGreater
import Evergreen.V217.Pagination
import Evergreen.V217.PersonName
import Evergreen.V217.RichText
import Evergreen.V217.Sticker
import Evergreen.V217.UserAgent
import Evergreen.V217.UserSession
import SeqDict
import SeqSet


type AdminUiSection
    = UsersSection
    | LogSection
    | DiscordDmChannelsSection
    | DiscordUsersSection
    | DiscordGuildsSection
    | GuildsSection
    | ApiKeysSection
    | ExportSection
    | ConnectionsSection
    | FilesSection
    | ToBackendLogsSection
    | StickersAndEmojisSection
    | VoiceChatSection


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) Evergreen.V217.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V217.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V217.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V217.Id.Id Evergreen.V217.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V217.Id.AnyGuildOrDmId (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V217.Id.AnyGuildOrDmId, Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId ) (Evergreen.V217.Id.Id Evergreen.V217.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) ( Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelId, Evergreen.V217.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) ( Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId, Evergreen.V217.Id.ThreadRoute )
    , icon : Maybe Evergreen.V217.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) (Evergreen.V217.NonemptyDict.NonemptyDict ( Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelId, Evergreen.V217.Id.ThreadRoute ) Evergreen.V217.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.NonemptyDict.NonemptyDict ( Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId, Evergreen.V217.Id.ThreadRoute ) Evergreen.V217.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V217.RichText.Domain
    , emojiConfig : Evergreen.V217.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V217.Id.Id Evergreen.V217.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V217.Id.Id Evergreen.V217.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V217.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V217.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V217.PersonName.PersonName
    , icon : Maybe Evergreen.V217.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V217.PersonName.PersonName
    , icon : Maybe Evergreen.V217.FileStatus.FileHash
    , email : Maybe Evergreen.V217.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V217.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V217.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V217.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.StickerId) Evergreen.V217.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.CustomEmojiId) Evergreen.V217.CustomEmoji.CustomEmojiData
    }
