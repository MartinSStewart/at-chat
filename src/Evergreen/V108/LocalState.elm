module Evergreen.V108.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V108.ChannelName
import Evergreen.V108.DmChannel
import Evergreen.V108.FileStatus
import Evergreen.V108.GuildName
import Evergreen.V108.Id
import Evergreen.V108.Log
import Evergreen.V108.Message
import Evergreen.V108.NonemptyDict
import Evergreen.V108.OneToOne
import Evergreen.V108.SecretId
import Evergreen.V108.SessionIdHash
import Evergreen.V108.Slack
import Evergreen.V108.User
import Evergreen.V108.UserAgent
import Evergreen.V108.UserSession
import Evergreen.V108.VisibleMessages
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
    , name : Evergreen.V108.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V108.Message.MessageState Evergreen.V108.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V108.VisibleMessages.VisibleMessages Evergreen.V108.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) (Evergreen.V108.DmChannel.LastTypedAt Evergreen.V108.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelMessageId) Evergreen.V108.DmChannel.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
    , name : Evergreen.V108.GuildName.GuildName
    , icon : Maybe Evergreen.V108.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V108.SecretId.SecretId Evergreen.V108.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V108.NonemptyDict.NonemptyDict (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) Evergreen.V108.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V108.Slack.ClientSecret
    , openRouterKey : Maybe String
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V108.UserSession.UserSession
    , user : Evergreen.V108.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) Evergreen.V108.User.FrontendUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V108.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) Evergreen.V108.DmChannel.FrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V108.SessionIdHash.SessionIdHash Evergreen.V108.UserSession.FrontendUserSession
    , publicVapidKey : String
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V108.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
    , name : Evergreen.V108.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V108.Message.Message Evergreen.V108.Id.ChannelMessageId)
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) (Evergreen.V108.DmChannel.LastTypedAt Evergreen.V108.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V108.OneToOne.OneToOne Evergreen.V108.DmChannel.ExternalMessageId (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelMessageId) Evergreen.V108.DmChannel.Thread
    , linkedThreadIds : Evergreen.V108.OneToOne.OneToOne Evergreen.V108.DmChannel.ExternalChannelId (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelMessageId)
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
    , name : Evergreen.V108.GuildName.GuildName
    , icon : Maybe Evergreen.V108.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelId) BackendChannel
    , linkedChannelIds : Evergreen.V108.OneToOne.OneToOne Evergreen.V108.DmChannel.ExternalChannelId (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelId)
    , members :
        SeqDict.SeqDict
            (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V108.SecretId.SecretId Evergreen.V108.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
            }
    }
