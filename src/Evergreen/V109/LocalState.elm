module Evergreen.V109.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V109.ChannelName
import Evergreen.V109.DmChannel
import Evergreen.V109.FileStatus
import Evergreen.V109.GuildName
import Evergreen.V109.Id
import Evergreen.V109.Log
import Evergreen.V109.Message
import Evergreen.V109.NonemptyDict
import Evergreen.V109.OneToOne
import Evergreen.V109.SecretId
import Evergreen.V109.SessionIdHash
import Evergreen.V109.Slack
import Evergreen.V109.TextEditor
import Evergreen.V109.User
import Evergreen.V109.UserAgent
import Evergreen.V109.UserSession
import Evergreen.V109.VisibleMessages
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
    , name : Evergreen.V109.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V109.Message.MessageState Evergreen.V109.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V109.VisibleMessages.VisibleMessages Evergreen.V109.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) (Evergreen.V109.DmChannel.LastTypedAt Evergreen.V109.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelMessageId) Evergreen.V109.DmChannel.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
    , name : Evergreen.V109.GuildName.GuildName
    , icon : Maybe Evergreen.V109.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V109.SecretId.SecretId Evergreen.V109.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V109.NonemptyDict.NonemptyDict (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) Evergreen.V109.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V109.Slack.ClientSecret
    , openRouterKey : Maybe String
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V109.UserSession.UserSession
    , user : Evergreen.V109.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) Evergreen.V109.User.FrontendUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V109.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) Evergreen.V109.DmChannel.FrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V109.SessionIdHash.SessionIdHash Evergreen.V109.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V109.TextEditor.LocalState
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V109.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
    , name : Evergreen.V109.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V109.Message.Message Evergreen.V109.Id.ChannelMessageId)
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) (Evergreen.V109.DmChannel.LastTypedAt Evergreen.V109.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V109.OneToOne.OneToOne Evergreen.V109.DmChannel.ExternalMessageId (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelMessageId) Evergreen.V109.DmChannel.Thread
    , linkedThreadIds : Evergreen.V109.OneToOne.OneToOne Evergreen.V109.DmChannel.ExternalChannelId (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelMessageId)
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
    , name : Evergreen.V109.GuildName.GuildName
    , icon : Maybe Evergreen.V109.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelId) BackendChannel
    , linkedChannelIds : Evergreen.V109.OneToOne.OneToOne Evergreen.V109.DmChannel.ExternalChannelId (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelId)
    , members :
        SeqDict.SeqDict
            (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V109.SecretId.SecretId Evergreen.V109.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
            }
    }
