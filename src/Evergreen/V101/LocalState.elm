module Evergreen.V101.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V101.ChannelName
import Evergreen.V101.DmChannel
import Evergreen.V101.FileStatus
import Evergreen.V101.GuildName
import Evergreen.V101.Id
import Evergreen.V101.Log
import Evergreen.V101.Message
import Evergreen.V101.NonemptyDict
import Evergreen.V101.OneToOne
import Evergreen.V101.SecretId
import Evergreen.V101.SessionIdHash
import Evergreen.V101.Slack
import Evergreen.V101.User
import Evergreen.V101.UserAgent
import Evergreen.V101.UserSession
import Evergreen.V101.VisibleMessages
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V101.Id.Id Evergreen.V101.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V101.Id.Id Evergreen.V101.Id.UserId
    , name : Evergreen.V101.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V101.Message.MessageState Evergreen.V101.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V101.VisibleMessages.VisibleMessages Evergreen.V101.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) (Evergreen.V101.DmChannel.LastTypedAt Evergreen.V101.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelMessageId) Evergreen.V101.DmChannel.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V101.Id.Id Evergreen.V101.Id.UserId
    , name : Evergreen.V101.GuildName.GuildName
    , icon : Maybe Evergreen.V101.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V101.Id.Id Evergreen.V101.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V101.SecretId.SecretId Evergreen.V101.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V101.Id.Id Evergreen.V101.Id.UserId
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V101.NonemptyDict.NonemptyDict (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) Evergreen.V101.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V101.Slack.ClientSecret
    , openRouterKey : Maybe String
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V101.UserSession.UserSession
    , user : Evergreen.V101.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) Evergreen.V101.User.FrontendUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V101.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) Evergreen.V101.DmChannel.FrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V101.SessionIdHash.SessionIdHash Evergreen.V101.UserSession.FrontendUserSession
    , publicVapidKey : String
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V101.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V101.Id.Id Evergreen.V101.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V101.Id.Id Evergreen.V101.Id.UserId
    , name : Evergreen.V101.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V101.Message.Message Evergreen.V101.Id.ChannelMessageId)
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) (Evergreen.V101.DmChannel.LastTypedAt Evergreen.V101.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V101.OneToOne.OneToOne Evergreen.V101.DmChannel.ExternalMessageId (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelMessageId) Evergreen.V101.DmChannel.Thread
    , linkedThreadIds : Evergreen.V101.OneToOne.OneToOne Evergreen.V101.DmChannel.ExternalChannelId (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelMessageId)
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V101.Id.Id Evergreen.V101.Id.UserId
    , name : Evergreen.V101.GuildName.GuildName
    , icon : Maybe Evergreen.V101.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelId) BackendChannel
    , linkedChannelIds : Evergreen.V101.OneToOne.OneToOne Evergreen.V101.DmChannel.ExternalChannelId (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelId)
    , members :
        SeqDict.SeqDict
            (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V101.Id.Id Evergreen.V101.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V101.SecretId.SecretId Evergreen.V101.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V101.Id.Id Evergreen.V101.Id.UserId
            }
    }
