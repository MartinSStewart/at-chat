module Evergreen.V54.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V54.ChannelName
import Evergreen.V54.DmChannel
import Evergreen.V54.FileStatus
import Evergreen.V54.GuildName
import Evergreen.V54.Id
import Evergreen.V54.Log
import Evergreen.V54.Message
import Evergreen.V54.NonemptyDict
import Evergreen.V54.OneToOne
import Evergreen.V54.SecretId
import Evergreen.V54.Slack
import Evergreen.V54.User
import Evergreen.V54.VisibleMessages
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
    , name : Evergreen.V54.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V54.Message.MessageState Evergreen.V54.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V54.VisibleMessages.VisibleMessages Evergreen.V54.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) (Evergreen.V54.DmChannel.LastTypedAt Evergreen.V54.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelMessageId) Evergreen.V54.DmChannel.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
    , name : Evergreen.V54.GuildName.GuildName
    , icon : Maybe Evergreen.V54.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V54.SecretId.SecretId Evergreen.V54.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V54.NonemptyDict.NonemptyDict (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) Evergreen.V54.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V54.Slack.ClientSecret
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
    , user : Evergreen.V54.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) Evergreen.V54.User.FrontendUser
    , timezone : Effect.Time.Zone
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) Evergreen.V54.DmChannel.FrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , publicVapidKey : String
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V54.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
    , name : Evergreen.V54.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V54.Message.Message Evergreen.V54.Id.ChannelMessageId)
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) (Evergreen.V54.DmChannel.LastTypedAt Evergreen.V54.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V54.OneToOne.OneToOne Evergreen.V54.DmChannel.ExternalMessageId (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelMessageId) Evergreen.V54.DmChannel.Thread
    , linkedThreadIds : Evergreen.V54.OneToOne.OneToOne Evergreen.V54.DmChannel.ExternalChannelId (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelMessageId)
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
    , name : Evergreen.V54.GuildName.GuildName
    , icon : Maybe Evergreen.V54.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelId) BackendChannel
    , linkedChannelIds : Evergreen.V54.OneToOne.OneToOne Evergreen.V54.DmChannel.ExternalChannelId (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelId)
    , members :
        SeqDict.SeqDict
            (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V54.SecretId.SecretId Evergreen.V54.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
            }
    }
