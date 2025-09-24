module Evergreen.V102.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V102.ChannelName
import Evergreen.V102.DmChannel
import Evergreen.V102.FileStatus
import Evergreen.V102.GuildName
import Evergreen.V102.Id
import Evergreen.V102.Log
import Evergreen.V102.Message
import Evergreen.V102.NonemptyDict
import Evergreen.V102.OneToOne
import Evergreen.V102.SecretId
import Evergreen.V102.SessionIdHash
import Evergreen.V102.Slack
import Evergreen.V102.User
import Evergreen.V102.UserAgent
import Evergreen.V102.UserSession
import Evergreen.V102.VisibleMessages
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V102.Id.Id Evergreen.V102.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V102.Id.Id Evergreen.V102.Id.UserId
    , name : Evergreen.V102.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V102.Message.MessageState Evergreen.V102.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V102.VisibleMessages.VisibleMessages Evergreen.V102.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) (Evergreen.V102.DmChannel.LastTypedAt Evergreen.V102.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelMessageId) Evergreen.V102.DmChannel.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V102.Id.Id Evergreen.V102.Id.UserId
    , name : Evergreen.V102.GuildName.GuildName
    , icon : Maybe Evergreen.V102.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V102.Id.Id Evergreen.V102.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V102.SecretId.SecretId Evergreen.V102.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V102.Id.Id Evergreen.V102.Id.UserId
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V102.NonemptyDict.NonemptyDict (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) Evergreen.V102.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V102.Slack.ClientSecret
    , openRouterKey : Maybe String
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V102.UserSession.UserSession
    , user : Evergreen.V102.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) Evergreen.V102.User.FrontendUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V102.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) Evergreen.V102.DmChannel.FrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V102.SessionIdHash.SessionIdHash Evergreen.V102.UserSession.FrontendUserSession
    , publicVapidKey : String
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V102.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V102.Id.Id Evergreen.V102.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V102.Id.Id Evergreen.V102.Id.UserId
    , name : Evergreen.V102.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V102.Message.Message Evergreen.V102.Id.ChannelMessageId)
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) (Evergreen.V102.DmChannel.LastTypedAt Evergreen.V102.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V102.OneToOne.OneToOne Evergreen.V102.DmChannel.ExternalMessageId (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelMessageId) Evergreen.V102.DmChannel.Thread
    , linkedThreadIds : Evergreen.V102.OneToOne.OneToOne Evergreen.V102.DmChannel.ExternalChannelId (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelMessageId)
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V102.Id.Id Evergreen.V102.Id.UserId
    , name : Evergreen.V102.GuildName.GuildName
    , icon : Maybe Evergreen.V102.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelId) BackendChannel
    , linkedChannelIds : Evergreen.V102.OneToOne.OneToOne Evergreen.V102.DmChannel.ExternalChannelId (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelId)
    , members :
        SeqDict.SeqDict
            (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V102.Id.Id Evergreen.V102.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V102.SecretId.SecretId Evergreen.V102.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V102.Id.Id Evergreen.V102.Id.UserId
            }
    }
