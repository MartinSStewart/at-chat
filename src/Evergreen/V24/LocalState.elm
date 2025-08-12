module Evergreen.V24.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V24.ChannelName
import Evergreen.V24.Discord.Id
import Evergreen.V24.DmChannel
import Evergreen.V24.FileStatus
import Evergreen.V24.GuildName
import Evergreen.V24.Id
import Evergreen.V24.Log
import Evergreen.V24.Message
import Evergreen.V24.NonemptyDict
import Evergreen.V24.OneToOne
import Evergreen.V24.SecretId
import Evergreen.V24.User
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
    , name : Evergreen.V24.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V24.Message.Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) Evergreen.V24.DmChannel.LastTypedAt
    , linkedMessageIds : Evergreen.V24.OneToOne.OneToOne (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.MessageId) Int
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
    , name : Evergreen.V24.GuildName.GuildName
    , icon : Maybe Evergreen.V24.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V24.SecretId.SecretId Evergreen.V24.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
            }
    , announcementChannel : Evergreen.V24.Id.Id Evergreen.V24.Id.ChannelId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V24.NonemptyDict.NonemptyDict (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) Evergreen.V24.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
    , user : Evergreen.V24.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) Evergreen.V24.User.FrontendUser
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) Evergreen.V24.DmChannel.DmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V24.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
    , name : Evergreen.V24.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V24.Message.Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) Evergreen.V24.DmChannel.LastTypedAt
    , linkedId : Maybe (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.ChannelId)
    , linkedMessageIds : Evergreen.V24.OneToOne.OneToOne (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.MessageId) Int
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
    , name : Evergreen.V24.GuildName.GuildName
    , icon : Maybe Evergreen.V24.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V24.SecretId.SecretId Evergreen.V24.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
            }
    , announcementChannel : Evergreen.V24.Id.Id Evergreen.V24.Id.ChannelId
    }
