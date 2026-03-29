module Evergreen.V177.User exposing (..)

import Effect.Time
import Evergreen.V177.Discord
import Evergreen.V177.DiscordUserData
import Evergreen.V177.EmailAddress
import Evergreen.V177.Emoji
import Evergreen.V177.FileStatus
import Evergreen.V177.Id
import Evergreen.V177.NonemptyDict
import Evergreen.V177.OneOrGreater
import Evergreen.V177.Pagination
import Evergreen.V177.PersonName
import Evergreen.V177.RichText
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


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) Evergreen.V177.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V177.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V177.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V177.Id.Id Evergreen.V177.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V177.Id.AnyGuildOrDmId (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V177.Id.AnyGuildOrDmId, Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId ) (Evergreen.V177.Id.Id Evergreen.V177.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) ( Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelId, Evergreen.V177.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) ( Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId, Evergreen.V177.Id.ThreadRoute )
    , icon : Maybe Evergreen.V177.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) (Evergreen.V177.NonemptyDict.NonemptyDict ( Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelId, Evergreen.V177.Id.ThreadRoute ) Evergreen.V177.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.NonemptyDict.NonemptyDict ( Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId, Evergreen.V177.Id.ThreadRoute ) Evergreen.V177.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V177.RichText.Domain
    , emojiConfig : Evergreen.V177.Emoji.EmojiConfig
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V177.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V177.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V177.PersonName.PersonName
    , icon : Maybe Evergreen.V177.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V177.PersonName.PersonName
    , icon : Maybe Evergreen.V177.FileStatus.FileHash
    , email : Maybe Evergreen.V177.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V177.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
