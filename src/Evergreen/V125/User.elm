module Evergreen.V125.User exposing (..)

import Effect.Time
import Evergreen.V125.Discord.Id
import Evergreen.V125.EmailAddress
import Evergreen.V125.FileStatus
import Evergreen.V125.Id
import Evergreen.V125.NonemptyDict
import Evergreen.V125.OneOrGreater
import Evergreen.V125.PersonName
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


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) Evergreen.V125.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V125.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V125.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V125.Id.AnyGuildOrDmId (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId ) (Evergreen.V125.Id.Id Evergreen.V125.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) ( Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelId, Evergreen.V125.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) ( Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId, Evergreen.V125.Id.ThreadRoute )
    , icon : Maybe Evergreen.V125.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) (Evergreen.V125.NonemptyDict.NonemptyDict ( Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelId, Evergreen.V125.Id.ThreadRoute ) Evergreen.V125.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) (Evergreen.V125.NonemptyDict.NonemptyDict ( Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId, Evergreen.V125.Id.ThreadRoute ) Evergreen.V125.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId)
    }


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V125.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V125.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V125.PersonName.PersonName
    , icon : Maybe Evergreen.V125.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V125.PersonName.PersonName
    , icon : Maybe Evergreen.V125.FileStatus.FileHash
    , email : Maybe Evergreen.V125.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
