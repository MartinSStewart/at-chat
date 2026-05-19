module Evergreen.V239.User exposing (..)

import Effect.Time
import Evergreen.V239.CustomEmoji
import Evergreen.V239.Discord
import Evergreen.V239.DiscordUserData
import Evergreen.V239.EmailAddress
import Evergreen.V239.Emoji
import Evergreen.V239.FileStatus
import Evergreen.V239.Id
import Evergreen.V239.NonemptyDict
import Evergreen.V239.OneOrGreater
import Evergreen.V239.Pagination
import Evergreen.V239.PersonName
import Evergreen.V239.RichText
import Evergreen.V239.Sticker
import Evergreen.V239.UserAgent
import Evergreen.V239.UserSession
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


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) Evergreen.V239.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V239.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V239.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V239.Id.Id Evergreen.V239.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V239.Id.AnyGuildOrDmId (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V239.Id.AnyGuildOrDmId, Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId ) (Evergreen.V239.Id.Id Evergreen.V239.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) ( Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelId, Evergreen.V239.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) ( Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId, Evergreen.V239.Id.ThreadRoute )
    , icon : Maybe Evergreen.V239.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) (Evergreen.V239.NonemptyDict.NonemptyDict ( Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelId, Evergreen.V239.Id.ThreadRoute ) Evergreen.V239.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.NonemptyDict.NonemptyDict ( Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId, Evergreen.V239.Id.ThreadRoute ) Evergreen.V239.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V239.RichText.Domain
    , emojiConfig : Evergreen.V239.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V239.Id.Id Evergreen.V239.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V239.Id.Id Evergreen.V239.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V239.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V239.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V239.PersonName.PersonName
    , icon : Maybe Evergreen.V239.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V239.PersonName.PersonName
    , icon : Maybe Evergreen.V239.FileStatus.FileHash
    , email : Maybe Evergreen.V239.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V239.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V239.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V239.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.StickerId) Evergreen.V239.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.CustomEmojiId) Evergreen.V239.CustomEmoji.CustomEmojiData
    }
