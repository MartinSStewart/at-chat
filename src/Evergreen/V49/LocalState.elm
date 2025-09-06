module Evergreen.V49.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V49.ChannelName
import Evergreen.V49.DmChannel
import Evergreen.V49.FileStatus
import Evergreen.V49.GuildName
import Evergreen.V49.Id
import Evergreen.V49.Log
import Evergreen.V49.Message
import Evergreen.V49.NonemptyDict
import Evergreen.V49.OneToOne
import Evergreen.V49.SecretId
import Evergreen.V49.Slack
import Evergreen.V49.User
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
    , name : Evergreen.V49.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V49.Message.MessageState Evergreen.V49.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V49.DmChannel.VisibleMessages Evergreen.V49.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) (Evergreen.V49.DmChannel.LastTypedAt Evergreen.V49.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelMessageId) Evergreen.V49.DmChannel.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
    , name : Evergreen.V49.GuildName.GuildName
    , icon : Maybe Evergreen.V49.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V49.SecretId.SecretId Evergreen.V49.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V49.NonemptyDict.NonemptyDict (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) Evergreen.V49.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V49.Slack.ClientSecret
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
    , user : Evergreen.V49.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) Evergreen.V49.User.FrontendUser
    , timezone : Effect.Time.Zone
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) Evergreen.V49.DmChannel.FrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , publicVapidKey : String
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V49.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
    , name : Evergreen.V49.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V49.Message.Message Evergreen.V49.Id.ChannelMessageId)
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) (Evergreen.V49.DmChannel.LastTypedAt Evergreen.V49.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V49.OneToOne.OneToOne Evergreen.V49.DmChannel.ExternalMessageId (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelMessageId) Evergreen.V49.DmChannel.Thread
    , linkedThreadIds : Evergreen.V49.OneToOne.OneToOne Evergreen.V49.DmChannel.ExternalChannelId (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelMessageId)
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
    , name : Evergreen.V49.GuildName.GuildName
    , icon : Maybe Evergreen.V49.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelId) BackendChannel
    , linkedChannelIds : Evergreen.V49.OneToOne.OneToOne Evergreen.V49.DmChannel.ExternalChannelId (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelId)
    , members :
        SeqDict.SeqDict
            (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V49.SecretId.SecretId Evergreen.V49.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
            }
    }
