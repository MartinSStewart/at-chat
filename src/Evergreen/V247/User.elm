module Evergreen.V247.User exposing (..)

import Effect.Time
import Evergreen.V247.CustomEmoji
import Evergreen.V247.Discord
import Evergreen.V247.DiscordUserData
import Evergreen.V247.EmailAddress
import Evergreen.V247.Emoji
import Evergreen.V247.FileStatus
import Evergreen.V247.Id
import Evergreen.V247.NonemptyDict
import Evergreen.V247.OneOrGreater
import Evergreen.V247.Pagination
import Evergreen.V247.PersonName
import Evergreen.V247.RichText
import Evergreen.V247.Sticker
import Evergreen.V247.UserAgent
import Evergreen.V247.UserSession
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
    = DmChannelLastViewed (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) Evergreen.V247.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V247.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V247.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V247.Id.Id Evergreen.V247.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V247.Id.AnyGuildOrDmId (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V247.Id.AnyGuildOrDmId, Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId ) (Evergreen.V247.Id.Id Evergreen.V247.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) ( Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelId, Evergreen.V247.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) ( Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId, Evergreen.V247.Id.ThreadRoute )
    , icon : Maybe Evergreen.V247.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) (Evergreen.V247.NonemptyDict.NonemptyDict ( Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelId, Evergreen.V247.Id.ThreadRoute ) Evergreen.V247.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.NonemptyDict.NonemptyDict ( Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId, Evergreen.V247.Id.ThreadRoute ) Evergreen.V247.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V247.RichText.Domain
    , emojiConfig : Evergreen.V247.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V247.Id.Id Evergreen.V247.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V247.Id.Id Evergreen.V247.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V247.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V247.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V247.PersonName.PersonName
    , icon : Maybe Evergreen.V247.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V247.PersonName.PersonName
    , icon : Maybe Evergreen.V247.FileStatus.FileHash
    , email : Maybe Evergreen.V247.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V247.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V247.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V247.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.StickerId) Evergreen.V247.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.CustomEmojiId) Evergreen.V247.CustomEmoji.CustomEmojiData
    }
