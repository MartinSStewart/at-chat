module Evergreen.V215.User exposing (..)

import Effect.Time
import Evergreen.V215.CustomEmoji
import Evergreen.V215.Discord
import Evergreen.V215.DiscordUserData
import Evergreen.V215.EmailAddress
import Evergreen.V215.Emoji
import Evergreen.V215.FileStatus
import Evergreen.V215.Id
import Evergreen.V215.NonemptyDict
import Evergreen.V215.OneOrGreater
import Evergreen.V215.Pagination
import Evergreen.V215.PersonName
import Evergreen.V215.RichText
import Evergreen.V215.Sticker
import Evergreen.V215.UserAgent
import Evergreen.V215.UserSession
import SeqDict
import SeqSet


type AdminUiSection
    = UsersSection
    | LogSection
    | DiscordDmChannelsSection
    | DiscordUsersSection
    | DiscordGuildsSection
    | GuildsSection
    | ApiKeysSection
    | ExportSection
    | ConnectionsSection
    | FilesSection
    | ToBackendLogsSection
    | StickersAndEmojisSection


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) Evergreen.V215.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V215.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V215.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V215.Id.Id Evergreen.V215.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V215.Id.AnyGuildOrDmId (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V215.Id.AnyGuildOrDmId, Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId ) (Evergreen.V215.Id.Id Evergreen.V215.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) ( Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelId, Evergreen.V215.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) ( Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId, Evergreen.V215.Id.ThreadRoute )
    , icon : Maybe Evergreen.V215.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) (Evergreen.V215.NonemptyDict.NonemptyDict ( Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelId, Evergreen.V215.Id.ThreadRoute ) Evergreen.V215.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.NonemptyDict.NonemptyDict ( Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId, Evergreen.V215.Id.ThreadRoute ) Evergreen.V215.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V215.RichText.Domain
    , emojiConfig : Evergreen.V215.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V215.Id.Id Evergreen.V215.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V215.Id.Id Evergreen.V215.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V215.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V215.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V215.PersonName.PersonName
    , icon : Maybe Evergreen.V215.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V215.PersonName.PersonName
    , icon : Maybe Evergreen.V215.FileStatus.FileHash
    , email : Maybe Evergreen.V215.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V215.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V215.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V215.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.StickerId) Evergreen.V215.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.CustomEmojiId) Evergreen.V215.CustomEmoji.CustomEmojiData
    }
