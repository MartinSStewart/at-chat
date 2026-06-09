module Evergreen.V283.User exposing (..)

import Effect.Time
import Evergreen.V283.CustomEmoji
import Evergreen.V283.Discord
import Evergreen.V283.DiscordUserData
import Evergreen.V283.EmailAddress
import Evergreen.V283.Emoji
import Evergreen.V283.FileStatus
import Evergreen.V283.Id
import Evergreen.V283.NonemptyDict
import Evergreen.V283.OneOrGreater
import Evergreen.V283.Pagination
import Evergreen.V283.PersonName
import Evergreen.V283.RichText
import Evergreen.V283.Sticker
import Evergreen.V283.UserAgent
import Evergreen.V283.UserSession
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
    = DmChannelLastViewed (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) Evergreen.V283.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V283.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V283.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V283.Id.Id Evergreen.V283.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V283.Id.AnyGuildOrDmId (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V283.Id.AnyGuildOrDmId, Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId ) (Evergreen.V283.Id.Id Evergreen.V283.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) ( Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelId, Evergreen.V283.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) ( Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId, Evergreen.V283.Id.ThreadRoute )
    , icon : Maybe Evergreen.V283.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) (Evergreen.V283.NonemptyDict.NonemptyDict ( Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelId, Evergreen.V283.Id.ThreadRoute ) Evergreen.V283.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.NonemptyDict.NonemptyDict ( Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId, Evergreen.V283.Id.ThreadRoute ) Evergreen.V283.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V283.RichText.Domain
    , emojiConfig : Evergreen.V283.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V283.Id.Id Evergreen.V283.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V283.Id.Id Evergreen.V283.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V283.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V283.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V283.PersonName.PersonName
    , icon : Maybe Evergreen.V283.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V283.PersonName.PersonName
    , icon : Maybe Evergreen.V283.FileStatus.FileHash
    , email : Maybe Evergreen.V283.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V283.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V283.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V283.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.StickerId) Evergreen.V283.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.CustomEmojiId) Evergreen.V283.CustomEmoji.CustomEmojiData
    }
