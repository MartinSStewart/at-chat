module Evergreen.V31.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V31.ChannelName
import Evergreen.V31.Discord.Id
import Evergreen.V31.DmChannel
import Evergreen.V31.FileStatus
import Evergreen.V31.GuildName
import Evergreen.V31.Id
import Evergreen.V31.Log
import Evergreen.V31.Message
import Evergreen.V31.NonemptyDict
import Evergreen.V31.OneToOne
import Evergreen.V31.SecretId
import Evergreen.V31.User
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V31.Id.Id Evergreen.V31.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V31.Id.Id Evergreen.V31.Id.UserId
    , name : Evergreen.V31.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V31.Message.Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId) Evergreen.V31.DmChannel.LastTypedAt
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V31.Id.Id Evergreen.V31.Id.UserId
    , name : Evergreen.V31.GuildName.GuildName
    , icon : Maybe Evergreen.V31.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V31.Id.Id Evergreen.V31.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V31.Id.Id Evergreen.V31.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V31.SecretId.SecretId Evergreen.V31.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V31.Id.Id Evergreen.V31.Id.UserId
            }
    , announcementChannel : Evergreen.V31.Id.Id Evergreen.V31.Id.ChannelId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V31.NonemptyDict.NonemptyDict (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId) Evergreen.V31.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V31.Id.Id Evergreen.V31.Id.UserId
    , user : Evergreen.V31.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId) Evergreen.V31.User.FrontendUser
    , timezone : Effect.Time.Zone
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId) Evergreen.V31.DmChannel.DmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V31.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V31.Id.Id Evergreen.V31.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V31.Id.Id Evergreen.V31.Id.UserId
    , name : Evergreen.V31.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V31.Message.Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId) Evergreen.V31.DmChannel.LastTypedAt
    , linkedId : Maybe (Evergreen.V31.Discord.Id.Id Evergreen.V31.Discord.Id.ChannelId)
    , linkedMessageIds : Evergreen.V31.OneToOne.OneToOne (Evergreen.V31.Discord.Id.Id Evergreen.V31.Discord.Id.MessageId) Int
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V31.Id.Id Evergreen.V31.Id.UserId
    , name : Evergreen.V31.GuildName.GuildName
    , icon : Maybe Evergreen.V31.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V31.Id.Id Evergreen.V31.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V31.Id.Id Evergreen.V31.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V31.SecretId.SecretId Evergreen.V31.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V31.Id.Id Evergreen.V31.Id.UserId
            }
    , announcementChannel : Evergreen.V31.Id.Id Evergreen.V31.Id.ChannelId
    }
