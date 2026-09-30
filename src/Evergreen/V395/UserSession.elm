module Evergreen.V395.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V395.Discord
import Evergreen.V395.FileStatus
import Evergreen.V395.Id
import Evergreen.V395.IdArray
import Evergreen.V395.Message
import Evergreen.V395.PersonName
import Evergreen.V395.Ports
import Evergreen.V395.SessionIdHash
import Evergreen.V395.UserAgent
import Evergreen.V395.UserColor
import SeqDict
import SeqSet


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId)) (Maybe Evergreen.V395.Message.RepliedToGame)
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


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V395.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V395.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias SheepGameQuestion =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId) Evergreen.V395.FileStatus.FileStatus
    }


type LastViewedGuild
    = LastViewedGuild (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId)
    | LastViewedDiscordGuild (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId)


type alias UserSession =
    { userId : Evergreen.V395.Id.Id Evergreen.V395.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V395.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V395.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    , lastClientDisconnect : Maybe Effect.Time.Posix
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , savedSheepGameQuestions : Evergreen.V395.IdArray.IdArray Evergreen.V395.Id.QuestionId SheepGameQuestion
    , lastViewedGuild : Maybe LastViewedGuild
    }


type PreviouslyLastViewedMessage messageId
    = DontCare
    | PreviouslyLastViewedMessage (Evergreen.V395.Id.Id messageId)


type alias Viewing_DmData =
    { id : Evergreen.V395.Id.Viewing_DmId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V395.Id.ChannelMessageId
    }


type alias Viewing_DmThreadData =
    { id : Evergreen.V395.Id.Viewing_DmThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V395.Id.ThreadMessageId
    }


type alias Viewing_DiscordDmData =
    { id : Evergreen.V395.Id.Viewing_DiscordDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V395.Id.ChannelMessageId
    }


type alias Viewing_ChannelData =
    { id : Evergreen.V395.Id.Viewing_ChannelId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V395.Id.ChannelMessageId
    }


type alias Viewing_ChannelThreadData =
    { id : Evergreen.V395.Id.Viewing_ChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V395.Id.ThreadMessageId
    }


type alias Viewing_DiscordChannelData =
    { id : Evergreen.V395.Id.Viewing_DiscordChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V395.Id.ChannelMessageId
    }


type alias Viewing_DiscordChannelThreadData =
    { id : Evergreen.V395.Id.Viewing_DiscordChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V395.Id.ThreadMessageId
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


type alias DiscordFrontendUser =
    { name : Evergreen.V395.PersonName.PersonName
    , icon : Maybe Evergreen.V395.FileStatus.FileHash
    , color : Evergreen.V395.UserColor.UserColor
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V395.UserAgent.UserAgent
    , lastActiveAt : Effect.Time.Posix
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V395.Id.Id messageId) (Evergreen.V395.Message.Message messageId (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId))
    , newUsers : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId, Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (Evergreen.V395.Message.Message Evergreen.V395.Id.ChannelMessageId (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId, Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId, Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ThreadMessageId) (Evergreen.V395.Message.Message Evergreen.V395.Id.ThreadMessageId (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (Evergreen.V395.Message.Message Evergreen.V395.Id.ChannelMessageId (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V395.Id.Id Evergreen.V395.Id.UserId, Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ThreadMessageId) (Evergreen.V395.Message.Message Evergreen.V395.Id.ThreadMessageId (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId, Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (Evergreen.V395.Message.Message Evergreen.V395.Id.ChannelMessageId (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId, Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId, Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ThreadMessageId) (Evergreen.V395.Message.Message Evergreen.V395.Id.ThreadMessageId (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (Evergreen.V395.Message.Message Evergreen.V395.Id.ChannelMessageId (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) DiscordFrontendUser
    }
