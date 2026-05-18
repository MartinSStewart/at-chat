module Evergreen.V236.User exposing (..)

import Effect.Time
import Evergreen.V236.CustomEmoji
import Evergreen.V236.Discord
import Evergreen.V236.DiscordUserData
import Evergreen.V236.EmailAddress
import Evergreen.V236.Emoji
import Evergreen.V236.FileStatus
import Evergreen.V236.Id
import Evergreen.V236.NonemptyDict
import Evergreen.V236.OneOrGreater
import Evergreen.V236.Pagination
import Evergreen.V236.PersonName
import Evergreen.V236.RichText
import Evergreen.V236.Sticker
import Evergreen.V236.UserAgent
import Evergreen.V236.UserSession
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
    = DmChannelLastViewed (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) Evergreen.V236.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V236.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V236.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V236.Id.Id Evergreen.V236.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V236.Id.AnyGuildOrDmId (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V236.Id.AnyGuildOrDmId, Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId ) (Evergreen.V236.Id.Id Evergreen.V236.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) ( Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelId, Evergreen.V236.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) ( Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId, Evergreen.V236.Id.ThreadRoute )
    , icon : Maybe Evergreen.V236.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) (Evergreen.V236.NonemptyDict.NonemptyDict ( Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelId, Evergreen.V236.Id.ThreadRoute ) Evergreen.V236.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.NonemptyDict.NonemptyDict ( Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId, Evergreen.V236.Id.ThreadRoute ) Evergreen.V236.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V236.RichText.Domain
    , emojiConfig : Evergreen.V236.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V236.Id.Id Evergreen.V236.Id.StickerId)
    , availableCustomEmojis : SeqSet.SeqSet (Evergreen.V236.Id.Id Evergreen.V236.Id.CustomEmojiId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V236.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V236.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V236.PersonName.PersonName
    , icon : Maybe Evergreen.V236.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V236.PersonName.PersonName
    , icon : Maybe Evergreen.V236.FileStatus.FileHash
    , email : Maybe Evergreen.V236.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V236.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention


type alias LocalUser =
    { session : Evergreen.V236.UserSession.UserSession
    , user : FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V236.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.StickerId) Evergreen.V236.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.CustomEmojiId) Evergreen.V236.CustomEmoji.CustomEmojiData
    }
