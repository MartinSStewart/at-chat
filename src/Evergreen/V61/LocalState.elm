module Evergreen.V61.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V61.ChannelName
import Evergreen.V61.DmChannel
import Evergreen.V61.FileStatus
import Evergreen.V61.GuildName
import Evergreen.V61.Id
import Evergreen.V61.Log
import Evergreen.V61.Message
import Evergreen.V61.NonemptyDict
import Evergreen.V61.OneToOne
import Evergreen.V61.SecretId
import Evergreen.V61.Slack
import Evergreen.V61.User
import Evergreen.V61.VisibleMessages
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V61.Id.Id Evergreen.V61.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V61.Id.Id Evergreen.V61.Id.UserId
    , name : Evergreen.V61.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V61.Message.MessageState Evergreen.V61.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V61.VisibleMessages.VisibleMessages Evergreen.V61.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) (Evergreen.V61.DmChannel.LastTypedAt Evergreen.V61.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelMessageId) Evergreen.V61.DmChannel.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V61.Id.Id Evergreen.V61.Id.UserId
    , name : Evergreen.V61.GuildName.GuildName
    , icon : Maybe Evergreen.V61.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V61.Id.Id Evergreen.V61.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V61.SecretId.SecretId Evergreen.V61.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V61.Id.Id Evergreen.V61.Id.UserId
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V61.NonemptyDict.NonemptyDict (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) Evergreen.V61.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V61.Slack.ClientSecret
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V61.Id.Id Evergreen.V61.Id.UserId
    , user : Evergreen.V61.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) Evergreen.V61.User.FrontendUser
    , timezone : Effect.Time.Zone
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) Evergreen.V61.DmChannel.FrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , publicVapidKey : String
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V61.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V61.Id.Id Evergreen.V61.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V61.Id.Id Evergreen.V61.Id.UserId
    , name : Evergreen.V61.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V61.Message.Message Evergreen.V61.Id.ChannelMessageId)
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) (Evergreen.V61.DmChannel.LastTypedAt Evergreen.V61.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V61.OneToOne.OneToOne Evergreen.V61.DmChannel.ExternalMessageId (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelMessageId) Evergreen.V61.DmChannel.Thread
    , linkedThreadIds : Evergreen.V61.OneToOne.OneToOne Evergreen.V61.DmChannel.ExternalChannelId (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelMessageId)
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V61.Id.Id Evergreen.V61.Id.UserId
    , name : Evergreen.V61.GuildName.GuildName
    , icon : Maybe Evergreen.V61.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelId) BackendChannel
    , linkedChannelIds : Evergreen.V61.OneToOne.OneToOne Evergreen.V61.DmChannel.ExternalChannelId (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelId)
    , members :
        SeqDict.SeqDict
            (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V61.Id.Id Evergreen.V61.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V61.SecretId.SecretId Evergreen.V61.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V61.Id.Id Evergreen.V61.Id.UserId
            }
    }
