module Evergreen.V104.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V104.ChannelName
import Evergreen.V104.DmChannel
import Evergreen.V104.FileStatus
import Evergreen.V104.GuildName
import Evergreen.V104.Id
import Evergreen.V104.Log
import Evergreen.V104.Message
import Evergreen.V104.NonemptyDict
import Evergreen.V104.OneToOne
import Evergreen.V104.SecretId
import Evergreen.V104.SessionIdHash
import Evergreen.V104.Slack
import Evergreen.V104.User
import Evergreen.V104.UserAgent
import Evergreen.V104.UserSession
import Evergreen.V104.VisibleMessages
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V104.Id.Id Evergreen.V104.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V104.Id.Id Evergreen.V104.Id.UserId
    , name : Evergreen.V104.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V104.Message.MessageState Evergreen.V104.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V104.VisibleMessages.VisibleMessages Evergreen.V104.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) (Evergreen.V104.DmChannel.LastTypedAt Evergreen.V104.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelMessageId) Evergreen.V104.DmChannel.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V104.Id.Id Evergreen.V104.Id.UserId
    , name : Evergreen.V104.GuildName.GuildName
    , icon : Maybe Evergreen.V104.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V104.Id.Id Evergreen.V104.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V104.SecretId.SecretId Evergreen.V104.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V104.Id.Id Evergreen.V104.Id.UserId
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V104.NonemptyDict.NonemptyDict (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) Evergreen.V104.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V104.Slack.ClientSecret
    , openRouterKey : Maybe String
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V104.UserSession.UserSession
    , user : Evergreen.V104.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) Evergreen.V104.User.FrontendUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V104.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) Evergreen.V104.DmChannel.FrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V104.SessionIdHash.SessionIdHash Evergreen.V104.UserSession.FrontendUserSession
    , publicVapidKey : String
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V104.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V104.Id.Id Evergreen.V104.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V104.Id.Id Evergreen.V104.Id.UserId
    , name : Evergreen.V104.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V104.Message.Message Evergreen.V104.Id.ChannelMessageId)
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) (Evergreen.V104.DmChannel.LastTypedAt Evergreen.V104.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V104.OneToOne.OneToOne Evergreen.V104.DmChannel.ExternalMessageId (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelMessageId) Evergreen.V104.DmChannel.Thread
    , linkedThreadIds : Evergreen.V104.OneToOne.OneToOne Evergreen.V104.DmChannel.ExternalChannelId (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelMessageId)
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V104.Id.Id Evergreen.V104.Id.UserId
    , name : Evergreen.V104.GuildName.GuildName
    , icon : Maybe Evergreen.V104.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelId) BackendChannel
    , linkedChannelIds : Evergreen.V104.OneToOne.OneToOne Evergreen.V104.DmChannel.ExternalChannelId (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelId)
    , members :
        SeqDict.SeqDict
            (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V104.Id.Id Evergreen.V104.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V104.SecretId.SecretId Evergreen.V104.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V104.Id.Id Evergreen.V104.Id.UserId
            }
    }
