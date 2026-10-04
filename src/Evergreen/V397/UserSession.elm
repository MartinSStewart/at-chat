module Evergreen.V397.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V397.Discord
import Evergreen.V397.FileStatus
import Evergreen.V397.Id
import Evergreen.V397.IdArray
import Evergreen.V397.Message
import Evergreen.V397.PersonName
import Evergreen.V397.Ports
import Evergreen.V397.SessionIdHash
import Evergreen.V397.UserAgent
import Evergreen.V397.UserColor
import SeqDict
import SeqSet


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId)) (Maybe Evergreen.V397.Message.RepliedToGame)
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
    | Subscribed Evergreen.V397.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V397.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias SheepGameQuestion =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId) Evergreen.V397.FileStatus.FileStatus
    }


type LastViewedGuild
    = LastViewedGuild (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId)
    | LastViewedDiscordGuild (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId)


type alias UserSession =
    { userId : Evergreen.V397.Id.Id Evergreen.V397.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V397.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V397.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    , lastClientDisconnect : Maybe Effect.Time.Posix
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , savedSheepGameQuestions : Evergreen.V397.IdArray.IdArray Evergreen.V397.Id.QuestionId SheepGameQuestion
    , lastViewedGuild : Maybe LastViewedGuild
    }


type PreviouslyLastViewedMessage messageId
    = DontCare
    | PreviouslyLastViewedMessage (Evergreen.V397.Id.Id messageId)


type alias Viewing_DmData =
    { id : Evergreen.V397.Id.Viewing_DmId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V397.Id.ChannelMessageId
    }


type alias Viewing_DmThreadData =
    { id : Evergreen.V397.Id.Viewing_DmThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V397.Id.ThreadMessageId
    }


type alias Viewing_DiscordDmData =
    { id : Evergreen.V397.Id.Viewing_DiscordDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V397.Id.ChannelMessageId
    }


type alias Viewing_ChannelData =
    { id : Evergreen.V397.Id.Viewing_ChannelId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V397.Id.ChannelMessageId
    }


type alias Viewing_ChannelThreadData =
    { id : Evergreen.V397.Id.Viewing_ChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V397.Id.ThreadMessageId
    }


type alias Viewing_DiscordChannelData =
    { id : Evergreen.V397.Id.Viewing_DiscordChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V397.Id.ChannelMessageId
    }


type alias Viewing_DiscordChannelThreadData =
    { id : Evergreen.V397.Id.Viewing_DiscordChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V397.Id.ThreadMessageId
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
    { name : Evergreen.V397.PersonName.PersonName
    , icon : Maybe Evergreen.V397.FileStatus.FileHash
    , color : Evergreen.V397.UserColor.UserColor
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V397.UserAgent.UserAgent
    , lastActiveAt : Effect.Time.Posix
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V397.Id.Id messageId) (Evergreen.V397.Message.Message messageId (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId))
    , newUsers : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId, Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (Evergreen.V397.Message.Message Evergreen.V397.Id.ChannelMessageId (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId, Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId, Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ThreadMessageId) (Evergreen.V397.Message.Message Evergreen.V397.Id.ThreadMessageId (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (Evergreen.V397.Message.Message Evergreen.V397.Id.ChannelMessageId (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V397.Id.Id Evergreen.V397.Id.UserId, Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ThreadMessageId) (Evergreen.V397.Message.Message Evergreen.V397.Id.ThreadMessageId (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId, Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (Evergreen.V397.Message.Message Evergreen.V397.Id.ChannelMessageId (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId, Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId, Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ThreadMessageId) (Evergreen.V397.Message.Message Evergreen.V397.Id.ThreadMessageId (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (Evergreen.V397.Message.Message Evergreen.V397.Id.ChannelMessageId (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) DiscordFrontendUser
    }
