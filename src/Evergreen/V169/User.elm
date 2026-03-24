module Evergreen.V169.User exposing (..)

import Effect.Time
import Evergreen.V169.Discord
import Evergreen.V169.DiscordUserData
import Evergreen.V169.EmailAddress
import Evergreen.V169.Emoji
import Evergreen.V169.FileStatus
import Evergreen.V169.Id
import Evergreen.V169.NonemptyDict
import Evergreen.V169.OneOrGreater
import Evergreen.V169.Pagination
import Evergreen.V169.PersonName
import Evergreen.V169.RichText
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
    = DmChannelLastViewed (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) Evergreen.V169.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V169.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V169.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Evergreen.V169.Id.Id Evergreen.V169.Pagination.PageId
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V169.Id.AnyGuildOrDmId (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V169.Id.AnyGuildOrDmId, Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId ) (Evergreen.V169.Id.Id Evergreen.V169.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) ( Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelId, Evergreen.V169.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) ( Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId, Evergreen.V169.Id.ThreadRoute )
    , icon : Maybe Evergreen.V169.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) (Evergreen.V169.NonemptyDict.NonemptyDict ( Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelId, Evergreen.V169.Id.ThreadRoute ) Evergreen.V169.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.NonemptyDict.NonemptyDict ( Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId, Evergreen.V169.Id.ThreadRoute ) Evergreen.V169.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId)
    , linkDiscordAcknowledgementIsChecked : Bool
    , domainWhitelist : SeqSet.SeqSet Evergreen.V169.RichText.Domain
    , emojiConfig : Evergreen.V169.Emoji.EmojiConfig
    }


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V169.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V169.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V169.PersonName.PersonName
    , icon : Maybe Evergreen.V169.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V169.PersonName.PersonName
    , icon : Maybe Evergreen.V169.FileStatus.FileHash
    , email : Maybe Evergreen.V169.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V169.DiscordUserData.DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
