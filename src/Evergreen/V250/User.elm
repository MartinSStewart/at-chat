module Evergreen.V250.User exposing (..)

import Effect.Time
import Evergreen.V250.CustomEmoji
import Evergreen.V250.Discord
import Evergreen.V250.DiscordUserData
import Evergreen.V250.EmailAddress
import Evergreen.V250.Emoji
import Evergreen.V250.FileStatus
import Evergreen.V250.Id
import Evergreen.V250.NonemptyDict
import Evergreen.V250.OneOrGreater
import Evergreen.V250.Pagination
import Evergreen.V250.PersonName
import Evergreen.V250.RichText
import Evergreen.V250.Sticker
import Evergreen.V250.UserAgent
import Evergreen.V250.UserSession
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
    | WebsocketCloseEventsSection


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) Evergreen.V250.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V250.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V250.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V250.Id.Id Evergreen.V250.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V250.Id.AnyGuildOrDmId (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V250.Id.AnyGuildOrDmId, Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId ) (Evergreen.V250.Id.Id Evergreen.V250.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) ( Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelId, Evergreen.V250.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) ( Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId, Evergreen.V250.Id.ThreadRoute )
    , icon : Maybe Evergreen.V250.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) (Evergreen.V250.NonemptyDict.NonemptyDict ( Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelId, Evergreen.V250.Id.ThreadRoute ) Evergreen.V250.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.NonemptyDict.NonemptyDict ( Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId, Evergreen.V250.Id.ThreadRoute ) Evergreen.V250.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V250.RichText.Domain
    , emojiConfig : Evergreen.V250.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V250.Id.Id Evergreen.V250.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V250.Id.Id Evergreen.V250.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V250.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V250.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V250.PersonName.PersonName
    , icon : Maybe Evergreen.V250.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V250.PersonName.PersonName
    , icon : Maybe Evergreen.V250.FileStatus.FileHash
    , email : Maybe Evergreen.V250.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V250.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V250.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V250.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.StickerId) Evergreen.V250.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.CustomEmojiId) Evergreen.V250.CustomEmoji.CustomEmojiData
    }
