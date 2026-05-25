module Evergreen.V252.User exposing (..)

import Effect.Time
import Evergreen.V252.CustomEmoji
import Evergreen.V252.Discord
import Evergreen.V252.DiscordUserData
import Evergreen.V252.EmailAddress
import Evergreen.V252.Emoji
import Evergreen.V252.FileStatus
import Evergreen.V252.Id
import Evergreen.V252.NonemptyDict
import Evergreen.V252.OneOrGreater
import Evergreen.V252.Pagination
import Evergreen.V252.PersonName
import Evergreen.V252.RichText
import Evergreen.V252.Sticker
import Evergreen.V252.UserAgent
import Evergreen.V252.UserSession
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
    = DmChannelLastViewed (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) Evergreen.V252.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V252.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V252.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V252.Id.Id Evergreen.V252.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V252.Id.AnyGuildOrDmId (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V252.Id.AnyGuildOrDmId, Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId ) (Evergreen.V252.Id.Id Evergreen.V252.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) ( Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelId, Evergreen.V252.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) ( Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId, Evergreen.V252.Id.ThreadRoute )
    , icon : Maybe Evergreen.V252.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) (Evergreen.V252.NonemptyDict.NonemptyDict ( Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelId, Evergreen.V252.Id.ThreadRoute ) Evergreen.V252.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.NonemptyDict.NonemptyDict ( Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId, Evergreen.V252.Id.ThreadRoute ) Evergreen.V252.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V252.RichText.Domain
    , emojiConfig : Evergreen.V252.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V252.Id.Id Evergreen.V252.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V252.Id.Id Evergreen.V252.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V252.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V252.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V252.PersonName.PersonName
    , icon : Maybe Evergreen.V252.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V252.PersonName.PersonName
    , icon : Maybe Evergreen.V252.FileStatus.FileHash
    , email : Maybe Evergreen.V252.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V252.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V252.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V252.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.StickerId) Evergreen.V252.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.CustomEmojiId) Evergreen.V252.CustomEmoji.CustomEmojiData
    }
