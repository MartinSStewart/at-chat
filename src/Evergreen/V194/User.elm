module Evergreen.V194.User exposing (..)

import Effect.Time
import Evergreen.V194.Discord
import Evergreen.V194.DiscordUserData
import Evergreen.V194.EmailAddress
import Evergreen.V194.Emoji
import Evergreen.V194.FileStatus
import Evergreen.V194.Id
import Evergreen.V194.NonemptyDict
import Evergreen.V194.OneOrGreater
import Evergreen.V194.Pagination
import Evergreen.V194.PersonName
import Evergreen.V194.RichText
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
    = DmChannelLastViewed (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) Evergreen.V194.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V194.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V194.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V194.Id.Id Evergreen.V194.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V194.Id.AnyGuildOrDmId (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V194.Id.AnyGuildOrDmId, Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId ) (Evergreen.V194.Id.Id Evergreen.V194.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) ( Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelId, Evergreen.V194.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) ( Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId, Evergreen.V194.Id.ThreadRoute )
    , icon : Maybe Evergreen.V194.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) (Evergreen.V194.NonemptyDict.NonemptyDict ( Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelId, Evergreen.V194.Id.ThreadRoute ) Evergreen.V194.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.NonemptyDict.NonemptyDict ( Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId, Evergreen.V194.Id.ThreadRoute ) Evergreen.V194.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V194.RichText.Domain
    , emojiConfig : Evergreen.V194.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V194.Id.Id Evergreen.V194.Id.StickerId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V194.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V194.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V194.PersonName.PersonName
    , icon : Maybe Evergreen.V194.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V194.PersonName.PersonName
    , icon : Maybe Evergreen.V194.FileStatus.FileHash
    , email : Maybe Evergreen.V194.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V194.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
