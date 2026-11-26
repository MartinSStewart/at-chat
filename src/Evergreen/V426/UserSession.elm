module Evergreen.V426.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V426.Discord
import Evergreen.V426.FileStatus
import Evergreen.V426.Id
import Evergreen.V426.IdArray
import Evergreen.V426.Message
import Evergreen.V426.PersonName
import Evergreen.V426.Ports
import Evergreen.V426.SessionIdHash
import Evergreen.V426.Slack
import Evergreen.V426.UserAgent
import Evergreen.V426.UserColor
import SeqDict
import SeqSet


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId)) (Maybe Evergreen.V426.Message.RepliedToGame)
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
    | Subscribed Evergreen.V426.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V426.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias SheepGameQuestion =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId) Evergreen.V426.FileStatus.FileStatus
    }


type LastViewedGuild
    = LastViewedGuild (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId)
    | LastViewedDiscordGuild (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId)
    | LastViewedSlackWorkspace (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId)


type alias UserSession =
    { userId : Evergreen.V426.Id.Id Evergreen.V426.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V426.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V426.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    , lastClientDisconnect : Maybe Effect.Time.Posix
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , savedSheepGameQuestions : Evergreen.V426.IdArray.IdArray Evergreen.V426.Id.QuestionId SheepGameQuestion
    , lastViewedGuild : Maybe LastViewedGuild
    }


type PreviouslyLastViewedMessage messageId
    = DontCare
    | PreviouslyLastViewedMessage (Evergreen.V426.Id.Id messageId)


type alias Viewing_DmData =
    { id : Evergreen.V426.Id.Viewing_DmId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V426.Id.ChannelMessageId
    }


type alias Viewing_DmThreadData =
    { id : Evergreen.V426.Id.Viewing_DmThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V426.Id.ThreadMessageId
    }


type alias Viewing_DiscordDmData =
    { id : Evergreen.V426.Id.Viewing_DiscordDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V426.Id.ChannelMessageId
    }


type alias Viewing_ChannelData =
    { id : Evergreen.V426.Id.Viewing_ChannelId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V426.Id.ChannelMessageId
    }


type alias Viewing_ChannelThreadData =
    { id : Evergreen.V426.Id.Viewing_ChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V426.Id.ThreadMessageId
    }


type alias Viewing_DiscordChannelData =
    { id : Evergreen.V426.Id.Viewing_DiscordChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V426.Id.ChannelMessageId
    }


type alias Viewing_DiscordChannelThreadData =
    { id : Evergreen.V426.Id.Viewing_DiscordChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V426.Id.ThreadMessageId
    }


type alias Viewing_SlackChannelData =
    { id : Evergreen.V426.Id.Viewing_SlackChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V426.Id.ChannelMessageId
    }


type alias Viewing_SlackChannelThreadData =
    { id : Evergreen.V426.Id.Viewing_SlackChannelId
    , threadId : Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V426.Id.ThreadMessageId
    }


type alias Viewing_SlackDmData =
    { id : Evergreen.V426.Id.Viewing_SlackDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V426.Id.ChannelMessageId
    }


type alias Viewing_SlackDmThreadData =
    { id : Evergreen.V426.Id.Viewing_SlackDmId
    , threadId : Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V426.Id.ThreadMessageId
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
    { name : Evergreen.V426.PersonName.PersonName
    , icon : Maybe Evergreen.V426.FileStatus.FileHash
    , color : Evergreen.V426.UserColor.UserColor
    , teamId : Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V426.PersonName.PersonName
    , icon : Maybe Evergreen.V426.FileStatus.FileHash
    , color : Evergreen.V426.UserColor.UserColor
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V426.UserAgent.UserAgent
    , lastActiveAt : Effect.Time.Posix
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V426.Id.Id messageId) (Evergreen.V426.Message.Message messageId (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId))
    , newUsers : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId, Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.Message.Message Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId, Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId, Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ThreadMessageId) (Evergreen.V426.Message.Message Evergreen.V426.Id.ThreadMessageId (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.Message.Message Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V426.Id.Id Evergreen.V426.Id.UserId, Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ThreadMessageId) (Evergreen.V426.Message.Message Evergreen.V426.Id.ThreadMessageId (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId, Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.Message.Message Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId, Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId, Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ThreadMessageId) (Evergreen.V426.Message.Message Evergreen.V426.Id.ThreadMessageId (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.Message.Message Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) DiscordFrontendUser
    , slackChannels : SeqDict.SeqDict ( Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId, Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId ) (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.Message.Message Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId)))
    , slackThreads : SeqDict.SeqDict ( Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId, Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId, Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ThreadMessageId) (Evergreen.V426.Message.Message Evergreen.V426.Id.ThreadMessageId (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId)))
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.DmChannelId) (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.Message.Message Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId)))
    , slackDmThreads : SeqDict.SeqDict ( Evergreen.V426.Slack.Id Evergreen.V426.Slack.DmChannelId, Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ThreadMessageId) (Evergreen.V426.Message.Message Evergreen.V426.Id.ThreadMessageId (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId)))
    }
