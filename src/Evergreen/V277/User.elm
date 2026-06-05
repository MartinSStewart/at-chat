module Evergreen.V277.User exposing (..)

import Effect.Time
import Evergreen.V277.CustomEmoji
import Evergreen.V277.Discord
import Evergreen.V277.DiscordUserData
import Evergreen.V277.EmailAddress
import Evergreen.V277.Emoji
import Evergreen.V277.FileStatus
import Evergreen.V277.Id
import Evergreen.V277.NonemptyDict
import Evergreen.V277.OneOrGreater
import Evergreen.V277.Pagination
import Evergreen.V277.PersonName
import Evergreen.V277.RichText
import Evergreen.V277.Sticker
import Evergreen.V277.UserAgent
import Evergreen.V277.UserSession
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
    = DmChannelLastViewed (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) Evergreen.V277.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V277.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V277.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V277.Id.Id Evergreen.V277.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V277.Id.AnyGuildOrDmId (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V277.Id.AnyGuildOrDmId, Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId ) (Evergreen.V277.Id.Id Evergreen.V277.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) ( Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelId, Evergreen.V277.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) ( Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId, Evergreen.V277.Id.ThreadRoute )
    , icon : Maybe Evergreen.V277.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) (Evergreen.V277.NonemptyDict.NonemptyDict ( Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelId, Evergreen.V277.Id.ThreadRoute ) Evergreen.V277.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.NonemptyDict.NonemptyDict ( Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId, Evergreen.V277.Id.ThreadRoute ) Evergreen.V277.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V277.RichText.Domain
    , emojiConfig : Evergreen.V277.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V277.Id.Id Evergreen.V277.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V277.Id.Id Evergreen.V277.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V277.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V277.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V277.PersonName.PersonName
    , icon : Maybe Evergreen.V277.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V277.PersonName.PersonName
    , icon : Maybe Evergreen.V277.FileStatus.FileHash
    , email : Maybe Evergreen.V277.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V277.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V277.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V277.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.StickerId) Evergreen.V277.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.CustomEmojiId) Evergreen.V277.CustomEmoji.CustomEmojiData
    }
