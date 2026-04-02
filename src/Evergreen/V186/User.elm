module Evergreen.V186.User exposing (..)

import Effect.Time
import Evergreen.V186.Discord
import Evergreen.V186.DiscordUserData
import Evergreen.V186.EmailAddress
import Evergreen.V186.Emoji
import Evergreen.V186.FileStatus
import Evergreen.V186.Id
import Evergreen.V186.NonemptyDict
import Evergreen.V186.OneOrGreater
import Evergreen.V186.Pagination
import Evergreen.V186.PersonName
import Evergreen.V186.RichText
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


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) Evergreen.V186.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V186.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V186.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V186.Id.Id Evergreen.V186.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V186.Id.AnyGuildOrDmId (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V186.Id.AnyGuildOrDmId, Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId ) (Evergreen.V186.Id.Id Evergreen.V186.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) ( Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelId, Evergreen.V186.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) ( Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId, Evergreen.V186.Id.ThreadRoute )
    , icon : Maybe Evergreen.V186.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) (Evergreen.V186.NonemptyDict.NonemptyDict ( Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelId, Evergreen.V186.Id.ThreadRoute ) Evergreen.V186.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.NonemptyDict.NonemptyDict ( Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId, Evergreen.V186.Id.ThreadRoute ) Evergreen.V186.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V186.RichText.Domain
    , emojiConfig : Evergreen.V186.Emoji.EmojiConfig
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V186.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V186.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V186.PersonName.PersonName
    , icon : Maybe Evergreen.V186.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V186.PersonName.PersonName
    , icon : Maybe Evergreen.V186.FileStatus.FileHash
    , email : Maybe Evergreen.V186.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V186.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
