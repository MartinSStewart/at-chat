module Evergreen.V190.User exposing (..)

import Effect.Time
import Evergreen.V190.Discord
import Evergreen.V190.DiscordUserData
import Evergreen.V190.EmailAddress
import Evergreen.V190.Emoji
import Evergreen.V190.FileStatus
import Evergreen.V190.Id
import Evergreen.V190.NonemptyDict
import Evergreen.V190.OneOrGreater
import Evergreen.V190.Pagination
import Evergreen.V190.PersonName
import Evergreen.V190.RichText
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


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) Evergreen.V190.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V190.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V190.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V190.Id.Id Evergreen.V190.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V190.Id.AnyGuildOrDmId (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V190.Id.AnyGuildOrDmId, Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId ) (Evergreen.V190.Id.Id Evergreen.V190.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) ( Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelId, Evergreen.V190.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) ( Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId, Evergreen.V190.Id.ThreadRoute )
    , icon : Maybe Evergreen.V190.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) (Evergreen.V190.NonemptyDict.NonemptyDict ( Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelId, Evergreen.V190.Id.ThreadRoute ) Evergreen.V190.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.NonemptyDict.NonemptyDict ( Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId, Evergreen.V190.Id.ThreadRoute ) Evergreen.V190.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V190.RichText.Domain
    , emojiConfig : Evergreen.V190.Emoji.EmojiConfig
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V190.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V190.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V190.PersonName.PersonName
    , icon : Maybe Evergreen.V190.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V190.PersonName.PersonName
    , icon : Maybe Evergreen.V190.FileStatus.FileHash
    , email : Maybe Evergreen.V190.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V190.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
