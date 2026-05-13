module Evergreen.V216.User exposing (..)

import Effect.Time
import Evergreen.V216.CustomEmoji
import Evergreen.V216.Discord
import Evergreen.V216.DiscordUserData
import Evergreen.V216.EmailAddress
import Evergreen.V216.Emoji
import Evergreen.V216.FileStatus
import Evergreen.V216.Id
import Evergreen.V216.NonemptyDict
import Evergreen.V216.OneOrGreater
import Evergreen.V216.Pagination
import Evergreen.V216.PersonName
import Evergreen.V216.RichText
import Evergreen.V216.Sticker
import Evergreen.V216.UserAgent
import Evergreen.V216.UserSession
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
    = DmChannelLastViewed (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) Evergreen.V216.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V216.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V216.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V216.Id.Id Evergreen.V216.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V216.Id.AnyGuildOrDmId (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V216.Id.AnyGuildOrDmId, Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId ) (Evergreen.V216.Id.Id Evergreen.V216.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) ( Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelId, Evergreen.V216.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) ( Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId, Evergreen.V216.Id.ThreadRoute )
    , icon : Maybe Evergreen.V216.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) (Evergreen.V216.NonemptyDict.NonemptyDict ( Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelId, Evergreen.V216.Id.ThreadRoute ) Evergreen.V216.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.NonemptyDict.NonemptyDict ( Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId, Evergreen.V216.Id.ThreadRoute ) Evergreen.V216.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V216.RichText.Domain
    , emojiConfig : Evergreen.V216.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V216.Id.Id Evergreen.V216.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V216.Id.Id Evergreen.V216.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V216.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V216.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V216.PersonName.PersonName
    , icon : Maybe Evergreen.V216.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V216.PersonName.PersonName
    , icon : Maybe Evergreen.V216.FileStatus.FileHash
    , email : Maybe Evergreen.V216.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V216.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V216.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V216.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.StickerId) Evergreen.V216.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.CustomEmojiId) Evergreen.V216.CustomEmoji.CustomEmojiData
    }
