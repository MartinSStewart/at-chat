module Evergreen.V27.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V27.ChannelName
import Evergreen.V27.Discord.Id
import Evergreen.V27.DmChannel
import Evergreen.V27.FileStatus
import Evergreen.V27.GuildName
import Evergreen.V27.Id
import Evergreen.V27.Log
import Evergreen.V27.Message
import Evergreen.V27.NonemptyDict
import Evergreen.V27.OneToOne
import Evergreen.V27.SecretId
import Evergreen.V27.User
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
    , name : Evergreen.V27.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V27.Message.Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.DmChannel.LastTypedAt
    , linkedMessageIds : Evergreen.V27.OneToOne.OneToOne (Evergreen.V27.Discord.Id.Id Evergreen.V27.Discord.Id.MessageId) Int
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
    , name : Evergreen.V27.GuildName.GuildName
    , icon : Maybe Evergreen.V27.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V27.SecretId.SecretId Evergreen.V27.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
            }
    , announcementChannel : Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V27.NonemptyDict.NonemptyDict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
    , user : Evergreen.V27.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.User.FrontendUser
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.DmChannel.DmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V27.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
    , name : Evergreen.V27.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V27.Message.Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.DmChannel.LastTypedAt
    , linkedId : Maybe (Evergreen.V27.Discord.Id.Id Evergreen.V27.Discord.Id.ChannelId)
    , linkedMessageIds : Evergreen.V27.OneToOne.OneToOne (Evergreen.V27.Discord.Id.Id Evergreen.V27.Discord.Id.MessageId) Int
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
    , name : Evergreen.V27.GuildName.GuildName
    , icon : Maybe Evergreen.V27.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V27.SecretId.SecretId Evergreen.V27.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
            }
    , announcementChannel : Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId
    }
