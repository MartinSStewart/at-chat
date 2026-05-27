module Evergreen.V257.User exposing (..)

import Effect.Time
import Evergreen.V257.CustomEmoji
import Evergreen.V257.Discord
import Evergreen.V257.DiscordUserData
import Evergreen.V257.EmailAddress
import Evergreen.V257.Emoji
import Evergreen.V257.FileStatus
import Evergreen.V257.Id
import Evergreen.V257.NonemptyDict
import Evergreen.V257.OneOrGreater
import Evergreen.V257.Pagination
import Evergreen.V257.PersonName
import Evergreen.V257.RichText
import Evergreen.V257.Sticker
import Evergreen.V257.UserAgent
import Evergreen.V257.UserSession
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
    = DmChannelLastViewed (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) Evergreen.V257.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V257.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V257.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V257.Id.Id Evergreen.V257.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V257.Id.AnyGuildOrDmId (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V257.Id.AnyGuildOrDmId, Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId ) (Evergreen.V257.Id.Id Evergreen.V257.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) ( Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelId, Evergreen.V257.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) ( Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId, Evergreen.V257.Id.ThreadRoute )
    , icon : Maybe Evergreen.V257.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) (Evergreen.V257.NonemptyDict.NonemptyDict ( Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelId, Evergreen.V257.Id.ThreadRoute ) Evergreen.V257.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.NonemptyDict.NonemptyDict ( Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId, Evergreen.V257.Id.ThreadRoute ) Evergreen.V257.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V257.RichText.Domain
    , emojiConfig : Evergreen.V257.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V257.Id.Id Evergreen.V257.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V257.Id.Id Evergreen.V257.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V257.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V257.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V257.PersonName.PersonName
    , icon : Maybe Evergreen.V257.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V257.PersonName.PersonName
    , icon : Maybe Evergreen.V257.FileStatus.FileHash
    , email : Maybe Evergreen.V257.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V257.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V257.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V257.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.StickerId) Evergreen.V257.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.CustomEmojiId) Evergreen.V257.CustomEmoji.CustomEmojiData
    }
