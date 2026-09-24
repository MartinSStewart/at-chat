module Evergreen.V385.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V385.Discord
import Evergreen.V385.FileStatus
import Evergreen.V385.Id
import Evergreen.V385.IdArray
import Evergreen.V385.Message
import Evergreen.V385.PersonName
import Evergreen.V385.Ports
import Evergreen.V385.SessionIdHash
import Evergreen.V385.UserAgent
import Evergreen.V385.UserColor
import SeqDict
import SeqSet


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId)) (Maybe Evergreen.V385.Message.RepliedToGame)
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


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V385.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V385.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias SheepGameQuestion =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId) Evergreen.V385.FileStatus.FileStatus
    }


type alias UserSession =
    { userId : Evergreen.V385.Id.Id Evergreen.V385.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V385.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V385.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    , lastClientDisconnect : Maybe Effect.Time.Posix
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , savedSheepGameQuestions : Evergreen.V385.IdArray.IdArray Evergreen.V385.Id.QuestionId SheepGameQuestion
    }


type PreviouslyLastViewedMessage messageId
    = DontCare
    | PreviouslyLastViewedMessage (Evergreen.V385.Id.Id messageId)


type alias Viewing_DmData =
    { id : Evergreen.V385.Id.Viewing_DmId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V385.Id.ChannelMessageId
    }


type alias Viewing_DmThreadData =
    { id : Evergreen.V385.Id.Viewing_DmThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V385.Id.ThreadMessageId
    }


type alias Viewing_DiscordDmData =
    { id : Evergreen.V385.Id.Viewing_DiscordDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V385.Id.ChannelMessageId
    }


type alias Viewing_ChannelData =
    { id : Evergreen.V385.Id.Viewing_ChannelId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V385.Id.ChannelMessageId
    }


type alias Viewing_ChannelThreadData =
    { id : Evergreen.V385.Id.Viewing_ChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V385.Id.ThreadMessageId
    }


type alias Viewing_DiscordChannelData =
    { id : Evergreen.V385.Id.Viewing_DiscordChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V385.Id.ChannelMessageId
    }


type alias Viewing_DiscordChannelThreadData =
    { id : Evergreen.V385.Id.Viewing_DiscordChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V385.Id.ThreadMessageId
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
    { name : Evergreen.V385.PersonName.PersonName
    , icon : Maybe Evergreen.V385.FileStatus.FileHash
    , color : Evergreen.V385.UserColor.UserColor
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V385.UserAgent.UserAgent
    , lastActiveAt : Effect.Time.Posix
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V385.Id.Id messageId) (Evergreen.V385.Message.Message messageId (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId, Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (Evergreen.V385.Message.Message Evergreen.V385.Id.ChannelMessageId (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId, Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId, Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ThreadMessageId) (Evergreen.V385.Message.Message Evergreen.V385.Id.ThreadMessageId (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (Evergreen.V385.Message.Message Evergreen.V385.Id.ChannelMessageId (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V385.Id.Id Evergreen.V385.Id.UserId, Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ThreadMessageId) (Evergreen.V385.Message.Message Evergreen.V385.Id.ThreadMessageId (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId, Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (Evergreen.V385.Message.Message Evergreen.V385.Id.ChannelMessageId (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId, Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId, Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ThreadMessageId) (Evergreen.V385.Message.Message Evergreen.V385.Id.ThreadMessageId (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (Evergreen.V385.Message.Message Evergreen.V385.Id.ChannelMessageId (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) DiscordFrontendUser
    }
