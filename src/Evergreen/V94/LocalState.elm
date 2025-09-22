module Evergreen.V94.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V94.ChannelName
import Evergreen.V94.DmChannel
import Evergreen.V94.FileStatus
import Evergreen.V94.GuildName
import Evergreen.V94.Id
import Evergreen.V94.Log
import Evergreen.V94.Message
import Evergreen.V94.NonemptyDict
import Evergreen.V94.OneToOne
import Evergreen.V94.SecretId
import Evergreen.V94.SessionIdHash
import Evergreen.V94.Slack
import Evergreen.V94.User
import Evergreen.V94.UserAgent
import Evergreen.V94.UserSession
import Evergreen.V94.VisibleMessages
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V94.Id.Id Evergreen.V94.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V94.Id.Id Evergreen.V94.Id.UserId
    , name : Evergreen.V94.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V94.Message.MessageState Evergreen.V94.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V94.VisibleMessages.VisibleMessages Evergreen.V94.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) (Evergreen.V94.DmChannel.LastTypedAt Evergreen.V94.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelMessageId) Evergreen.V94.DmChannel.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V94.Id.Id Evergreen.V94.Id.UserId
    , name : Evergreen.V94.GuildName.GuildName
    , icon : Maybe Evergreen.V94.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V94.Id.Id Evergreen.V94.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V94.SecretId.SecretId Evergreen.V94.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V94.Id.Id Evergreen.V94.Id.UserId
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V94.NonemptyDict.NonemptyDict (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) Evergreen.V94.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V94.Slack.ClientSecret
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V94.UserSession.UserSession
    , user : Evergreen.V94.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) Evergreen.V94.User.FrontendUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V94.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) Evergreen.V94.DmChannel.FrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V94.SessionIdHash.SessionIdHash Evergreen.V94.UserSession.FrontendUserSession
    , publicVapidKey : String
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V94.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V94.Id.Id Evergreen.V94.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V94.Id.Id Evergreen.V94.Id.UserId
    , name : Evergreen.V94.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V94.Message.Message Evergreen.V94.Id.ChannelMessageId)
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) (Evergreen.V94.DmChannel.LastTypedAt Evergreen.V94.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V94.OneToOne.OneToOne Evergreen.V94.DmChannel.ExternalMessageId (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelMessageId) Evergreen.V94.DmChannel.Thread
    , linkedThreadIds : Evergreen.V94.OneToOne.OneToOne Evergreen.V94.DmChannel.ExternalChannelId (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelMessageId)
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V94.Id.Id Evergreen.V94.Id.UserId
    , name : Evergreen.V94.GuildName.GuildName
    , icon : Maybe Evergreen.V94.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelId) BackendChannel
    , linkedChannelIds : Evergreen.V94.OneToOne.OneToOne Evergreen.V94.DmChannel.ExternalChannelId (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelId)
    , members :
        SeqDict.SeqDict
            (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V94.Id.Id Evergreen.V94.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V94.SecretId.SecretId Evergreen.V94.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V94.Id.Id Evergreen.V94.Id.UserId
            }
    }
