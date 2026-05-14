module Evergreen.V218.User exposing (..)

import Effect.Time
import Evergreen.V218.CustomEmoji
import Evergreen.V218.Discord
import Evergreen.V218.DiscordUserData
import Evergreen.V218.EmailAddress
import Evergreen.V218.Emoji
import Evergreen.V218.FileStatus
import Evergreen.V218.Id
import Evergreen.V218.NonemptyDict
import Evergreen.V218.OneOrGreater
import Evergreen.V218.Pagination
import Evergreen.V218.PersonName
import Evergreen.V218.RichText
import Evergreen.V218.Sticker
import Evergreen.V218.UserAgent
import Evergreen.V218.UserSession
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
    | VoiceChatSection


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) Evergreen.V218.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V218.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V218.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V218.Id.Id Evergreen.V218.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V218.Id.AnyGuildOrDmId (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V218.Id.AnyGuildOrDmId, Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId ) (Evergreen.V218.Id.Id Evergreen.V218.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) ( Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelId, Evergreen.V218.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) ( Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId, Evergreen.V218.Id.ThreadRoute )
    , icon : Maybe Evergreen.V218.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) (Evergreen.V218.NonemptyDict.NonemptyDict ( Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelId, Evergreen.V218.Id.ThreadRoute ) Evergreen.V218.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.NonemptyDict.NonemptyDict ( Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId, Evergreen.V218.Id.ThreadRoute ) Evergreen.V218.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V218.RichText.Domain
    , emojiConfig : Evergreen.V218.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V218.Id.Id Evergreen.V218.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V218.Id.Id Evergreen.V218.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V218.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V218.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V218.PersonName.PersonName
    , icon : Maybe Evergreen.V218.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V218.PersonName.PersonName
    , icon : Maybe Evergreen.V218.FileStatus.FileHash
    , email : Maybe Evergreen.V218.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V218.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V218.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V218.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.StickerId) Evergreen.V218.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.CustomEmojiId) Evergreen.V218.CustomEmoji.CustomEmojiData
    }
