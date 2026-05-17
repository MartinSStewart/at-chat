module Evergreen.V228.User exposing (..)

import Effect.Time
import Evergreen.V228.CustomEmoji
import Evergreen.V228.Discord
import Evergreen.V228.DiscordUserData
import Evergreen.V228.EmailAddress
import Evergreen.V228.Emoji
import Evergreen.V228.FileStatus
import Evergreen.V228.Id
import Evergreen.V228.NonemptyDict
import Evergreen.V228.OneOrGreater
import Evergreen.V228.Pagination
import Evergreen.V228.PersonName
import Evergreen.V228.RichText
import Evergreen.V228.Sticker
import Evergreen.V228.UserAgent
import Evergreen.V228.UserSession
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
    = DmChannelLastViewed (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) Evergreen.V228.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V228.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V228.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V228.Id.Id Evergreen.V228.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V228.Id.AnyGuildOrDmId (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V228.Id.AnyGuildOrDmId, Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId ) (Evergreen.V228.Id.Id Evergreen.V228.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) ( Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelId, Evergreen.V228.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) ( Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId, Evergreen.V228.Id.ThreadRoute )
    , icon : Maybe Evergreen.V228.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) (Evergreen.V228.NonemptyDict.NonemptyDict ( Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelId, Evergreen.V228.Id.ThreadRoute ) Evergreen.V228.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.NonemptyDict.NonemptyDict ( Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId, Evergreen.V228.Id.ThreadRoute ) Evergreen.V228.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V228.RichText.Domain
    , emojiConfig : Evergreen.V228.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V228.Id.Id Evergreen.V228.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V228.Id.Id Evergreen.V228.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V228.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V228.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V228.PersonName.PersonName
    , icon : Maybe Evergreen.V228.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V228.PersonName.PersonName
    , icon : Maybe Evergreen.V228.FileStatus.FileHash
    , email : Maybe Evergreen.V228.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V228.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V228.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V228.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.StickerId) Evergreen.V228.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.CustomEmojiId) Evergreen.V228.CustomEmoji.CustomEmojiData
    }
