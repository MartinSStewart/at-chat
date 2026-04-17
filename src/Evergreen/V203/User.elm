module Evergreen.V203.User exposing (..)

import Effect.Time
import Evergreen.V203.Discord
import Evergreen.V203.DiscordUserData
import Evergreen.V203.EmailAddress
import Evergreen.V203.Emoji
import Evergreen.V203.FileStatus
import Evergreen.V203.Id
import Evergreen.V203.NonemptyDict
import Evergreen.V203.OneOrGreater
import Evergreen.V203.Pagination
import Evergreen.V203.PersonName
import Evergreen.V203.RichText
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
    = DmChannelLastViewed (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) Evergreen.V203.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V203.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V203.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V203.Id.Id Evergreen.V203.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V203.Id.AnyGuildOrDmId (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V203.Id.AnyGuildOrDmId, Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId ) (Evergreen.V203.Id.Id Evergreen.V203.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) ( Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelId, Evergreen.V203.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) ( Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId, Evergreen.V203.Id.ThreadRoute )
    , icon : Maybe Evergreen.V203.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) (Evergreen.V203.NonemptyDict.NonemptyDict ( Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelId, Evergreen.V203.Id.ThreadRoute ) Evergreen.V203.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.NonemptyDict.NonemptyDict ( Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId, Evergreen.V203.Id.ThreadRoute ) Evergreen.V203.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V203.RichText.Domain
    , emojiConfig : Evergreen.V203.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V203.Id.Id Evergreen.V203.Id.StickerId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V203.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V203.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V203.PersonName.PersonName
    , icon : Maybe Evergreen.V203.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V203.PersonName.PersonName
    , icon : Maybe Evergreen.V203.FileStatus.FileHash
    , email : Maybe Evergreen.V203.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V203.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
