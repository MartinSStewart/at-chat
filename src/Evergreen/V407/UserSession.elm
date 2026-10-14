module Evergreen.V407.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V407.Discord
import Evergreen.V407.FileStatus
import Evergreen.V407.Id
import Evergreen.V407.IdArray
import Evergreen.V407.Message
import Evergreen.V407.PersonName
import Evergreen.V407.Ports
import Evergreen.V407.SessionIdHash
import Evergreen.V407.UserAgent
import Evergreen.V407.UserColor
import SeqDict
import SeqSet


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId)) (Maybe Evergreen.V407.Message.RepliedToGame)
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
    | Subscribed Evergreen.V407.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V407.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias SheepGameQuestion =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId) Evergreen.V407.FileStatus.FileStatus
    }


type LastViewedGuild
    = LastViewedGuild (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId)
    | LastViewedDiscordGuild (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId)


type alias UserSession =
    { userId : Evergreen.V407.Id.Id Evergreen.V407.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V407.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V407.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    , lastClientDisconnect : Maybe Effect.Time.Posix
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , savedSheepGameQuestions : Evergreen.V407.IdArray.IdArray Evergreen.V407.Id.QuestionId SheepGameQuestion
    , lastViewedGuild : Maybe LastViewedGuild
    }


type PreviouslyLastViewedMessage messageId
    = DontCare
    | PreviouslyLastViewedMessage (Evergreen.V407.Id.Id messageId)


type alias Viewing_DmData =
    { id : Evergreen.V407.Id.Viewing_DmId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V407.Id.ChannelMessageId
    }


type alias Viewing_DmThreadData =
    { id : Evergreen.V407.Id.Viewing_DmThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V407.Id.ThreadMessageId
    }


type alias Viewing_DiscordDmData =
    { id : Evergreen.V407.Id.Viewing_DiscordDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V407.Id.ChannelMessageId
    }


type alias Viewing_ChannelData =
    { id : Evergreen.V407.Id.Viewing_ChannelId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V407.Id.ChannelMessageId
    }


type alias Viewing_ChannelThreadData =
    { id : Evergreen.V407.Id.Viewing_ChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V407.Id.ThreadMessageId
    }


type alias Viewing_DiscordChannelData =
    { id : Evergreen.V407.Id.Viewing_DiscordChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V407.Id.ChannelMessageId
    }


type alias Viewing_DiscordChannelThreadData =
    { id : Evergreen.V407.Id.Viewing_DiscordChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V407.Id.ThreadMessageId
    }


type alias Viewing_SlackChannelData =
    { id : Evergreen.V407.Id.Viewing_SlackChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V407.Id.ChannelMessageId
    }


type alias Viewing_SlackChannelThreadData =
    { id : Evergreen.V407.Id.Viewing_SlackChannelId
    , threadId : Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V407.Id.ThreadMessageId
    }


type alias Viewing_SlackDmData =
    { id : Evergreen.V407.Id.Viewing_SlackDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V407.Id.ChannelMessageId
    }


type alias Viewing_SlackDmThreadData =
    { id : Evergreen.V407.Id.Viewing_SlackDmId
    , threadId : Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V407.Id.ThreadMessageId
    }


type Viewing
    = Viewing_Dm Viewing_DmData
    | Viewing_DmThread Viewing_DmThreadData
    | Viewing_DiscordDm Viewing_DiscordDmData
    | Viewing_Channel Viewing_ChannelData
    | Viewing_ChannelThread Viewing_ChannelThreadData
    | Viewing_DiscordChannel Viewing_DiscordChannelData
    | Viewing_DiscordChannelThread Viewing_DiscordChannelThreadData
    | Viewing_SlackChannel Viewing_SlackChannelData
    | Viewing_SlackChannelThread Viewing_SlackChannelThreadData
    | Viewing_SlackDm Viewing_SlackDmData
    | Viewing_SlackDmThread Viewing_SlackDmThreadData
    | Viewing_None
    | Viewing_Overview


type alias SlackFrontendUser =
    { name : Evergreen.V407.PersonName.PersonName
    , icon : Maybe Evergreen.V407.FileStatus.FileHash
    , color : Evergreen.V407.UserColor.UserColor
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V407.PersonName.PersonName
    , icon : Maybe Evergreen.V407.FileStatus.FileHash
    , color : Evergreen.V407.UserColor.UserColor
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V407.UserAgent.UserAgent
    , lastActiveAt : Effect.Time.Posix
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V407.Id.Id messageId) (Evergreen.V407.Message.Message messageId (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId))
    , newUsers : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId, Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.Message.Message Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId, Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId, Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ThreadMessageId) (Evergreen.V407.Message.Message Evergreen.V407.Id.ThreadMessageId (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.Message.Message Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V407.Id.Id Evergreen.V407.Id.UserId, Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ThreadMessageId) (Evergreen.V407.Message.Message Evergreen.V407.Id.ThreadMessageId (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId, Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.Message.Message Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId, Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId, Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ThreadMessageId) (Evergreen.V407.Message.Message Evergreen.V407.Id.ThreadMessageId (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.Message.Message Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) DiscordFrontendUser
    }
