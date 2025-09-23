module Evergreen.V97.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V97.ChannelName
import Evergreen.V97.DmChannel
import Evergreen.V97.FileStatus
import Evergreen.V97.GuildName
import Evergreen.V97.Id
import Evergreen.V97.Log
import Evergreen.V97.Message
import Evergreen.V97.NonemptyDict
import Evergreen.V97.OneToOne
import Evergreen.V97.SecretId
import Evergreen.V97.SessionIdHash
import Evergreen.V97.Slack
import Evergreen.V97.User
import Evergreen.V97.UserAgent
import Evergreen.V97.UserSession
import Evergreen.V97.VisibleMessages
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
    , name : Evergreen.V97.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V97.Message.MessageState Evergreen.V97.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V97.VisibleMessages.VisibleMessages Evergreen.V97.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) (Evergreen.V97.DmChannel.LastTypedAt Evergreen.V97.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelMessageId) Evergreen.V97.DmChannel.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
    , name : Evergreen.V97.GuildName.GuildName
    , icon : Maybe Evergreen.V97.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V97.SecretId.SecretId Evergreen.V97.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V97.NonemptyDict.NonemptyDict (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) Evergreen.V97.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V97.Slack.ClientSecret
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V97.UserSession.UserSession
    , user : Evergreen.V97.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) Evergreen.V97.User.FrontendUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V97.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) Evergreen.V97.DmChannel.FrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V97.SessionIdHash.SessionIdHash Evergreen.V97.UserSession.FrontendUserSession
    , publicVapidKey : String
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V97.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
    , name : Evergreen.V97.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V97.Message.Message Evergreen.V97.Id.ChannelMessageId)
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) (Evergreen.V97.DmChannel.LastTypedAt Evergreen.V97.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V97.OneToOne.OneToOne Evergreen.V97.DmChannel.ExternalMessageId (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelMessageId) Evergreen.V97.DmChannel.Thread
    , linkedThreadIds : Evergreen.V97.OneToOne.OneToOne Evergreen.V97.DmChannel.ExternalChannelId (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelMessageId)
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
    , name : Evergreen.V97.GuildName.GuildName
    , icon : Maybe Evergreen.V97.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelId) BackendChannel
    , linkedChannelIds : Evergreen.V97.OneToOne.OneToOne Evergreen.V97.DmChannel.ExternalChannelId (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelId)
    , members :
        SeqDict.SeqDict
            (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V97.SecretId.SecretId Evergreen.V97.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
            }
    }
