module Evergreen.V270.User exposing (..)

import Effect.Time
import Evergreen.V270.CustomEmoji
import Evergreen.V270.Discord
import Evergreen.V270.DiscordUserData
import Evergreen.V270.EmailAddress
import Evergreen.V270.Emoji
import Evergreen.V270.FileStatus
import Evergreen.V270.Id
import Evergreen.V270.NonemptyDict
import Evergreen.V270.OneOrGreater
import Evergreen.V270.Pagination
import Evergreen.V270.PersonName
import Evergreen.V270.RichText
import Evergreen.V270.Sticker
import Evergreen.V270.UserAgent
import Evergreen.V270.UserSession
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
    = DmChannelLastViewed (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) Evergreen.V270.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V270.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V270.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V270.Id.Id Evergreen.V270.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V270.Id.AnyGuildOrDmId (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V270.Id.AnyGuildOrDmId, Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId ) (Evergreen.V270.Id.Id Evergreen.V270.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) ( Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelId, Evergreen.V270.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) ( Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId, Evergreen.V270.Id.ThreadRoute )
    , icon : Maybe Evergreen.V270.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) (Evergreen.V270.NonemptyDict.NonemptyDict ( Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelId, Evergreen.V270.Id.ThreadRoute ) Evergreen.V270.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.NonemptyDict.NonemptyDict ( Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId, Evergreen.V270.Id.ThreadRoute ) Evergreen.V270.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V270.RichText.Domain
    , emojiConfig : Evergreen.V270.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V270.Id.Id Evergreen.V270.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V270.Id.Id Evergreen.V270.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V270.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V270.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V270.PersonName.PersonName
    , icon : Maybe Evergreen.V270.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V270.PersonName.PersonName
    , icon : Maybe Evergreen.V270.FileStatus.FileHash
    , email : Maybe Evergreen.V270.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V270.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V270.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V270.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.StickerId) Evergreen.V270.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.CustomEmojiId) Evergreen.V270.CustomEmoji.CustomEmojiData
    }
