module Evergreen.V406.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V406.Discord
import Evergreen.V406.FileStatus
import Evergreen.V406.Id
import Evergreen.V406.IdArray
import Evergreen.V406.Message
import Evergreen.V406.PersonName
import Evergreen.V406.Ports
import Evergreen.V406.SessionIdHash
import Evergreen.V406.UserAgent
import Evergreen.V406.UserColor
import SeqDict
import SeqSet


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId)) (Maybe Evergreen.V406.Message.RepliedToGame)
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type UserOptionSection
    = UserOption_TwoFactorAuthentication
    | UserOption_Settings
    | UserOption_WhitelistedDomains
    | UserOption_E2ee
    | UserOption_Discord
    | UserOption_ConnectedDevices
    | UserOption_Debug
    | UserOption_Privacy
    | UserOption_Slack


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V406.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V406.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias SheepGameQuestion =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId) Evergreen.V406.FileStatus.FileStatus
    }


type LastViewedGuild
    = LastViewedGuild (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId)
    | LastViewedDiscordGuild (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId)


type alias UserSession =
    { userId : Evergreen.V406.Id.Id Evergreen.V406.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V406.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V406.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    , lastClientDisconnect : Maybe Effect.Time.Posix
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , savedSheepGameQuestions : Evergreen.V406.IdArray.IdArray Evergreen.V406.Id.QuestionId SheepGameQuestion
    , lastViewedGuild : Maybe LastViewedGuild
    }


type PreviouslyLastViewedMessage messageId
    = DontCare
    | PreviouslyLastViewedMessage (Evergreen.V406.Id.Id messageId)


type alias Viewing_DmData =
    { id : Evergreen.V406.Id.Viewing_DmId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V406.Id.ChannelMessageId
    }


type alias Viewing_DmThreadData =
    { id : Evergreen.V406.Id.Viewing_DmThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V406.Id.ThreadMessageId
    }


type alias Viewing_DiscordDmData =
    { id : Evergreen.V406.Id.Viewing_DiscordDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V406.Id.ChannelMessageId
    }


type alias Viewing_ChannelData =
    { id : Evergreen.V406.Id.Viewing_ChannelId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V406.Id.ChannelMessageId
    }


type alias Viewing_ChannelThreadData =
    { id : Evergreen.V406.Id.Viewing_ChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V406.Id.ThreadMessageId
    }


type alias Viewing_DiscordChannelData =
    { id : Evergreen.V406.Id.Viewing_DiscordChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V406.Id.ChannelMessageId
    }


type alias Viewing_DiscordChannelThreadData =
    { id : Evergreen.V406.Id.Viewing_DiscordChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V406.Id.ThreadMessageId
    }


type Viewing
    = Viewing_Dm Viewing_DmData
    | Viewing_DmThread Viewing_DmThreadData
    | Viewing_DiscordDm Viewing_DiscordDmData
    | Viewing_Channel Viewing_ChannelData
    | Viewing_ChannelThread Viewing_ChannelThreadData
    | Viewing_DiscordChannel Viewing_DiscordChannelData
    | Viewing_DiscordChannelThread Viewing_DiscordChannelThreadData
    | Viewing_None
    | Viewing_Overview


type alias SlackFrontendUser =
    { name : Evergreen.V406.PersonName.PersonName
    , icon : Maybe Evergreen.V406.FileStatus.FileHash
    , color : Evergreen.V406.UserColor.UserColor
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V406.PersonName.PersonName
    , icon : Maybe Evergreen.V406.FileStatus.FileHash
    , color : Evergreen.V406.UserColor.UserColor
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V406.UserAgent.UserAgent
    , lastActiveAt : Effect.Time.Posix
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V406.Id.Id messageId) (Evergreen.V406.Message.Message messageId (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId))
    , newUsers : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId, Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (Evergreen.V406.Message.Message Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId, Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId, Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ThreadMessageId) (Evergreen.V406.Message.Message Evergreen.V406.Id.ThreadMessageId (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (Evergreen.V406.Message.Message Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V406.Id.Id Evergreen.V406.Id.UserId, Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ThreadMessageId) (Evergreen.V406.Message.Message Evergreen.V406.Id.ThreadMessageId (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId, Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (Evergreen.V406.Message.Message Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId, Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId, Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ThreadMessageId) (Evergreen.V406.Message.Message Evergreen.V406.Id.ThreadMessageId (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (Evergreen.V406.Message.Message Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) DiscordFrontendUser
    }
