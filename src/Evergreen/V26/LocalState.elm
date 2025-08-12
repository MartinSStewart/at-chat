module Evergreen.V26.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V26.ChannelName
import Evergreen.V26.Discord.Id
import Evergreen.V26.DmChannel
import Evergreen.V26.FileStatus
import Evergreen.V26.GuildName
import Evergreen.V26.Id
import Evergreen.V26.Log
import Evergreen.V26.Message
import Evergreen.V26.NonemptyDict
import Evergreen.V26.OneToOne
import Evergreen.V26.SecretId
import Evergreen.V26.User
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
    , name : Evergreen.V26.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V26.Message.Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) Evergreen.V26.DmChannel.LastTypedAt
    , linkedMessageIds : Evergreen.V26.OneToOne.OneToOne (Evergreen.V26.Discord.Id.Id Evergreen.V26.Discord.Id.MessageId) Int
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
    , name : Evergreen.V26.GuildName.GuildName
    , icon : Maybe Evergreen.V26.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V26.Id.Id Evergreen.V26.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V26.SecretId.SecretId Evergreen.V26.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
            }
    , announcementChannel : Evergreen.V26.Id.Id Evergreen.V26.Id.ChannelId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V26.NonemptyDict.NonemptyDict (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) Evergreen.V26.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
    , user : Evergreen.V26.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) Evergreen.V26.User.FrontendUser
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) Evergreen.V26.DmChannel.DmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V26.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
    , name : Evergreen.V26.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V26.Message.Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) Evergreen.V26.DmChannel.LastTypedAt
    , linkedId : Maybe (Evergreen.V26.Discord.Id.Id Evergreen.V26.Discord.Id.ChannelId)
    , linkedMessageIds : Evergreen.V26.OneToOne.OneToOne (Evergreen.V26.Discord.Id.Id Evergreen.V26.Discord.Id.MessageId) Int
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
    , name : Evergreen.V26.GuildName.GuildName
    , icon : Maybe Evergreen.V26.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V26.Id.Id Evergreen.V26.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V26.SecretId.SecretId Evergreen.V26.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
            }
    , announcementChannel : Evergreen.V26.Id.Id Evergreen.V26.Id.ChannelId
    }
