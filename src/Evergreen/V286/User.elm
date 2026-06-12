module Evergreen.V286.User exposing (..)

import Effect.Time
import Evergreen.V286.CustomEmoji
import Evergreen.V286.Discord
import Evergreen.V286.DiscordUserData
import Evergreen.V286.EmailAddress
import Evergreen.V286.Emoji
import Evergreen.V286.FileStatus
import Evergreen.V286.Id
import Evergreen.V286.NonemptyDict
import Evergreen.V286.OneOrGreater
import Evergreen.V286.Pagination
import Evergreen.V286.PersonName
import Evergreen.V286.RichText
import Evergreen.V286.Sticker
import Evergreen.V286.UserAgent
import Evergreen.V286.UserSession
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
    = DmChannelLastViewed (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) Evergreen.V286.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V286.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V286.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V286.Id.Id Evergreen.V286.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V286.Id.AnyGuildOrDmId (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V286.Id.AnyGuildOrDmId, Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId ) (Evergreen.V286.Id.Id Evergreen.V286.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) ( Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelId, Evergreen.V286.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) ( Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId, Evergreen.V286.Id.ThreadRoute )
    , icon : Maybe Evergreen.V286.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) (Evergreen.V286.NonemptyDict.NonemptyDict ( Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelId, Evergreen.V286.Id.ThreadRoute ) Evergreen.V286.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.NonemptyDict.NonemptyDict ( Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId, Evergreen.V286.Id.ThreadRoute ) Evergreen.V286.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V286.RichText.Domain
    , emojiConfig : Evergreen.V286.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V286.Id.Id Evergreen.V286.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V286.Id.Id Evergreen.V286.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V286.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V286.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V286.PersonName.PersonName
    , icon : Maybe Evergreen.V286.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V286.PersonName.PersonName
    , icon : Maybe Evergreen.V286.FileStatus.FileHash
    , email : Maybe Evergreen.V286.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V286.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V286.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V286.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.StickerId) Evergreen.V286.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.CustomEmojiId) Evergreen.V286.CustomEmoji.CustomEmojiData
    }
