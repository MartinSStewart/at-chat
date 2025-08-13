module Evergreen.V30.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V30.ChannelName
import Evergreen.V30.Discord.Id
import Evergreen.V30.DmChannel
import Evergreen.V30.FileStatus
import Evergreen.V30.GuildName
import Evergreen.V30.Id
import Evergreen.V30.Log
import Evergreen.V30.Message
import Evergreen.V30.NonemptyDict
import Evergreen.V30.OneToOne
import Evergreen.V30.SecretId
import Evergreen.V30.User
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V30.Id.Id Evergreen.V30.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V30.Id.Id Evergreen.V30.Id.UserId
    , name : Evergreen.V30.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V30.Message.Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) Evergreen.V30.DmChannel.LastTypedAt
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V30.Id.Id Evergreen.V30.Id.UserId
    , name : Evergreen.V30.GuildName.GuildName
    , icon : Maybe Evergreen.V30.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V30.Id.Id Evergreen.V30.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V30.Id.Id Evergreen.V30.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V30.SecretId.SecretId Evergreen.V30.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V30.Id.Id Evergreen.V30.Id.UserId
            }
    , announcementChannel : Evergreen.V30.Id.Id Evergreen.V30.Id.ChannelId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V30.NonemptyDict.NonemptyDict (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) Evergreen.V30.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V30.Id.Id Evergreen.V30.Id.UserId
    , user : Evergreen.V30.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) Evergreen.V30.User.FrontendUser
    , timezone : Effect.Time.Zone
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) Evergreen.V30.DmChannel.DmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V30.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V30.Id.Id Evergreen.V30.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V30.Id.Id Evergreen.V30.Id.UserId
    , name : Evergreen.V30.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V30.Message.Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) Evergreen.V30.DmChannel.LastTypedAt
    , linkedId : Maybe (Evergreen.V30.Discord.Id.Id Evergreen.V30.Discord.Id.ChannelId)
    , linkedMessageIds : Evergreen.V30.OneToOne.OneToOne (Evergreen.V30.Discord.Id.Id Evergreen.V30.Discord.Id.MessageId) Int
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V30.Id.Id Evergreen.V30.Id.UserId
    , name : Evergreen.V30.GuildName.GuildName
    , icon : Maybe Evergreen.V30.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V30.Id.Id Evergreen.V30.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V30.Id.Id Evergreen.V30.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V30.SecretId.SecretId Evergreen.V30.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V30.Id.Id Evergreen.V30.Id.UserId
            }
    , announcementChannel : Evergreen.V30.Id.Id Evergreen.V30.Id.ChannelId
    }
