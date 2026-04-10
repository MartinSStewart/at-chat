module Evergreen.V193.User exposing (..)

import Effect.Time
import Evergreen.V193.Discord
import Evergreen.V193.DiscordUserData
import Evergreen.V193.EmailAddress
import Evergreen.V193.Emoji
import Evergreen.V193.FileStatus
import Evergreen.V193.Id
import Evergreen.V193.NonemptyDict
import Evergreen.V193.OneOrGreater
import Evergreen.V193.Pagination
import Evergreen.V193.PersonName
import Evergreen.V193.RichText
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
    | StickersSection


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) Evergreen.V193.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V193.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V193.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V193.Id.Id Evergreen.V193.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V193.Id.AnyGuildOrDmId (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V193.Id.AnyGuildOrDmId, Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId ) (Evergreen.V193.Id.Id Evergreen.V193.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) ( Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelId, Evergreen.V193.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) ( Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId, Evergreen.V193.Id.ThreadRoute )
    , icon : Maybe Evergreen.V193.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) (Evergreen.V193.NonemptyDict.NonemptyDict ( Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelId, Evergreen.V193.Id.ThreadRoute ) Evergreen.V193.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.NonemptyDict.NonemptyDict ( Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId, Evergreen.V193.Id.ThreadRoute ) Evergreen.V193.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V193.RichText.Domain
    , emojiConfig : Evergreen.V193.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V193.Id.Id Evergreen.V193.Id.StickerId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V193.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V193.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V193.PersonName.PersonName
    , icon : Maybe Evergreen.V193.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V193.PersonName.PersonName
    , icon : Maybe Evergreen.V193.FileStatus.FileHash
    , email : Maybe Evergreen.V193.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V193.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
