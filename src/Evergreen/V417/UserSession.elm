module Evergreen.V417.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V417.Discord
import Evergreen.V417.FileStatus
import Evergreen.V417.Id
import Evergreen.V417.IdArray
import Evergreen.V417.Message
import Evergreen.V417.PersonName
import Evergreen.V417.Ports
import Evergreen.V417.SessionIdHash
import Evergreen.V417.Slack
import Evergreen.V417.UserAgent
import Evergreen.V417.UserColor
import SeqDict
import SeqSet


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId)) (Maybe Evergreen.V417.Message.RepliedToGame)
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
    | Subscribed Evergreen.V417.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V417.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias SheepGameQuestion =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId) Evergreen.V417.FileStatus.FileStatus
    }


type LastViewedGuild
    = LastViewedGuild (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId)
    | LastViewedDiscordGuild (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId)
    | LastViewedSlackWorkspace (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId)


type alias UserSession =
    { userId : Evergreen.V417.Id.Id Evergreen.V417.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V417.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V417.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    , lastClientDisconnect : Maybe Effect.Time.Posix
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , savedSheepGameQuestions : Evergreen.V417.IdArray.IdArray Evergreen.V417.Id.QuestionId SheepGameQuestion
    , lastViewedGuild : Maybe LastViewedGuild
    }


type PreviouslyLastViewedMessage messageId
    = DontCare
    | PreviouslyLastViewedMessage (Evergreen.V417.Id.Id messageId)


type alias Viewing_DmData =
    { id : Evergreen.V417.Id.Viewing_DmId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V417.Id.ChannelMessageId
    }


type alias Viewing_DmThreadData =
    { id : Evergreen.V417.Id.Viewing_DmThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V417.Id.ThreadMessageId
    }


type alias Viewing_DiscordDmData =
    { id : Evergreen.V417.Id.Viewing_DiscordDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V417.Id.ChannelMessageId
    }


type alias Viewing_ChannelData =
    { id : Evergreen.V417.Id.Viewing_ChannelId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V417.Id.ChannelMessageId
    }


type alias Viewing_ChannelThreadData =
    { id : Evergreen.V417.Id.Viewing_ChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V417.Id.ThreadMessageId
    }


type alias Viewing_DiscordChannelData =
    { id : Evergreen.V417.Id.Viewing_DiscordChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V417.Id.ChannelMessageId
    }


type alias Viewing_DiscordChannelThreadData =
    { id : Evergreen.V417.Id.Viewing_DiscordChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V417.Id.ThreadMessageId
    }


type alias Viewing_SlackChannelData =
    { id : Evergreen.V417.Id.Viewing_SlackChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V417.Id.ChannelMessageId
    }


type alias Viewing_SlackChannelThreadData =
    { id : Evergreen.V417.Id.Viewing_SlackChannelId
    , threadId : Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V417.Id.ThreadMessageId
    }


type alias Viewing_SlackDmData =
    { id : Evergreen.V417.Id.Viewing_SlackDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V417.Id.ChannelMessageId
    }


type alias Viewing_SlackDmThreadData =
    { id : Evergreen.V417.Id.Viewing_SlackDmId
    , threadId : Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V417.Id.ThreadMessageId
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
    { name : Evergreen.V417.PersonName.PersonName
    , icon : Maybe Evergreen.V417.FileStatus.FileHash
    , color : Evergreen.V417.UserColor.UserColor
    , teamId : Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V417.PersonName.PersonName
    , icon : Maybe Evergreen.V417.FileStatus.FileHash
    , color : Evergreen.V417.UserColor.UserColor
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V417.UserAgent.UserAgent
    , lastActiveAt : Effect.Time.Posix
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V417.Id.Id messageId) (Evergreen.V417.Message.Message messageId (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId))
    , newUsers : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId, Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.Message.Message Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId, Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId, Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ThreadMessageId) (Evergreen.V417.Message.Message Evergreen.V417.Id.ThreadMessageId (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.Message.Message Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V417.Id.Id Evergreen.V417.Id.UserId, Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ThreadMessageId) (Evergreen.V417.Message.Message Evergreen.V417.Id.ThreadMessageId (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId, Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.Message.Message Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId, Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId, Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ThreadMessageId) (Evergreen.V417.Message.Message Evergreen.V417.Id.ThreadMessageId (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.Message.Message Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) DiscordFrontendUser
    , slackChannels : SeqDict.SeqDict ( Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId, Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId ) (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.Message.Message Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId)))
    , slackThreads : SeqDict.SeqDict ( Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId, Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId, Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ThreadMessageId) (Evergreen.V417.Message.Message Evergreen.V417.Id.ThreadMessageId (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId)))
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.DmChannelId) (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.Message.Message Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId)))
    , slackDmThreads : SeqDict.SeqDict ( Evergreen.V417.Slack.Id Evergreen.V417.Slack.DmChannelId, Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ThreadMessageId) (Evergreen.V417.Message.Message Evergreen.V417.Id.ThreadMessageId (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId)))
    }
