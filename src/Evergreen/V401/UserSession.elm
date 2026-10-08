module Evergreen.V401.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V401.Discord
import Evergreen.V401.FileStatus
import Evergreen.V401.Id
import Evergreen.V401.IdArray
import Evergreen.V401.Message
import Evergreen.V401.PersonName
import Evergreen.V401.Ports
import Evergreen.V401.SessionIdHash
import Evergreen.V401.UserAgent
import Evergreen.V401.UserColor
import SeqDict
import SeqSet


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId)) (Maybe Evergreen.V401.Message.RepliedToGame)
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
    | Subscribed Evergreen.V401.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V401.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias SheepGameQuestion =
    { text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId) Evergreen.V401.FileStatus.FileStatus
    }


type LastViewedGuild
    = LastViewedGuild (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId)
    | LastViewedDiscordGuild (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId)


type alias UserSession =
    { userId : Evergreen.V401.Id.Id Evergreen.V401.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V401.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V401.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    , lastClientDisconnect : Maybe Effect.Time.Posix
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , savedSheepGameQuestions : Evergreen.V401.IdArray.IdArray Evergreen.V401.Id.QuestionId SheepGameQuestion
    , lastViewedGuild : Maybe LastViewedGuild
    }


type PreviouslyLastViewedMessage messageId
    = DontCare
    | PreviouslyLastViewedMessage (Evergreen.V401.Id.Id messageId)


type alias Viewing_DmData =
    { id : Evergreen.V401.Id.Viewing_DmId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V401.Id.ChannelMessageId
    }


type alias Viewing_DmThreadData =
    { id : Evergreen.V401.Id.Viewing_DmThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V401.Id.ThreadMessageId
    }


type alias Viewing_DiscordDmData =
    { id : Evergreen.V401.Id.Viewing_DiscordDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V401.Id.ChannelMessageId
    }


type alias Viewing_ChannelData =
    { id : Evergreen.V401.Id.Viewing_ChannelId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V401.Id.ChannelMessageId
    }


type alias Viewing_ChannelThreadData =
    { id : Evergreen.V401.Id.Viewing_ChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V401.Id.ThreadMessageId
    }


type alias Viewing_DiscordChannelData =
    { id : Evergreen.V401.Id.Viewing_DiscordChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V401.Id.ChannelMessageId
    }


type alias Viewing_DiscordChannelThreadData =
    { id : Evergreen.V401.Id.Viewing_DiscordChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage Evergreen.V401.Id.ThreadMessageId
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
    { name : Evergreen.V401.PersonName.PersonName
    , icon : Maybe Evergreen.V401.FileStatus.FileHash
    , color : Evergreen.V401.UserColor.UserColor
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V401.UserAgent.UserAgent
    , lastActiveAt : Effect.Time.Posix
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V401.Id.Id messageId) (Evergreen.V401.Message.Message messageId (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId))
    , newUsers : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) DiscordFrontendUser
    }


type alias UnreadOverviewData =
    { guildChannels : SeqDict.SeqDict ( Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId, Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId ) (SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (Evergreen.V401.Message.Message Evergreen.V401.Id.ChannelMessageId (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId)))
    , guildThreads : SeqDict.SeqDict ( Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId, Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId, Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ThreadMessageId) (Evergreen.V401.Message.Message Evergreen.V401.Id.ThreadMessageId (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId)))
    , dmChannels : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (Evergreen.V401.Message.Message Evergreen.V401.Id.ChannelMessageId (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId)))
    , dmThreads : SeqDict.SeqDict ( Evergreen.V401.Id.Id Evergreen.V401.Id.UserId, Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ThreadMessageId) (Evergreen.V401.Message.Message Evergreen.V401.Id.ThreadMessageId (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId)))
    , discordGuildChannels : SeqDict.SeqDict ( Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId, Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId ) (SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (Evergreen.V401.Message.Message Evergreen.V401.Id.ChannelMessageId (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId)))
    , discordGuildThreads : SeqDict.SeqDict ( Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId, Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId, Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId ) (SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ThreadMessageId) (Evergreen.V401.Message.Message Evergreen.V401.Id.ThreadMessageId (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId)))
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId) (SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (Evergreen.V401.Message.Message Evergreen.V401.Id.ChannelMessageId (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId)))
    , discordUsers : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) DiscordFrontendUser
    }
