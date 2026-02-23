module Evergreen.V119.User exposing (..)

import Effect.Time
import Evergreen.V119.Discord.Id
import Evergreen.V119.EmailAddress
import Evergreen.V119.FileStatus
import Evergreen.V119.Id
import Evergreen.V119.NonemptyDict
import Evergreen.V119.OneOrGreater
import Evergreen.V119.PersonName
import SeqDict
import SeqSet


type AdminUiSection
    = UsersSection
    | LogSection
    | DiscordDmChannelsSection


type EmailNotifications
    = CheckEvery5Minutes


type LastDmViewed
    = DmChannelLastViewed (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) Evergreen.V119.Id.ThreadRoute
    | DiscordDmChannelLastViewed (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.PrivateChannelId)
    | NoLastDmViewed


type alias BackendUser =
    { name : Evergreen.V119.PersonName.PersonName
    , isAdmin : Bool
    , email : Evergreen.V119.EmailAddress.EmailAddress
    , recentLoginEmails : List Effect.Time.Posix
    , lastLogPageViewed : Int
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , createdAt : Effect.Time.Posix
    , emailNotifications : EmailNotifications
    , lastEmailNotification : Effect.Time.Posix
    , lastViewed : SeqDict.SeqDict Evergreen.V119.Id.AnyGuildOrDmId (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId)
    , lastViewedThreads : SeqDict.SeqDict ( Evergreen.V119.Id.AnyGuildOrDmId, Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId ) (Evergreen.V119.Id.Id Evergreen.V119.Id.ThreadMessageId)
    , lastDmViewed : LastDmViewed
    , lastChannelViewed : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) ( Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelId, Evergreen.V119.Id.ThreadRoute )
    , lastDiscordChannelViewed : SeqDict.SeqDict (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId) ( Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.ChannelId, Evergreen.V119.Id.ThreadRoute )
    , icon : Maybe Evergreen.V119.FileStatus.FileHash
    , notifyOnAllMessages : SeqSet.SeqSet (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId)
    , discordNotifyOnAllMessages : SeqSet.SeqSet (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId)
    , directMentions : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) (Evergreen.V119.NonemptyDict.NonemptyDict ( Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelId, Evergreen.V119.Id.ThreadRoute ) Evergreen.V119.OneOrGreater.OneOrGreater)
    , discordDirectMentions : SeqDict.SeqDict (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId) (Evergreen.V119.NonemptyDict.NonemptyDict ( Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.ChannelId, Evergreen.V119.Id.ThreadRoute ) Evergreen.V119.OneOrGreater.OneOrGreater)
    , lastPushNotification : Maybe Effect.Time.Posix
    }


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias FrontendCurrentUser =
    BackendUser


type alias FrontendUser =
    { name : Evergreen.V119.PersonName.PersonName
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , icon : Maybe Evergreen.V119.FileStatus.FileHash
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V119.PersonName.PersonName
    , icon : Maybe Evergreen.V119.FileStatus.FileHash
    }


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V119.PersonName.PersonName
    , icon : Maybe Evergreen.V119.FileStatus.FileHash
    , email : Maybe Evergreen.V119.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type NotificationLevel
    = NotifyOnEveryMessage
    | NotifyOnMention
