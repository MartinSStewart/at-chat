module Evergreen.V288.User exposing (..)

import Effect.Time
import Evergreen.V288.CustomEmoji
import Evergreen.V288.Discord
import Evergreen.V288.DiscordUserData
import Evergreen.V288.EmailAddress
import Evergreen.V288.Emoji
import Evergreen.V288.FileStatus
import Evergreen.V288.Id
import Evergreen.V288.NonemptyDict
import Evergreen.V288.OneOrGreater
import Evergreen.V288.Pagination
import Evergreen.V288.PersonName
import Evergreen.V288.RichText
import Evergreen.V288.Sticker
import Evergreen.V288.UserAgent
import Evergreen.V288.UserSession
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
    = DmChannelLastViewed (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) Evergreen.V288.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V288.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V288.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V288.Id.Id Evergreen.V288.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V288.Id.AnyGuildOrDmId (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V288.Id.AnyGuildOrDmId, Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId ) (Evergreen.V288.Id.Id Evergreen.V288.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) ( Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelId, Evergreen.V288.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) ( Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId, Evergreen.V288.Id.ThreadRoute )
    , icon : Maybe Evergreen.V288.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) (Evergreen.V288.NonemptyDict.NonemptyDict ( Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelId, Evergreen.V288.Id.ThreadRoute ) Evergreen.V288.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.NonemptyDict.NonemptyDict ( Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId, Evergreen.V288.Id.ThreadRoute ) Evergreen.V288.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V288.RichText.Domain
    , emojiConfig : Evergreen.V288.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V288.Id.Id Evergreen.V288.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V288.Id.Id Evergreen.V288.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V288.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V288.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V288.PersonName.PersonName
    , icon : Maybe Evergreen.V288.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V288.PersonName.PersonName
    , icon : Maybe Evergreen.V288.FileStatus.FileHash
    , email : Maybe Evergreen.V288.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V288.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V288.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V288.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.StickerId) Evergreen.V288.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.CustomEmojiId) Evergreen.V288.CustomEmoji.CustomEmojiData
    }
