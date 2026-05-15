module Evergreen.V223.User exposing (..)

import Effect.Time
import Evergreen.V223.CustomEmoji
import Evergreen.V223.Discord
import Evergreen.V223.DiscordUserData
import Evergreen.V223.EmailAddress
import Evergreen.V223.Emoji
import Evergreen.V223.FileStatus
import Evergreen.V223.Id
import Evergreen.V223.NonemptyDict
import Evergreen.V223.OneOrGreater
import Evergreen.V223.Pagination
import Evergreen.V223.PersonName
import Evergreen.V223.RichText
import Evergreen.V223.Sticker
import Evergreen.V223.UserAgent
import Evergreen.V223.UserSession
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
    = DmChannelLastViewed (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId) Evergreen.V223.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V223.Discord.Id Evergreen.V223.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V223.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V223.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V223.Id.Id Evergreen.V223.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V223.Id.AnyGuildOrDmId (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V223.Id.AnyGuildOrDmId, Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelMessageId ) (Evergreen.V223.Id.Id Evergreen.V223.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.GuildId) ( Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelId, Evergreen.V223.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V223.Discord.Id Evergreen.V223.Discord.GuildId) ( Evergreen.V223.Discord.Id Evergreen.V223.Discord.ChannelId, Evergreen.V223.Id.ThreadRoute )
    , icon : Maybe Evergreen.V223.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V223.Id.Id Evergreen.V223.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V223.Discord.Id Evergreen.V223.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.GuildId) (Evergreen.V223.NonemptyDict.NonemptyDict ( Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelId, Evergreen.V223.Id.ThreadRoute ) Evergreen.V223.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V223.Discord.Id Evergreen.V223.Discord.GuildId) (Evergreen.V223.NonemptyDict.NonemptyDict ( Evergreen.V223.Discord.Id Evergreen.V223.Discord.ChannelId, Evergreen.V223.Id.ThreadRoute ) Evergreen.V223.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V223.Id.Id Evergreen.V223.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V223.Discord.Id Evergreen.V223.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V223.RichText.Domain
    , emojiConfig : Evergreen.V223.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V223.Id.Id Evergreen.V223.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V223.Id.Id Evergreen.V223.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V223.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V223.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V223.PersonName.PersonName
    , icon : Maybe Evergreen.V223.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V223.PersonName.PersonName
    , icon : Maybe Evergreen.V223.FileStatus.FileHash
    , email : Maybe Evergreen.V223.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V223.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V223.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V223.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.StickerId) Evergreen.V223.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.CustomEmojiId) Evergreen.V223.CustomEmoji.CustomEmojiData
    }
