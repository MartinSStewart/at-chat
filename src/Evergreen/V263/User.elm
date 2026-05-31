module Evergreen.V263.User exposing (..)

import Effect.Time
import Evergreen.V263.CustomEmoji
import Evergreen.V263.Discord
import Evergreen.V263.DiscordUserData
import Evergreen.V263.EmailAddress
import Evergreen.V263.Emoji
import Evergreen.V263.FileStatus
import Evergreen.V263.Id
import Evergreen.V263.NonemptyDict
import Evergreen.V263.OneOrGreater
import Evergreen.V263.Pagination
import Evergreen.V263.PersonName
import Evergreen.V263.RichText
import Evergreen.V263.Sticker
import Evergreen.V263.UserAgent
import Evergreen.V263.UserSession
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
    = DmChannelLastViewed (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) Evergreen.V263.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V263.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V263.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V263.Id.Id Evergreen.V263.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V263.Id.AnyGuildOrDmId (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V263.Id.AnyGuildOrDmId, Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId ) (Evergreen.V263.Id.Id Evergreen.V263.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) ( Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelId, Evergreen.V263.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) ( Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId, Evergreen.V263.Id.ThreadRoute )
    , icon : Maybe Evergreen.V263.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) (Evergreen.V263.NonemptyDict.NonemptyDict ( Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelId, Evergreen.V263.Id.ThreadRoute ) Evergreen.V263.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.NonemptyDict.NonemptyDict ( Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId, Evergreen.V263.Id.ThreadRoute ) Evergreen.V263.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V263.RichText.Domain
    , emojiConfig : Evergreen.V263.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V263.Id.Id Evergreen.V263.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V263.Id.Id Evergreen.V263.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V263.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V263.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V263.PersonName.PersonName
    , icon : Maybe Evergreen.V263.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V263.PersonName.PersonName
    , icon : Maybe Evergreen.V263.FileStatus.FileHash
    , email : Maybe Evergreen.V263.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V263.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V263.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V263.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.StickerId) Evergreen.V263.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.CustomEmojiId) Evergreen.V263.CustomEmoji.CustomEmojiData
    }
