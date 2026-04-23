module Evergreen.V207.User exposing (..)

import Effect.Time
import Evergreen.V207.Discord
import Evergreen.V207.DiscordUserData
import Evergreen.V207.EmailAddress
import Evergreen.V207.Emoji
import Evergreen.V207.FileStatus
import Evergreen.V207.Id
import Evergreen.V207.NonemptyDict
import Evergreen.V207.OneOrGreater
import Evergreen.V207.Pagination
import Evergreen.V207.PersonName
import Evergreen.V207.RichText
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
    = DmChannelLastViewed (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) Evergreen.V207.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V207.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V207.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V207.Id.Id Evergreen.V207.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V207.Id.AnyGuildOrDmId (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V207.Id.AnyGuildOrDmId, Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId ) (Evergreen.V207.Id.Id Evergreen.V207.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) ( Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelId, Evergreen.V207.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) ( Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId, Evergreen.V207.Id.ThreadRoute )
    , icon : Maybe Evergreen.V207.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) (Evergreen.V207.NonemptyDict.NonemptyDict ( Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelId, Evergreen.V207.Id.ThreadRoute ) Evergreen.V207.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.NonemptyDict.NonemptyDict ( Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId, Evergreen.V207.Id.ThreadRoute ) Evergreen.V207.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V207.RichText.Domain
    , emojiConfig : Evergreen.V207.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V207.Id.Id Evergreen.V207.Id.StickerId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V207.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V207.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V207.PersonName.PersonName
    , icon : Maybe Evergreen.V207.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V207.PersonName.PersonName
    , icon : Maybe Evergreen.V207.FileStatus.FileHash
    , email : Maybe Evergreen.V207.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V207.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
