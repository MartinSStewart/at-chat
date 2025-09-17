module Evergreen.V77.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Time
import Evergreen.V77.ChannelName
import Evergreen.V77.DmChannel
import Evergreen.V77.FileStatus
import Evergreen.V77.GuildName
import Evergreen.V77.Id
import Evergreen.V77.Log
import Evergreen.V77.Message
import Evergreen.V77.NonemptyDict
import Evergreen.V77.OneToOne
import Evergreen.V77.SecretId
import Evergreen.V77.Slack
import Evergreen.V77.User
import Evergreen.V77.UserAgent
import Evergreen.V77.VisibleMessages
import SeqDict
import Url


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type alias SubscribeData =
    { endpoint : Url.Url
    , auth : String
    , p256dh : String
    }


type PushSubscription
    = NotSubscribed
    | Subscribed SubscribeData
    | SubscriptionError Effect.Http.Error


type alias UserSession =
    { userId : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    }


type DiscordBotToken
    = DiscordBotToken String


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
    , name : Evergreen.V77.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V77.Message.MessageState Evergreen.V77.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V77.VisibleMessages.VisibleMessages Evergreen.V77.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) (Evergreen.V77.DmChannel.LastTypedAt Evergreen.V77.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelMessageId) Evergreen.V77.DmChannel.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
    , name : Evergreen.V77.GuildName.GuildName
    , icon : Maybe Evergreen.V77.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V77.SecretId.SecretId Evergreen.V77.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V77.NonemptyDict.NonemptyDict (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) Evergreen.V77.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V77.Slack.ClientSecret
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : UserSession
    , user : Evergreen.V77.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) Evergreen.V77.User.FrontendUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V77.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) Evergreen.V77.DmChannel.FrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , publicVapidKey : String
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V77.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
    , name : Evergreen.V77.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V77.Message.Message Evergreen.V77.Id.ChannelMessageId)
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) (Evergreen.V77.DmChannel.LastTypedAt Evergreen.V77.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V77.OneToOne.OneToOne Evergreen.V77.DmChannel.ExternalMessageId (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelMessageId) Evergreen.V77.DmChannel.Thread
    , linkedThreadIds : Evergreen.V77.OneToOne.OneToOne Evergreen.V77.DmChannel.ExternalChannelId (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelMessageId)
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
    , name : Evergreen.V77.GuildName.GuildName
    , icon : Maybe Evergreen.V77.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelId) BackendChannel
    , linkedChannelIds : Evergreen.V77.OneToOne.OneToOne Evergreen.V77.DmChannel.ExternalChannelId (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelId)
    , members :
        SeqDict.SeqDict
            (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V77.SecretId.SecretId Evergreen.V77.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
            }
    }
