module Evergreen.V92.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V92.ChannelName
import Evergreen.V92.DmChannel
import Evergreen.V92.FileStatus
import Evergreen.V92.GuildName
import Evergreen.V92.Id
import Evergreen.V92.Log
import Evergreen.V92.Message
import Evergreen.V92.NonemptyDict
import Evergreen.V92.OneToOne
import Evergreen.V92.SecretId
import Evergreen.V92.SessionIdHash
import Evergreen.V92.Slack
import Evergreen.V92.User
import Evergreen.V92.UserAgent
import Evergreen.V92.UserSession
import Evergreen.V92.VisibleMessages
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V92.Id.Id Evergreen.V92.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V92.Id.Id Evergreen.V92.Id.UserId
    , name : Evergreen.V92.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V92.Message.MessageState Evergreen.V92.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V92.VisibleMessages.VisibleMessages Evergreen.V92.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) (Evergreen.V92.DmChannel.LastTypedAt Evergreen.V92.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelMessageId) Evergreen.V92.DmChannel.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V92.Id.Id Evergreen.V92.Id.UserId
    , name : Evergreen.V92.GuildName.GuildName
    , icon : Maybe Evergreen.V92.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V92.Id.Id Evergreen.V92.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V92.SecretId.SecretId Evergreen.V92.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V92.Id.Id Evergreen.V92.Id.UserId
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V92.NonemptyDict.NonemptyDict (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) Evergreen.V92.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V92.Slack.ClientSecret
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V92.UserSession.UserSession
    , user : Evergreen.V92.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) Evergreen.V92.User.FrontendUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V92.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) Evergreen.V92.DmChannel.FrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V92.SessionIdHash.SessionIdHash Evergreen.V92.UserSession.FrontendUserSession
    , publicVapidKey : String
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V92.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V92.Id.Id Evergreen.V92.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V92.Id.Id Evergreen.V92.Id.UserId
    , name : Evergreen.V92.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V92.Message.Message Evergreen.V92.Id.ChannelMessageId)
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) (Evergreen.V92.DmChannel.LastTypedAt Evergreen.V92.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V92.OneToOne.OneToOne Evergreen.V92.DmChannel.ExternalMessageId (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelMessageId) Evergreen.V92.DmChannel.Thread
    , linkedThreadIds : Evergreen.V92.OneToOne.OneToOne Evergreen.V92.DmChannel.ExternalChannelId (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelMessageId)
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V92.Id.Id Evergreen.V92.Id.UserId
    , name : Evergreen.V92.GuildName.GuildName
    , icon : Maybe Evergreen.V92.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelId) BackendChannel
    , linkedChannelIds : Evergreen.V92.OneToOne.OneToOne Evergreen.V92.DmChannel.ExternalChannelId (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelId)
    , members :
        SeqDict.SeqDict
            (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V92.Id.Id Evergreen.V92.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V92.SecretId.SecretId Evergreen.V92.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V92.Id.Id Evergreen.V92.Id.UserId
            }
    }
