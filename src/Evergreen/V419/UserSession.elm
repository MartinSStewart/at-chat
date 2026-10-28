module Evergreen.V419.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V419.Discord
import Evergreen.V419.FileStatus
import Evergreen.V419.Id
import Evergreen.V419.IdArray
import Evergreen.V419.Message
import Evergreen.V419.PersonName
import Evergreen.V419.Ports
import Evergreen.V419.SessionIdHash
import Evergreen.V419.Slack
import Evergreen.V419.UserAgent
import Evergreen.V419.UserColor
import SeqDict
import SeqSet


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId)) (Maybe Evergreen.V419.Message.RepliedToGame)
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
    | Subscribed Evergreen.V419.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V419.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias SheepGameQuestion =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId) Evergreen.V419.FileStatus.FileStatus
    }


type LastViewedGuild
    = LastViewedGuild (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId)
    | LastViewedDiscordGuild (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId)
    | LastViewedSlackWorkspace (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId)


type alias UserSession =
    { userId : Evergreen.V419.Id.Id Evergreen.V419.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V419.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V419.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    , lastClientDisconnect : Maybe Effect.Time.Posix
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , savedSheepGameQuestions : Evergreen.V419.IdArray.IdArray Evergreen.V419.Id.QuestionId SheepGameQuestion
    , lastViewedGuild : Maybe LastViewedGuild
    }


type PreviouslyLastViewedMessage messageId
    = DontCare
    | PreviouslyLastViewedMessage (Evergreen.V419.Id.Id messageId)


type alias Viewing_DmData =
    { id : Evergreen.V419.Id.Viewing_DmId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V419.Id.ChannelMessageId
    }


type alias Viewing_DmThreadData =
    { id : Evergreen.V419.Id.Viewing_DmThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V419.Id.ThreadMessageId
    }


type alias Viewing_DiscordDmData =
    { id : Evergreen.V419.Id.Viewing_DiscordDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V419.Id.ChannelMessageId
    }


type alias Viewing_ChannelData =
    { id : Evergreen.V419.Id.Viewing_ChannelId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V419.Id.ChannelMessageId
    }


type alias Viewing_ChannelThreadData =
    { id : Evergreen.V419.Id.Viewing_ChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V419.Id.ThreadMessageId
    }


type alias Viewing_DiscordChannelData =
    { id : Evergreen.V419.Id.Viewing_DiscordChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V419.Id.ChannelMessageId
    }


type alias Viewing_DiscordChannelThreadData =
    { id : Evergreen.V419.Id.Viewing_DiscordChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V419.Id.ThreadMessageId
    }


type alias Viewing_SlackChannelData =
    { id : Evergreen.V419.Id.Viewing_SlackChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V419.Id.ChannelMessageId
    }


type alias Viewing_SlackChannelThreadData =
    { id : Evergreen.V419.Id.Viewing_SlackChannelId
    , threadId : Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V419.Id.ThreadMessageId
    }


type alias Viewing_SlackDmData =
    { id : Evergreen.V419.Id.Viewing_SlackDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V419.Id.ChannelMessageId
    }


type alias Viewing_SlackDmThreadData =
    { id : Evergreen.V419.Id.Viewing_SlackDmId
    , threadId : Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V419.Id.ThreadMessageId
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
    { name : Evergreen.V419.PersonName.PersonName
    , icon : Maybe Evergreen.V419.FileStatus.FileHash
    , color : Evergreen.V419.UserColor.UserColor
    , teamId : Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId
    }


type alias DiscordFrontendUser =
    { name : Evergreen.V419.PersonName.PersonName
    , icon : Maybe Evergreen.V419.FileStatus.FileHash
    , color : Evergreen.V419.UserColor.UserColor
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V419.UserAgent.UserAgent
    , lastActiveAt : Effect.Time.Posix
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V419.Id.Id messageId) (Evergreen.V419.Message.Message messageId (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId))
    , newUsers : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId, Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.Message.Message Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId, Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId, Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ThreadMessageId) (Evergreen.V419.Message.Message Evergreen.V419.Id.ThreadMessageId (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.Message.Message Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V419.Id.Id Evergreen.V419.Id.UserId, Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ThreadMessageId) (Evergreen.V419.Message.Message Evergreen.V419.Id.ThreadMessageId (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId, Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.Message.Message Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId, Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId, Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ThreadMessageId) (Evergreen.V419.Message.Message Evergreen.V419.Id.ThreadMessageId (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.Message.Message Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) DiscordFrontendUser
    , slackChannels : SeqDict.SeqDict ( Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId, Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId ) (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.Message.Message Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId)))
    , slackThreads : SeqDict.SeqDict ( Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId, Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId, Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ThreadMessageId) (Evergreen.V419.Message.Message Evergreen.V419.Id.ThreadMessageId (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId)))
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.DmChannelId) (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.Message.Message Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId)))
    , slackDmThreads : SeqDict.SeqDict ( Evergreen.V419.Slack.Id Evergreen.V419.Slack.DmChannelId, Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ThreadMessageId) (Evergreen.V419.Message.Message Evergreen.V419.Id.ThreadMessageId (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId)))
    }
