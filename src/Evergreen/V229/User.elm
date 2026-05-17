module Evergreen.V229.User exposing (..)

import Effect.Time
import Evergreen.V229.CustomEmoji
import Evergreen.V229.Discord
import Evergreen.V229.DiscordUserData
import Evergreen.V229.EmailAddress
import Evergreen.V229.Emoji
import Evergreen.V229.FileStatus
import Evergreen.V229.Id
import Evergreen.V229.NonemptyDict
import Evergreen.V229.OneOrGreater
import Evergreen.V229.Pagination
import Evergreen.V229.PersonName
import Evergreen.V229.RichText
import Evergreen.V229.Sticker
import Evergreen.V229.UserAgent
import Evergreen.V229.UserSession
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
    = DmChannelLastViewed (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) Evergreen.V229.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V229.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V229.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V229.Id.Id Evergreen.V229.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V229.Id.AnyGuildOrDmId (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V229.Id.AnyGuildOrDmId, Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId ) (Evergreen.V229.Id.Id Evergreen.V229.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) ( Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelId, Evergreen.V229.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) ( Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId, Evergreen.V229.Id.ThreadRoute )
    , icon : Maybe Evergreen.V229.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) (Evergreen.V229.NonemptyDict.NonemptyDict ( Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelId, Evergreen.V229.Id.ThreadRoute ) Evergreen.V229.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.NonemptyDict.NonemptyDict ( Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId, Evergreen.V229.Id.ThreadRoute ) Evergreen.V229.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V229.RichText.Domain
    , emojiConfig : Evergreen.V229.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V229.Id.Id Evergreen.V229.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V229.Id.Id Evergreen.V229.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V229.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V229.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V229.PersonName.PersonName
    , icon : Maybe Evergreen.V229.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V229.PersonName.PersonName
    , icon : Maybe Evergreen.V229.FileStatus.FileHash
    , email : Maybe Evergreen.V229.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V229.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V229.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V229.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.StickerId) Evergreen.V229.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.CustomEmojiId) Evergreen.V229.CustomEmoji.CustomEmojiData
    }
