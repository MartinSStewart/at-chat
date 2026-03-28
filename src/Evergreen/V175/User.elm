module Evergreen.V175.User exposing (..)

import Effect.Time
import Evergreen.V175.Discord
import Evergreen.V175.DiscordUserData
import Evergreen.V175.EmailAddress
import Evergreen.V175.Emoji
import Evergreen.V175.FileStatus
import Evergreen.V175.Id
import Evergreen.V175.NonemptyDict
import Evergreen.V175.OneOrGreater
import Evergreen.V175.Pagination
import Evergreen.V175.PersonName
import Evergreen.V175.RichText
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
    = DmChannelLastViewed (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) Evergreen.V175.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V175.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V175.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V175.Id.Id Evergreen.V175.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V175.Id.AnyGuildOrDmId (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V175.Id.AnyGuildOrDmId, Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId ) (Evergreen.V175.Id.Id Evergreen.V175.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) ( Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelId, Evergreen.V175.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) ( Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId, Evergreen.V175.Id.ThreadRoute )
    , icon : Maybe Evergreen.V175.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) (Evergreen.V175.NonemptyDict.NonemptyDict ( Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelId, Evergreen.V175.Id.ThreadRoute ) Evergreen.V175.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.NonemptyDict.NonemptyDict ( Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId, Evergreen.V175.Id.ThreadRoute ) Evergreen.V175.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V175.RichText.Domain
    , emojiConfig : Evergreen.V175.Emoji.EmojiConfig
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V175.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V175.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V175.PersonName.PersonName
    , icon : Maybe Evergreen.V175.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V175.PersonName.PersonName
    , icon : Maybe Evergreen.V175.FileStatus.FileHash
    , email : Maybe Evergreen.V175.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V175.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
