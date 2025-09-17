module Evergreen.V76.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Time
import Evergreen.V76.ChannelName
import Evergreen.V76.DmChannel
import Evergreen.V76.FileStatus
import Evergreen.V76.GuildName
import Evergreen.V76.Id
import Evergreen.V76.Log
import Evergreen.V76.Message
import Evergreen.V76.NonemptyDict
import Evergreen.V76.OneToOne
import Evergreen.V76.SecretId
import Evergreen.V76.Slack
import Evergreen.V76.User
import Evergreen.V76.VisibleMessages
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
    { userId : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    }


type DiscordBotToken
    = DiscordBotToken String


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
    , name : Evergreen.V76.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V76.Message.MessageState Evergreen.V76.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V76.VisibleMessages.VisibleMessages Evergreen.V76.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) (Evergreen.V76.DmChannel.LastTypedAt Evergreen.V76.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelMessageId) Evergreen.V76.DmChannel.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
    , name : Evergreen.V76.GuildName.GuildName
    , icon : Maybe Evergreen.V76.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V76.SecretId.SecretId Evergreen.V76.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V76.NonemptyDict.NonemptyDict (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) Evergreen.V76.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V76.Slack.ClientSecret
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : UserSession
    , user : Evergreen.V76.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) Evergreen.V76.User.FrontendUser
    , timezone : Effect.Time.Zone
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) Evergreen.V76.DmChannel.FrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , publicVapidKey : String
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V76.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
    , name : Evergreen.V76.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V76.Message.Message Evergreen.V76.Id.ChannelMessageId)
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) (Evergreen.V76.DmChannel.LastTypedAt Evergreen.V76.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V76.OneToOne.OneToOne Evergreen.V76.DmChannel.ExternalMessageId (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelMessageId) Evergreen.V76.DmChannel.Thread
    , linkedThreadIds : Evergreen.V76.OneToOne.OneToOne Evergreen.V76.DmChannel.ExternalChannelId (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelMessageId)
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
    , name : Evergreen.V76.GuildName.GuildName
    , icon : Maybe Evergreen.V76.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelId) BackendChannel
    , linkedChannelIds : Evergreen.V76.OneToOne.OneToOne Evergreen.V76.DmChannel.ExternalChannelId (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelId)
    , members :
        SeqDict.SeqDict
            (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V76.SecretId.SecretId Evergreen.V76.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
            }
    }
