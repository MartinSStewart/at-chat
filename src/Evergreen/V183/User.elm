module Evergreen.V183.User exposing (..)

import Effect.Time
import Evergreen.V183.Discord
import Evergreen.V183.DiscordUserData
import Evergreen.V183.EmailAddress
import Evergreen.V183.Emoji
import Evergreen.V183.FileStatus
import Evergreen.V183.Id
import Evergreen.V183.NonemptyDict
import Evergreen.V183.OneOrGreater
import Evergreen.V183.Pagination
import Evergreen.V183.PersonName
import Evergreen.V183.RichText
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
    = DmChannelLastViewed (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) Evergreen.V183.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V183.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V183.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V183.Id.Id Evergreen.V183.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V183.Id.AnyGuildOrDmId (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V183.Id.AnyGuildOrDmId, Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId ) (Evergreen.V183.Id.Id Evergreen.V183.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) ( Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelId, Evergreen.V183.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) ( Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId, Evergreen.V183.Id.ThreadRoute )
    , icon : Maybe Evergreen.V183.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) (Evergreen.V183.NonemptyDict.NonemptyDict ( Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelId, Evergreen.V183.Id.ThreadRoute ) Evergreen.V183.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.NonemptyDict.NonemptyDict ( Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId, Evergreen.V183.Id.ThreadRoute ) Evergreen.V183.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V183.RichText.Domain
    , emojiConfig : Evergreen.V183.Emoji.EmojiConfig
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V183.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V183.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V183.PersonName.PersonName
    , icon : Maybe Evergreen.V183.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V183.PersonName.PersonName
    , icon : Maybe Evergreen.V183.FileStatus.FileHash
    , email : Maybe Evergreen.V183.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V183.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
