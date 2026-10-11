module Evergreen.V403.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V403.Discord
import Evergreen.V403.FileStatus
import Evergreen.V403.Id
import Evergreen.V403.IdArray
import Evergreen.V403.Message
import Evergreen.V403.PersonName
import Evergreen.V403.Ports
import Evergreen.V403.SessionIdHash
import Evergreen.V403.UserAgent
import Evergreen.V403.UserColor
import SeqDict
import SeqSet


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId)) (Maybe Evergreen.V403.Message.RepliedToGame)
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
    | Subscribed Evergreen.V403.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V403.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias SheepGameQuestion =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId) Evergreen.V403.FileStatus.FileStatus
    }


type LastViewedGuild
    = LastViewedGuild (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId)
    | LastViewedDiscordGuild (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId)


type alias UserSession =
    { userId : Evergreen.V403.Id.Id Evergreen.V403.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V403.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V403.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    , lastClientDisconnect : Maybe Effect.Time.Posix
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , savedSheepGameQuestions : Evergreen.V403.IdArray.IdArray Evergreen.V403.Id.QuestionId SheepGameQuestion
    , lastViewedGuild : Maybe LastViewedGuild
    }


type PreviouslyLastViewedMessage messageId
    = DontCare
    | PreviouslyLastViewedMessage (Evergreen.V403.Id.Id messageId)


type alias Viewing_DmData =
    { id : Evergreen.V403.Id.Viewing_DmId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V403.Id.ChannelMessageId
    }


type alias Viewing_DmThreadData =
    { id : Evergreen.V403.Id.Viewing_DmThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V403.Id.ThreadMessageId
    }


type alias Viewing_DiscordDmData =
    { id : Evergreen.V403.Id.Viewing_DiscordDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V403.Id.ChannelMessageId
    }


type alias Viewing_ChannelData =
    { id : Evergreen.V403.Id.Viewing_ChannelId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V403.Id.ChannelMessageId
    }


type alias Viewing_ChannelThreadData =
    { id : Evergreen.V403.Id.Viewing_ChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V403.Id.ThreadMessageId
    }


type alias Viewing_DiscordChannelData =
    { id : Evergreen.V403.Id.Viewing_DiscordChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V403.Id.ChannelMessageId
    }


type alias Viewing_DiscordChannelThreadData =
    { id : Evergreen.V403.Id.Viewing_DiscordChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V403.Id.ThreadMessageId
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
    { name : Evergreen.V403.PersonName.PersonName
    , icon : Maybe Evergreen.V403.FileStatus.FileHash
    , color : Evergreen.V403.UserColor.UserColor
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V403.UserAgent.UserAgent
    , lastActiveAt : Effect.Time.Posix
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V403.Id.Id messageId) (Evergreen.V403.Message.Message messageId (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId))
    , newUsers : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId, Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (Evergreen.V403.Message.Message Evergreen.V403.Id.ChannelMessageId (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId, Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId, Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ThreadMessageId) (Evergreen.V403.Message.Message Evergreen.V403.Id.ThreadMessageId (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (Evergreen.V403.Message.Message Evergreen.V403.Id.ChannelMessageId (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V403.Id.Id Evergreen.V403.Id.UserId, Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ThreadMessageId) (Evergreen.V403.Message.Message Evergreen.V403.Id.ThreadMessageId (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId, Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (Evergreen.V403.Message.Message Evergreen.V403.Id.ChannelMessageId (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId, Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId, Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ThreadMessageId) (Evergreen.V403.Message.Message Evergreen.V403.Id.ThreadMessageId (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (Evergreen.V403.Message.Message Evergreen.V403.Id.ChannelMessageId (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) DiscordFrontendUser
    }
