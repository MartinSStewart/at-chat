module Evergreen.V402.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V402.Discord
import Evergreen.V402.FileStatus
import Evergreen.V402.Id
import Evergreen.V402.IdArray
import Evergreen.V402.Message
import Evergreen.V402.PersonName
import Evergreen.V402.Ports
import Evergreen.V402.SessionIdHash
import Evergreen.V402.UserAgent
import Evergreen.V402.UserColor
import SeqDict
import SeqSet


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId)) (Maybe Evergreen.V402.Message.RepliedToGame)
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
    | Subscribed Evergreen.V402.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V402.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias SheepGameQuestion =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId) Evergreen.V402.FileStatus.FileStatus
    }


type LastViewedGuild
    = LastViewedGuild (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId)
    | LastViewedDiscordGuild (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId)


type alias UserSession =
    { userId : Evergreen.V402.Id.Id Evergreen.V402.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V402.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V402.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    , lastClientDisconnect : Maybe Effect.Time.Posix
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , savedSheepGameQuestions : Evergreen.V402.IdArray.IdArray Evergreen.V402.Id.QuestionId SheepGameQuestion
    , lastViewedGuild : Maybe LastViewedGuild
    }


type PreviouslyLastViewedMessage messageId
    = DontCare
    | PreviouslyLastViewedMessage (Evergreen.V402.Id.Id messageId)


type alias Viewing_DmData =
    { id : Evergreen.V402.Id.Viewing_DmId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V402.Id.ChannelMessageId
    }


type alias Viewing_DmThreadData =
    { id : Evergreen.V402.Id.Viewing_DmThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V402.Id.ThreadMessageId
    }


type alias Viewing_DiscordDmData =
    { id : Evergreen.V402.Id.Viewing_DiscordDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V402.Id.ChannelMessageId
    }


type alias Viewing_ChannelData =
    { id : Evergreen.V402.Id.Viewing_ChannelId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V402.Id.ChannelMessageId
    }


type alias Viewing_ChannelThreadData =
    { id : Evergreen.V402.Id.Viewing_ChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V402.Id.ThreadMessageId
    }


type alias Viewing_DiscordChannelData =
    { id : Evergreen.V402.Id.Viewing_DiscordChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V402.Id.ChannelMessageId
    }


type alias Viewing_DiscordChannelThreadData =
    { id : Evergreen.V402.Id.Viewing_DiscordChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V402.Id.ThreadMessageId
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
    { name : Evergreen.V402.PersonName.PersonName
    , icon : Maybe Evergreen.V402.FileStatus.FileHash
    , color : Evergreen.V402.UserColor.UserColor
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V402.UserAgent.UserAgent
    , lastActiveAt : Effect.Time.Posix
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V402.Id.Id messageId) (Evergreen.V402.Message.Message messageId (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId))
    , newUsers : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId, Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (Evergreen.V402.Message.Message Evergreen.V402.Id.ChannelMessageId (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId, Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId, Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ThreadMessageId) (Evergreen.V402.Message.Message Evergreen.V402.Id.ThreadMessageId (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (Evergreen.V402.Message.Message Evergreen.V402.Id.ChannelMessageId (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V402.Id.Id Evergreen.V402.Id.UserId, Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ThreadMessageId) (Evergreen.V402.Message.Message Evergreen.V402.Id.ThreadMessageId (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId, Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (Evergreen.V402.Message.Message Evergreen.V402.Id.ChannelMessageId (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId, Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId, Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ThreadMessageId) (Evergreen.V402.Message.Message Evergreen.V402.Id.ThreadMessageId (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (Evergreen.V402.Message.Message Evergreen.V402.Id.ChannelMessageId (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) DiscordFrontendUser
    }
