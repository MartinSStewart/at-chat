module Evergreen.V232.User exposing (..)

import Effect.Time
import Evergreen.V232.CustomEmoji
import Evergreen.V232.Discord
import Evergreen.V232.DiscordUserData
import Evergreen.V232.EmailAddress
import Evergreen.V232.Emoji
import Evergreen.V232.FileStatus
import Evergreen.V232.Id
import Evergreen.V232.NonemptyDict
import Evergreen.V232.OneOrGreater
import Evergreen.V232.Pagination
import Evergreen.V232.PersonName
import Evergreen.V232.RichText
import Evergreen.V232.Sticker
import Evergreen.V232.UserAgent
import Evergreen.V232.UserSession
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
    = DmChannelLastViewed (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) Evergreen.V232.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V232.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V232.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V232.Id.Id Evergreen.V232.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V232.Id.AnyGuildOrDmId (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V232.Id.AnyGuildOrDmId, Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId ) (Evergreen.V232.Id.Id Evergreen.V232.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) ( Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelId, Evergreen.V232.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) ( Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId, Evergreen.V232.Id.ThreadRoute )
    , icon : Maybe Evergreen.V232.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) (Evergreen.V232.NonemptyDict.NonemptyDict ( Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelId, Evergreen.V232.Id.ThreadRoute ) Evergreen.V232.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.NonemptyDict.NonemptyDict ( Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId, Evergreen.V232.Id.ThreadRoute ) Evergreen.V232.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V232.RichText.Domain
    , emojiConfig : Evergreen.V232.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V232.Id.Id Evergreen.V232.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V232.Id.Id Evergreen.V232.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V232.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V232.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V232.PersonName.PersonName
    , icon : Maybe Evergreen.V232.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V232.PersonName.PersonName
    , icon : Maybe Evergreen.V232.FileStatus.FileHash
    , email : Maybe Evergreen.V232.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V232.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V232.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V232.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.StickerId) Evergreen.V232.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.CustomEmojiId) Evergreen.V232.CustomEmoji.CustomEmojiData
    }
