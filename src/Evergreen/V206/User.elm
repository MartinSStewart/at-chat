module Evergreen.V206.User exposing (..)

import Effect.Time
import Evergreen.V206.Discord
import Evergreen.V206.DiscordUserData
import Evergreen.V206.EmailAddress
import Evergreen.V206.Emoji
import Evergreen.V206.FileStatus
import Evergreen.V206.Id
import Evergreen.V206.NonemptyDict
import Evergreen.V206.OneOrGreater
import Evergreen.V206.Pagination
import Evergreen.V206.PersonName
import Evergreen.V206.RichText
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
    = DmChannelLastViewed (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) Evergreen.V206.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V206.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V206.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V206.Id.Id Evergreen.V206.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V206.Id.AnyGuildOrDmId (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V206.Id.AnyGuildOrDmId, Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId ) (Evergreen.V206.Id.Id Evergreen.V206.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) ( Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelId, Evergreen.V206.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) ( Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId, Evergreen.V206.Id.ThreadRoute )
    , icon : Maybe Evergreen.V206.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) (Evergreen.V206.NonemptyDict.NonemptyDict ( Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelId, Evergreen.V206.Id.ThreadRoute ) Evergreen.V206.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.NonemptyDict.NonemptyDict ( Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId, Evergreen.V206.Id.ThreadRoute ) Evergreen.V206.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V206.RichText.Domain
    , emojiConfig : Evergreen.V206.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V206.Id.Id Evergreen.V206.Id.StickerId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V206.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V206.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V206.PersonName.PersonName
    , icon : Maybe Evergreen.V206.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V206.PersonName.PersonName
    , icon : Maybe Evergreen.V206.FileStatus.FileHash
    , email : Maybe Evergreen.V206.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V206.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
