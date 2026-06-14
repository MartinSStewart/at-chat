module Evergreen.V289.User exposing (..)

import Effect.Time
import Evergreen.V289.CustomEmoji
import Evergreen.V289.Discord
import Evergreen.V289.DiscordUserData
import Evergreen.V289.EmailAddress
import Evergreen.V289.Emoji
import Evergreen.V289.FileStatus
import Evergreen.V289.Id
import Evergreen.V289.NonemptyDict
import Evergreen.V289.OneOrGreater
import Evergreen.V289.Pagination
import Evergreen.V289.PersonName
import Evergreen.V289.RichText
import Evergreen.V289.Sticker
import Evergreen.V289.UserAgent
import Evergreen.V289.UserSession
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
    = DmChannelLastViewed (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) Evergreen.V289.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V289.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V289.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V289.Id.Id Evergreen.V289.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V289.Id.AnyGuildOrDmId (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V289.Id.AnyGuildOrDmId, Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId ) (Evergreen.V289.Id.Id Evergreen.V289.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) ( Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelId, Evergreen.V289.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) ( Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId, Evergreen.V289.Id.ThreadRoute )
    , icon : Maybe Evergreen.V289.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) (Evergreen.V289.NonemptyDict.NonemptyDict ( Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelId, Evergreen.V289.Id.ThreadRoute ) Evergreen.V289.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.NonemptyDict.NonemptyDict ( Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId, Evergreen.V289.Id.ThreadRoute ) Evergreen.V289.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V289.RichText.Domain
    , emojiConfig : Evergreen.V289.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V289.Id.Id Evergreen.V289.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V289.Id.Id Evergreen.V289.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V289.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V289.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V289.PersonName.PersonName
    , icon : Maybe Evergreen.V289.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V289.PersonName.PersonName
    , icon : Maybe Evergreen.V289.FileStatus.FileHash
    , email : Maybe Evergreen.V289.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V289.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V289.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V289.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.StickerId) Evergreen.V289.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.CustomEmojiId) Evergreen.V289.CustomEmoji.CustomEmojiData
    }
