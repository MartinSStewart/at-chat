module Evergreen.V411.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V411.Discord
import Evergreen.V411.FileStatus
import Evergreen.V411.Id
import Evergreen.V411.IdArray
import Evergreen.V411.Message
import Evergreen.V411.PersonName
import Evergreen.V411.Ports
import Evergreen.V411.SessionIdHash
import Evergreen.V411.Slack
import Evergreen.V411.UserAgent
import Evergreen.V411.UserColor
import SeqDict
import SeqSet


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId)) (Maybe Evergreen.V411.Message.RepliedToGame)
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
    | Subscribed Evergreen.V411.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V411.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias SheepGameQuestion =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.FileStatus.FileId) Evergreen.V411.FileStatus.FileStatus
    }


type LastViewedGuild
    = LastViewedGuild (Evergreen.V411.Id.Id Evergreen.V411.Id.GuildId)
    | LastViewedDiscordGuild (Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId)
    | LastViewedSlackWorkspace (Evergreen.V411.Slack.Id Evergreen.V411.Slack.TeamId)


type alias UserSession =
    { userId : Evergreen.V411.Id.Id Evergreen.V411.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V411.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V411.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    , lastClientDisconnect : Maybe Effect.Time.Posix
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , savedSheepGameQuestions : Evergreen.V411.IdArray.IdArray Evergreen.V411.Id.QuestionId SheepGameQuestion
    , lastViewedGuild : Maybe LastViewedGuild
    }


type PreviouslyLastViewedMessage messageId
    = DontCare
    | PreviouslyLastViewedMessage (Evergreen.V411.Id.Id messageId)


type alias Viewing_DmData =
    { id : Evergreen.V411.Id.Viewing_DmId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V411.Id.ChannelMessageId
    }


type alias Viewing_DmThreadData =
    { id : Evergreen.V411.Id.Viewing_DmThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V411.Id.ThreadMessageId
    }


type alias Viewing_DiscordDmData =
    { id : Evergreen.V411.Id.Viewing_DiscordDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V411.Id.ChannelMessageId
    }


type alias Viewing_ChannelData =
    { id : Evergreen.V411.Id.Viewing_ChannelId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V411.Id.ChannelMessageId
    }


type alias Viewing_ChannelThreadData =
    { id : Evergreen.V411.Id.Viewing_ChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V411.Id.ThreadMessageId
    }


type alias Viewing_DiscordChannelData =
    { id : Evergreen.V411.Id.Viewing_DiscordChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V411.Id.ChannelMessageId
    }


type alias Viewing_DiscordChannelThreadData =
    { id : Evergreen.V411.Id.Viewing_DiscordChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V411.Id.ThreadMessageId
    }


type alias Viewing_SlackChannelData =
    { id : Evergreen.V411.Id.Viewing_SlackChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V411.Id.ChannelMessageId
    }


type alias Viewing_SlackChannelThreadData =
    { id : Evergreen.V411.Id.Viewing_SlackChannelId
    , threadId : Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V411.Id.ThreadMessageId
    }


type alias Viewing_SlackDmData =
    { id : Evergreen.V411.Id.Viewing_SlackDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V411.Id.ChannelMessageId
    }


type alias Viewing_SlackDmThreadData =
    { id : Evergreen.V411.Id.Viewing_SlackDmId
    , threadId : Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V411.Id.ThreadMessageId
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
    { name : Evergreen.V411.PersonName.PersonName
    , icon : Maybe Evergreen.V411.FileStatus.FileHash
    , color : Evergreen.V411.UserColor.UserColor
    , teamId : Evergreen.V411.Slack.Id Evergreen.V411.Slack.TeamId
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V411.PersonName.PersonName
    , icon : Maybe Evergreen.V411.FileStatus.FileHash
    , color : Evergreen.V411.UserColor.UserColor
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V411.UserAgent.UserAgent
    , lastActiveAt : Effect.Time.Posix
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V411.Id.Id messageId) (Evergreen.V411.Message.Message messageId (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId) (Evergreen.V411.Discord.Id Evergreen.V411.Discord.ChannelId))
    , newUsers : SeqDict.SeqDict (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V411.Id.Id Evergreen.V411.Id.GuildId, Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId) (Evergreen.V411.Message.Message Evergreen.V411.Id.ChannelMessageId (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V411.Id.Id Evergreen.V411.Id.GuildId, Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelId, Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.ThreadMessageId) (Evergreen.V411.Message.Message Evergreen.V411.Id.ThreadMessageId (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) (SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId) (Evergreen.V411.Message.Message Evergreen.V411.Id.ChannelMessageId (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V411.Id.Id Evergreen.V411.Id.UserId, Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.ThreadMessageId) (Evergreen.V411.Message.Message Evergreen.V411.Id.ThreadMessageId (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId, Evergreen.V411.Discord.Id Evergreen.V411.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId) (Evergreen.V411.Message.Message Evergreen.V411.Id.ChannelMessageId (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId) (Evergreen.V411.Discord.Id Evergreen.V411.Discord.ChannelId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId, Evergreen.V411.Discord.Id Evergreen.V411.Discord.ChannelId, Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.ThreadMessageId) (Evergreen.V411.Message.Message Evergreen.V411.Id.ThreadMessageId (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId) (Evergreen.V411.Discord.Id Evergreen.V411.Discord.ChannelId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V411.Discord.Id Evergreen.V411.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId) (Evergreen.V411.Message.Message Evergreen.V411.Id.ChannelMessageId (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId) (Evergreen.V411.Discord.Id Evergreen.V411.Discord.ChannelId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId) DiscordFrontendUser
    , slackChannels : SeqDict.SeqDict ( Evergreen.V411.Slack.Id Evergreen.V411.Slack.TeamId, Evergreen.V411.Slack.Id Evergreen.V411.Slack.ChannelId ) (SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId) (Evergreen.V411.Message.Message Evergreen.V411.Id.ChannelMessageId (Evergreen.V411.Slack.Id Evergreen.V411.Slack.UserId) (Evergreen.V411.Slack.Id Evergreen.V411.Slack.ChannelId)))
    , slackThreads : SeqDict.SeqDict ( Evergreen.V411.Slack.Id Evergreen.V411.Slack.TeamId, Evergreen.V411.Slack.Id Evergreen.V411.Slack.ChannelId, Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.ThreadMessageId) (Evergreen.V411.Message.Message Evergreen.V411.Id.ThreadMessageId (Evergreen.V411.Slack.Id Evergreen.V411.Slack.UserId) (Evergreen.V411.Slack.Id Evergreen.V411.Slack.ChannelId)))
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V411.Slack.Id Evergreen.V411.Slack.DmChannelId) (SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId) (Evergreen.V411.Message.Message Evergreen.V411.Id.ChannelMessageId (Evergreen.V411.Slack.Id Evergreen.V411.Slack.UserId) (Evergreen.V411.Slack.Id Evergreen.V411.Slack.ChannelId)))
    , slackDmThreads : SeqDict.SeqDict ( Evergreen.V411.Slack.Id Evergreen.V411.Slack.DmChannelId, Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.ThreadMessageId) (Evergreen.V411.Message.Message Evergreen.V411.Id.ThreadMessageId (Evergreen.V411.Slack.Id Evergreen.V411.Slack.UserId) (Evergreen.V411.Slack.Id Evergreen.V411.Slack.ChannelId)))
    }
