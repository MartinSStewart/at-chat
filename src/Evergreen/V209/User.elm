module Evergreen.V209.User exposing (..)

import Effect.Time
import Evergreen.V209.Discord
import Evergreen.V209.DiscordUserData
import Evergreen.V209.EmailAddress
import Evergreen.V209.Emoji
import Evergreen.V209.FileStatus
import Evergreen.V209.Id
import Evergreen.V209.NonemptyDict
import Evergreen.V209.OneOrGreater
import Evergreen.V209.Pagination
import Evergreen.V209.PersonName
import Evergreen.V209.RichText
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
    = DmChannelLastViewed (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) Evergreen.V209.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V209.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V209.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V209.Id.Id Evergreen.V209.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V209.Id.AnyGuildOrDmId (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V209.Id.AnyGuildOrDmId, Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId ) (Evergreen.V209.Id.Id Evergreen.V209.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) ( Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelId, Evergreen.V209.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) ( Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId, Evergreen.V209.Id.ThreadRoute )
    , icon : Maybe Evergreen.V209.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) (Evergreen.V209.NonemptyDict.NonemptyDict ( Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelId, Evergreen.V209.Id.ThreadRoute ) Evergreen.V209.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.NonemptyDict.NonemptyDict ( Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId, Evergreen.V209.Id.ThreadRoute ) Evergreen.V209.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V209.RichText.Domain
    , emojiConfig : Evergreen.V209.Emoji.EmojiConfig
    , availableStickers : SeqSet.SeqSet (Evergreen.V209.Id.Id Evergreen.V209.Id.StickerId)
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V209.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V209.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V209.PersonName.PersonName
    , icon : Maybe Evergreen.V209.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V209.PersonName.PersonName
    , icon : Maybe Evergreen.V209.FileStatus.FileHash
    , email : Maybe Evergreen.V209.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V209.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
