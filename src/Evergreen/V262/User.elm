module Evergreen.V262.User exposing (..)

import Effect.Time
import Evergreen.V262.CustomEmoji
import Evergreen.V262.Discord
import Evergreen.V262.DiscordUserData
import Evergreen.V262.EmailAddress
import Evergreen.V262.Emoji
import Evergreen.V262.FileStatus
import Evergreen.V262.Id
import Evergreen.V262.NonemptyDict
import Evergreen.V262.OneOrGreater
import Evergreen.V262.Pagination
import Evergreen.V262.PersonName
import Evergreen.V262.RichText
import Evergreen.V262.Sticker
import Evergreen.V262.UserAgent
import Evergreen.V262.UserSession
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


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId) Evergreen.V262.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V262.Discord.Id Evergreen.V262.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V262.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V262.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V262.Id.Id Evergreen.V262.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V262.Id.AnyGuildOrDmId (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V262.Id.AnyGuildOrDmId, Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelMessageId ) (Evergreen.V262.Id.Id Evergreen.V262.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.GuildId) ( Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelId, Evergreen.V262.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V262.Discord.Id Evergreen.V262.Discord.GuildId) ( Evergreen.V262.Discord.Id Evergreen.V262.Discord.ChannelId, Evergreen.V262.Id.ThreadRoute )
    , icon : Maybe Evergreen.V262.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V262.Id.Id Evergreen.V262.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V262.Discord.Id Evergreen.V262.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.GuildId) (Evergreen.V262.NonemptyDict.NonemptyDict ( Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelId, Evergreen.V262.Id.ThreadRoute ) Evergreen.V262.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V262.Discord.Id Evergreen.V262.Discord.GuildId) (Evergreen.V262.NonemptyDict.NonemptyDict ( Evergreen.V262.Discord.Id Evergreen.V262.Discord.ChannelId, Evergreen.V262.Id.ThreadRoute ) Evergreen.V262.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V262.Id.Id Evergreen.V262.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V262.Discord.Id Evergreen.V262.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V262.RichText.Domain
    , emojiConfig : Evergreen.V262.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V262.Id.Id Evergreen.V262.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V262.Id.Id Evergreen.V262.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V262.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V262.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V262.PersonName.PersonName
    , icon : Maybe Evergreen.V262.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V262.PersonName.PersonName
    , icon : Maybe Evergreen.V262.FileStatus.FileHash
    , email : Maybe Evergreen.V262.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V262.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V262.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V262.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.StickerId) Evergreen.V262.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.CustomEmojiId) Evergreen.V262.CustomEmoji.CustomEmojiData
    }
