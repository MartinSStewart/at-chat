module Evergreen.V59.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V59.ChannelName
import Evergreen.V59.DmChannel
import Evergreen.V59.FileStatus
import Evergreen.V59.GuildName
import Evergreen.V59.Id
import Evergreen.V59.Log
import Evergreen.V59.Message
import Evergreen.V59.NonemptyDict
import Evergreen.V59.OneToOne
import Evergreen.V59.SecretId
import Evergreen.V59.Slack
import Evergreen.V59.User
import Evergreen.V59.VisibleMessages
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
    , name : Evergreen.V59.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V59.Message.MessageState Evergreen.V59.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V59.VisibleMessages.VisibleMessages Evergreen.V59.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) (Evergreen.V59.DmChannel.LastTypedAt Evergreen.V59.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelMessageId) Evergreen.V59.DmChannel.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
    , name : Evergreen.V59.GuildName.GuildName
    , icon : Maybe Evergreen.V59.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V59.SecretId.SecretId Evergreen.V59.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V59.NonemptyDict.NonemptyDict (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) Evergreen.V59.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V59.Slack.ClientSecret
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
    , user : Evergreen.V59.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) Evergreen.V59.User.FrontendUser
    , timezone : Effect.Time.Zone
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) Evergreen.V59.DmChannel.FrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , publicVapidKey : String
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V59.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
    , name : Evergreen.V59.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V59.Message.Message Evergreen.V59.Id.ChannelMessageId)
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) (Evergreen.V59.DmChannel.LastTypedAt Evergreen.V59.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V59.OneToOne.OneToOne Evergreen.V59.DmChannel.ExternalMessageId (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelMessageId) Evergreen.V59.DmChannel.Thread
    , linkedThreadIds : Evergreen.V59.OneToOne.OneToOne Evergreen.V59.DmChannel.ExternalChannelId (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelMessageId)
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
    , name : Evergreen.V59.GuildName.GuildName
    , icon : Maybe Evergreen.V59.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelId) BackendChannel
    , linkedChannelIds : Evergreen.V59.OneToOne.OneToOne Evergreen.V59.DmChannel.ExternalChannelId (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelId)
    , members :
        SeqDict.SeqDict
            (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V59.SecretId.SecretId Evergreen.V59.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
            }
    }
