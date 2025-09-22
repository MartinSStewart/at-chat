module Evergreen.V93.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V93.ChannelName
import Evergreen.V93.DmChannel
import Evergreen.V93.FileStatus
import Evergreen.V93.GuildName
import Evergreen.V93.Id
import Evergreen.V93.Log
import Evergreen.V93.Message
import Evergreen.V93.NonemptyDict
import Evergreen.V93.OneToOne
import Evergreen.V93.SecretId
import Evergreen.V93.SessionIdHash
import Evergreen.V93.Slack
import Evergreen.V93.User
import Evergreen.V93.UserAgent
import Evergreen.V93.UserSession
import Evergreen.V93.VisibleMessages
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
    , name : Evergreen.V93.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V93.Message.MessageState Evergreen.V93.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V93.VisibleMessages.VisibleMessages Evergreen.V93.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) (Evergreen.V93.DmChannel.LastTypedAt Evergreen.V93.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelMessageId) Evergreen.V93.DmChannel.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
    , name : Evergreen.V93.GuildName.GuildName
    , icon : Maybe Evergreen.V93.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V93.SecretId.SecretId Evergreen.V93.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V93.NonemptyDict.NonemptyDict (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) Evergreen.V93.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V93.Slack.ClientSecret
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V93.UserSession.UserSession
    , user : Evergreen.V93.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) Evergreen.V93.User.FrontendUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V93.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) Evergreen.V93.DmChannel.FrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V93.SessionIdHash.SessionIdHash Evergreen.V93.UserSession.FrontendUserSession
    , publicVapidKey : String
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V93.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
    , name : Evergreen.V93.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V93.Message.Message Evergreen.V93.Id.ChannelMessageId)
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) (Evergreen.V93.DmChannel.LastTypedAt Evergreen.V93.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V93.OneToOne.OneToOne Evergreen.V93.DmChannel.ExternalMessageId (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelMessageId) Evergreen.V93.DmChannel.Thread
    , linkedThreadIds : Evergreen.V93.OneToOne.OneToOne Evergreen.V93.DmChannel.ExternalChannelId (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelMessageId)
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
    , name : Evergreen.V93.GuildName.GuildName
    , icon : Maybe Evergreen.V93.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelId) BackendChannel
    , linkedChannelIds : Evergreen.V93.OneToOne.OneToOne Evergreen.V93.DmChannel.ExternalChannelId (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelId)
    , members :
        SeqDict.SeqDict
            (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V93.SecretId.SecretId Evergreen.V93.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
            }
    }
