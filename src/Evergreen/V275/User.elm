module Evergreen.V275.User exposing (..)

import Effect.Time
import Evergreen.V275.CustomEmoji
import Evergreen.V275.Discord
import Evergreen.V275.DiscordUserData
import Evergreen.V275.EmailAddress
import Evergreen.V275.Emoji
import Evergreen.V275.FileStatus
import Evergreen.V275.Id
import Evergreen.V275.NonemptyDict
import Evergreen.V275.OneOrGreater
import Evergreen.V275.Pagination
import Evergreen.V275.PersonName
import Evergreen.V275.RichText
import Evergreen.V275.Sticker
import Evergreen.V275.UserAgent
import Evergreen.V275.UserSession
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
    = DmChannelLastViewed (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) Evergreen.V275.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V275.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V275.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V275.Id.Id Evergreen.V275.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V275.Id.AnyGuildOrDmId (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V275.Id.AnyGuildOrDmId, Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId ) (Evergreen.V275.Id.Id Evergreen.V275.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) ( Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelId, Evergreen.V275.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) ( Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId, Evergreen.V275.Id.ThreadRoute )
    , icon : Maybe Evergreen.V275.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) (Evergreen.V275.NonemptyDict.NonemptyDict ( Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelId, Evergreen.V275.Id.ThreadRoute ) Evergreen.V275.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.NonemptyDict.NonemptyDict ( Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId, Evergreen.V275.Id.ThreadRoute ) Evergreen.V275.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V275.RichText.Domain
    , emojiConfig : Evergreen.V275.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V275.Id.Id Evergreen.V275.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V275.Id.Id Evergreen.V275.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V275.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V275.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V275.PersonName.PersonName
    , icon : Maybe Evergreen.V275.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V275.PersonName.PersonName
    , icon : Maybe Evergreen.V275.FileStatus.FileHash
    , email : Maybe Evergreen.V275.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V275.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V275.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V275.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.StickerId) Evergreen.V275.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.CustomEmojiId) Evergreen.V275.CustomEmoji.CustomEmojiData
    }
