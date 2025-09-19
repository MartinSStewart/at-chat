module Evergreen.V90.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V90.ChannelName
import Evergreen.V90.DmChannel
import Evergreen.V90.FileStatus
import Evergreen.V90.GuildName
import Evergreen.V90.Id
import Evergreen.V90.Log
import Evergreen.V90.Message
import Evergreen.V90.NonemptyDict
import Evergreen.V90.OneToOne
import Evergreen.V90.SecretId
import Evergreen.V90.Slack
import Evergreen.V90.User
import Evergreen.V90.UserAgent
import Evergreen.V90.UserSession
import Evergreen.V90.VisibleMessages
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V90.Id.Id Evergreen.V90.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V90.Id.Id Evergreen.V90.Id.UserId
    , name : Evergreen.V90.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V90.Message.MessageState Evergreen.V90.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V90.VisibleMessages.VisibleMessages Evergreen.V90.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) (Evergreen.V90.DmChannel.LastTypedAt Evergreen.V90.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelMessageId) Evergreen.V90.DmChannel.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V90.Id.Id Evergreen.V90.Id.UserId
    , name : Evergreen.V90.GuildName.GuildName
    , icon : Maybe Evergreen.V90.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V90.Id.Id Evergreen.V90.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V90.SecretId.SecretId Evergreen.V90.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V90.Id.Id Evergreen.V90.Id.UserId
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V90.NonemptyDict.NonemptyDict (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) Evergreen.V90.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V90.Slack.ClientSecret
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V90.UserSession.UserSession
    , user : Evergreen.V90.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) Evergreen.V90.User.FrontendUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V90.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) Evergreen.V90.DmChannel.FrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V90.UserSession.FrontendUserSession
    , publicVapidKey : String
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V90.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V90.Id.Id Evergreen.V90.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V90.Id.Id Evergreen.V90.Id.UserId
    , name : Evergreen.V90.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V90.Message.Message Evergreen.V90.Id.ChannelMessageId)
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) (Evergreen.V90.DmChannel.LastTypedAt Evergreen.V90.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V90.OneToOne.OneToOne Evergreen.V90.DmChannel.ExternalMessageId (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelMessageId) Evergreen.V90.DmChannel.Thread
    , linkedThreadIds : Evergreen.V90.OneToOne.OneToOne Evergreen.V90.DmChannel.ExternalChannelId (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelMessageId)
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V90.Id.Id Evergreen.V90.Id.UserId
    , name : Evergreen.V90.GuildName.GuildName
    , icon : Maybe Evergreen.V90.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelId) BackendChannel
    , linkedChannelIds : Evergreen.V90.OneToOne.OneToOne Evergreen.V90.DmChannel.ExternalChannelId (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelId)
    , members :
        SeqDict.SeqDict
            (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V90.Id.Id Evergreen.V90.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V90.SecretId.SecretId Evergreen.V90.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V90.Id.Id Evergreen.V90.Id.UserId
            }
    }
