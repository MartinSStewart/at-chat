module Evergreen.V279.User exposing (..)

import Effect.Time
import Evergreen.V279.CustomEmoji
import Evergreen.V279.Discord
import Evergreen.V279.DiscordUserData
import Evergreen.V279.EmailAddress
import Evergreen.V279.Emoji
import Evergreen.V279.FileStatus
import Evergreen.V279.Id
import Evergreen.V279.NonemptyDict
import Evergreen.V279.OneOrGreater
import Evergreen.V279.Pagination
import Evergreen.V279.PersonName
import Evergreen.V279.RichText
import Evergreen.V279.Sticker
import Evergreen.V279.UserAgent
import Evergreen.V279.UserSession
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
    = DmChannelLastViewed (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) Evergreen.V279.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V279.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V279.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V279.Id.Id Evergreen.V279.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V279.Id.AnyGuildOrDmId (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V279.Id.AnyGuildOrDmId, Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId ) (Evergreen.V279.Id.Id Evergreen.V279.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) ( Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelId, Evergreen.V279.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) ( Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId, Evergreen.V279.Id.ThreadRoute )
    , icon : Maybe Evergreen.V279.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) (Evergreen.V279.NonemptyDict.NonemptyDict ( Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelId, Evergreen.V279.Id.ThreadRoute ) Evergreen.V279.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.NonemptyDict.NonemptyDict ( Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId, Evergreen.V279.Id.ThreadRoute ) Evergreen.V279.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V279.RichText.Domain
    , emojiConfig : Evergreen.V279.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V279.Id.Id Evergreen.V279.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V279.Id.Id Evergreen.V279.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V279.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V279.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V279.PersonName.PersonName
    , icon : Maybe Evergreen.V279.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V279.PersonName.PersonName
    , icon : Maybe Evergreen.V279.FileStatus.FileHash
    , email : Maybe Evergreen.V279.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V279.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V279.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V279.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.StickerId) Evergreen.V279.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.CustomEmojiId) Evergreen.V279.CustomEmoji.CustomEmojiData
    }
