module Evergreen.V53.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V53.ChannelName
import Evergreen.V53.DmChannel
import Evergreen.V53.FileStatus
import Evergreen.V53.GuildName
import Evergreen.V53.Id
import Evergreen.V53.Log
import Evergreen.V53.Message
import Evergreen.V53.NonemptyDict
import Evergreen.V53.OneToOne
import Evergreen.V53.SecretId
import Evergreen.V53.Slack
import Evergreen.V53.User
import Evergreen.V53.VisibleMessages
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V53.Id.Id Evergreen.V53.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V53.Id.Id Evergreen.V53.Id.UserId
    , name : Evergreen.V53.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V53.Message.MessageState Evergreen.V53.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V53.VisibleMessages.VisibleMessages Evergreen.V53.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) (Evergreen.V53.DmChannel.LastTypedAt Evergreen.V53.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelMessageId) Evergreen.V53.DmChannel.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V53.Id.Id Evergreen.V53.Id.UserId
    , name : Evergreen.V53.GuildName.GuildName
    , icon : Maybe Evergreen.V53.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V53.Id.Id Evergreen.V53.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V53.SecretId.SecretId Evergreen.V53.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V53.Id.Id Evergreen.V53.Id.UserId
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V53.NonemptyDict.NonemptyDict (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) Evergreen.V53.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V53.Slack.ClientSecret
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V53.Id.Id Evergreen.V53.Id.UserId
    , user : Evergreen.V53.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) Evergreen.V53.User.FrontendUser
    , timezone : Effect.Time.Zone
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) Evergreen.V53.DmChannel.FrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , publicVapidKey : String
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V53.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V53.Id.Id Evergreen.V53.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V53.Id.Id Evergreen.V53.Id.UserId
    , name : Evergreen.V53.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V53.Message.Message Evergreen.V53.Id.ChannelMessageId)
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) (Evergreen.V53.DmChannel.LastTypedAt Evergreen.V53.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V53.OneToOne.OneToOne Evergreen.V53.DmChannel.ExternalMessageId (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelMessageId) Evergreen.V53.DmChannel.Thread
    , linkedThreadIds : Evergreen.V53.OneToOne.OneToOne Evergreen.V53.DmChannel.ExternalChannelId (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelMessageId)
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V53.Id.Id Evergreen.V53.Id.UserId
    , name : Evergreen.V53.GuildName.GuildName
    , icon : Maybe Evergreen.V53.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelId) BackendChannel
    , linkedChannelIds : Evergreen.V53.OneToOne.OneToOne Evergreen.V53.DmChannel.ExternalChannelId (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelId)
    , members :
        SeqDict.SeqDict
            (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V53.Id.Id Evergreen.V53.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V53.SecretId.SecretId Evergreen.V53.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V53.Id.Id Evergreen.V53.Id.UserId
            }
    }
