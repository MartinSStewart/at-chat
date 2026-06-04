module Evergreen.V271.User exposing (..)

import Effect.Time
import Evergreen.V271.CustomEmoji
import Evergreen.V271.Discord
import Evergreen.V271.DiscordUserData
import Evergreen.V271.EmailAddress
import Evergreen.V271.Emoji
import Evergreen.V271.FileStatus
import Evergreen.V271.Id
import Evergreen.V271.NonemptyDict
import Evergreen.V271.OneOrGreater
import Evergreen.V271.Pagination
import Evergreen.V271.PersonName
import Evergreen.V271.RichText
import Evergreen.V271.Sticker
import Evergreen.V271.UserAgent
import Evergreen.V271.UserSession
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
    = DmChannelLastViewed (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) Evergreen.V271.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V271.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V271.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V271.Id.Id Evergreen.V271.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V271.Id.AnyGuildOrDmId (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V271.Id.AnyGuildOrDmId, Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId ) (Evergreen.V271.Id.Id Evergreen.V271.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) ( Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelId, Evergreen.V271.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) ( Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId, Evergreen.V271.Id.ThreadRoute )
    , icon : Maybe Evergreen.V271.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) (Evergreen.V271.NonemptyDict.NonemptyDict ( Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelId, Evergreen.V271.Id.ThreadRoute ) Evergreen.V271.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.NonemptyDict.NonemptyDict ( Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId, Evergreen.V271.Id.ThreadRoute ) Evergreen.V271.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V271.RichText.Domain
    , emojiConfig : Evergreen.V271.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V271.Id.Id Evergreen.V271.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V271.Id.Id Evergreen.V271.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V271.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V271.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V271.PersonName.PersonName
    , icon : Maybe Evergreen.V271.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V271.PersonName.PersonName
    , icon : Maybe Evergreen.V271.FileStatus.FileHash
    , email : Maybe Evergreen.V271.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V271.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V271.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V271.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.StickerId) Evergreen.V271.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.CustomEmojiId) Evergreen.V271.CustomEmoji.CustomEmojiData
    }
