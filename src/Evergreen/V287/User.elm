module Evergreen.V287.User exposing (..)

import Effect.Time
import Evergreen.V287.CustomEmoji
import Evergreen.V287.Discord
import Evergreen.V287.DiscordUserData
import Evergreen.V287.EmailAddress
import Evergreen.V287.Emoji
import Evergreen.V287.FileStatus
import Evergreen.V287.Id
import Evergreen.V287.NonemptyDict
import Evergreen.V287.OneOrGreater
import Evergreen.V287.Pagination
import Evergreen.V287.PersonName
import Evergreen.V287.RichText
import Evergreen.V287.Sticker
import Evergreen.V287.UserAgent
import Evergreen.V287.UserSession
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
    = DmChannelLastViewed (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) Evergreen.V287.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V287.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V287.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V287.Id.Id Evergreen.V287.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V287.Id.AnyGuildOrDmId (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V287.Id.AnyGuildOrDmId, Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId ) (Evergreen.V287.Id.Id Evergreen.V287.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) ( Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelId, Evergreen.V287.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) ( Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId, Evergreen.V287.Id.ThreadRoute )
    , icon : Maybe Evergreen.V287.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) (Evergreen.V287.NonemptyDict.NonemptyDict ( Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelId, Evergreen.V287.Id.ThreadRoute ) Evergreen.V287.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.NonemptyDict.NonemptyDict ( Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId, Evergreen.V287.Id.ThreadRoute ) Evergreen.V287.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V287.RichText.Domain
    , emojiConfig : Evergreen.V287.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V287.Id.Id Evergreen.V287.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V287.Id.Id Evergreen.V287.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V287.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V287.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V287.PersonName.PersonName
    , icon : Maybe Evergreen.V287.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V287.PersonName.PersonName
    , icon : Maybe Evergreen.V287.FileStatus.FileHash
    , email : Maybe Evergreen.V287.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V287.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V287.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V287.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.StickerId) Evergreen.V287.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.CustomEmojiId) Evergreen.V287.CustomEmoji.CustomEmojiData
    }
