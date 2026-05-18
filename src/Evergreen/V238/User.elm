module Evergreen.V238.User exposing (..)

import Effect.Time
import Evergreen.V238.CustomEmoji
import Evergreen.V238.Discord
import Evergreen.V238.DiscordUserData
import Evergreen.V238.EmailAddress
import Evergreen.V238.Emoji
import Evergreen.V238.FileStatus
import Evergreen.V238.Id
import Evergreen.V238.NonemptyDict
import Evergreen.V238.OneOrGreater
import Evergreen.V238.Pagination
import Evergreen.V238.PersonName
import Evergreen.V238.RichText
import Evergreen.V238.Sticker
import Evergreen.V238.UserAgent
import Evergreen.V238.UserSession
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
    = DmChannelLastViewed (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) Evergreen.V238.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V238.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V238.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V238.Id.Id Evergreen.V238.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V238.Id.AnyGuildOrDmId (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V238.Id.AnyGuildOrDmId, Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId ) (Evergreen.V238.Id.Id Evergreen.V238.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) ( Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelId, Evergreen.V238.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) ( Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId, Evergreen.V238.Id.ThreadRoute )
    , icon : Maybe Evergreen.V238.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) (Evergreen.V238.NonemptyDict.NonemptyDict ( Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelId, Evergreen.V238.Id.ThreadRoute ) Evergreen.V238.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.NonemptyDict.NonemptyDict ( Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId, Evergreen.V238.Id.ThreadRoute ) Evergreen.V238.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V238.RichText.Domain
    , emojiConfig : Evergreen.V238.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V238.Id.Id Evergreen.V238.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V238.Id.Id Evergreen.V238.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V238.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V238.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V238.PersonName.PersonName
    , icon : Maybe Evergreen.V238.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V238.PersonName.PersonName
    , icon : Maybe Evergreen.V238.FileStatus.FileHash
    , email : Maybe Evergreen.V238.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V238.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V238.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V238.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.StickerId) Evergreen.V238.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.CustomEmojiId) Evergreen.V238.CustomEmoji.CustomEmojiData
    }
