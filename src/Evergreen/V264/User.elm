module Evergreen.V264.User exposing (..)

import Effect.Time
import Evergreen.V264.CustomEmoji
import Evergreen.V264.Discord
import Evergreen.V264.DiscordUserData
import Evergreen.V264.EmailAddress
import Evergreen.V264.Emoji
import Evergreen.V264.FileStatus
import Evergreen.V264.Id
import Evergreen.V264.NonemptyDict
import Evergreen.V264.OneOrGreater
import Evergreen.V264.Pagination
import Evergreen.V264.PersonName
import Evergreen.V264.RichText
import Evergreen.V264.Sticker
import Evergreen.V264.UserAgent
import Evergreen.V264.UserSession
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
    = DmChannelLastViewed (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) Evergreen.V264.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V264.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V264.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V264.Id.Id Evergreen.V264.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V264.Id.AnyGuildOrDmId (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V264.Id.AnyGuildOrDmId, Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId ) (Evergreen.V264.Id.Id Evergreen.V264.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) ( Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelId, Evergreen.V264.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) ( Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId, Evergreen.V264.Id.ThreadRoute )
    , icon : Maybe Evergreen.V264.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) (Evergreen.V264.NonemptyDict.NonemptyDict ( Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelId, Evergreen.V264.Id.ThreadRoute ) Evergreen.V264.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.NonemptyDict.NonemptyDict ( Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId, Evergreen.V264.Id.ThreadRoute ) Evergreen.V264.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V264.RichText.Domain
    , emojiConfig : Evergreen.V264.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V264.Id.Id Evergreen.V264.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V264.Id.Id Evergreen.V264.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V264.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V264.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V264.PersonName.PersonName
    , icon : Maybe Evergreen.V264.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V264.PersonName.PersonName
    , icon : Maybe Evergreen.V264.FileStatus.FileHash
    , email : Maybe Evergreen.V264.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V264.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V264.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V264.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.StickerId) Evergreen.V264.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.CustomEmojiId) Evergreen.V264.CustomEmoji.CustomEmojiData
    }
