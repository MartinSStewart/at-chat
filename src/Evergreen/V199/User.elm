module Evergreen.V199.User exposing (..)

import Effect.Time
import Evergreen.V199.Discord
import Evergreen.V199.DiscordUserData
import Evergreen.V199.EmailAddress
import Evergreen.V199.Emoji
import Evergreen.V199.FileStatus
import Evergreen.V199.Id
import Evergreen.V199.NonemptyDict
import Evergreen.V199.OneOrGreater
import Evergreen.V199.Pagination
import Evergreen.V199.PersonName
import Evergreen.V199.RichText
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
    = DmChannelLastViewed (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) Evergreen.V199.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V199.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V199.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V199.Id.Id Evergreen.V199.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V199.Id.AnyGuildOrDmId (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V199.Id.AnyGuildOrDmId, Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId ) (Evergreen.V199.Id.Id Evergreen.V199.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) ( Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelId, Evergreen.V199.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) ( Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId, Evergreen.V199.Id.ThreadRoute )
    , icon : Maybe Evergreen.V199.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) (Evergreen.V199.NonemptyDict.NonemptyDict ( Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelId, Evergreen.V199.Id.ThreadRoute ) Evergreen.V199.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.NonemptyDict.NonemptyDict ( Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId, Evergreen.V199.Id.ThreadRoute ) Evergreen.V199.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V199.RichText.Domain
    , emojiConfig : Evergreen.V199.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V199.Id.Id Evergreen.V199.Id.StickerId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V199.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V199.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V199.PersonName.PersonName
    , icon : Maybe Evergreen.V199.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V199.PersonName.PersonName
    , icon : Maybe Evergreen.V199.FileStatus.FileHash
    , email : Maybe Evergreen.V199.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V199.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
