module Evergreen.V273.User exposing (..)

import Effect.Time
import Evergreen.V273.CustomEmoji
import Evergreen.V273.Discord
import Evergreen.V273.DiscordUserData
import Evergreen.V273.EmailAddress
import Evergreen.V273.Emoji
import Evergreen.V273.FileStatus
import Evergreen.V273.Id
import Evergreen.V273.NonemptyDict
import Evergreen.V273.OneOrGreater
import Evergreen.V273.Pagination
import Evergreen.V273.PersonName
import Evergreen.V273.RichText
import Evergreen.V273.Sticker
import Evergreen.V273.UserAgent
import Evergreen.V273.UserSession
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
    = DmChannelLastViewed (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) Evergreen.V273.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V273.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V273.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V273.Id.Id Evergreen.V273.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V273.Id.AnyGuildOrDmId (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V273.Id.AnyGuildOrDmId, Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId ) (Evergreen.V273.Id.Id Evergreen.V273.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) ( Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelId, Evergreen.V273.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) ( Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId, Evergreen.V273.Id.ThreadRoute )
    , icon : Maybe Evergreen.V273.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) (Evergreen.V273.NonemptyDict.NonemptyDict ( Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelId, Evergreen.V273.Id.ThreadRoute ) Evergreen.V273.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.NonemptyDict.NonemptyDict ( Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId, Evergreen.V273.Id.ThreadRoute ) Evergreen.V273.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V273.RichText.Domain
    , emojiConfig : Evergreen.V273.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V273.Id.Id Evergreen.V273.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V273.Id.Id Evergreen.V273.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V273.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V273.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V273.PersonName.PersonName
    , icon : Maybe Evergreen.V273.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V273.PersonName.PersonName
    , icon : Maybe Evergreen.V273.FileStatus.FileHash
    , email : Maybe Evergreen.V273.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V273.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V273.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V273.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.StickerId) Evergreen.V273.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.CustomEmojiId) Evergreen.V273.CustomEmoji.CustomEmojiData
    }
