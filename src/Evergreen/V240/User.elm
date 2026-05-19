module Evergreen.V240.User exposing (..)

import Effect.Time
import Evergreen.V240.CustomEmoji
import Evergreen.V240.Discord
import Evergreen.V240.DiscordUserData
import Evergreen.V240.EmailAddress
import Evergreen.V240.Emoji
import Evergreen.V240.FileStatus
import Evergreen.V240.Id
import Evergreen.V240.NonemptyDict
import Evergreen.V240.OneOrGreater
import Evergreen.V240.Pagination
import Evergreen.V240.PersonName
import Evergreen.V240.RichText
import Evergreen.V240.Sticker
import Evergreen.V240.UserAgent
import Evergreen.V240.UserSession
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


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) Evergreen.V240.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V240.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V240.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V240.Id.Id Evergreen.V240.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V240.Id.AnyGuildOrDmId (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V240.Id.AnyGuildOrDmId, Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId ) (Evergreen.V240.Id.Id Evergreen.V240.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) ( Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelId, Evergreen.V240.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) ( Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId, Evergreen.V240.Id.ThreadRoute )
    , icon : Maybe Evergreen.V240.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) (Evergreen.V240.NonemptyDict.NonemptyDict ( Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelId, Evergreen.V240.Id.ThreadRoute ) Evergreen.V240.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId) (Evergreen.V240.NonemptyDict.NonemptyDict ( Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId, Evergreen.V240.Id.ThreadRoute ) Evergreen.V240.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V240.RichText.Domain
    , emojiConfig : Evergreen.V240.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V240.Id.Id Evergreen.V240.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V240.Id.Id Evergreen.V240.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V240.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V240.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V240.PersonName.PersonName
    , icon : Maybe Evergreen.V240.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V240.PersonName.PersonName
    , icon : Maybe Evergreen.V240.FileStatus.FileHash
    , email : Maybe Evergreen.V240.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V240.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V240.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V240.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.StickerId) Evergreen.V240.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.CustomEmojiId) Evergreen.V240.CustomEmoji.CustomEmojiData
    }
