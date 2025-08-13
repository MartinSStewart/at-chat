module Evergreen.V29.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V29.ChannelName
import Evergreen.V29.Discord.Id
import Evergreen.V29.DmChannel
import Evergreen.V29.FileStatus
import Evergreen.V29.GuildName
import Evergreen.V29.Id
import Evergreen.V29.Log
import Evergreen.V29.Message
import Evergreen.V29.NonemptyDict
import Evergreen.V29.OneToOne
import Evergreen.V29.SecretId
import Evergreen.V29.User
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    , name : Evergreen.V29.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V29.Message.Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.DmChannel.LastTypedAt
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    , name : Evergreen.V29.GuildName.GuildName
    , icon : Maybe Evergreen.V29.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V29.SecretId.SecretId Evergreen.V29.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
            }
    , announcementChannel : Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V29.NonemptyDict.NonemptyDict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    , user : Evergreen.V29.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.User.FrontendUser
    , timezone : Effect.Time.Zone
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.DmChannel.DmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V29.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    , name : Evergreen.V29.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V29.Message.Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.DmChannel.LastTypedAt
    , linkedId : Maybe (Evergreen.V29.Discord.Id.Id Evergreen.V29.Discord.Id.ChannelId)
    , linkedMessageIds : Evergreen.V29.OneToOne.OneToOne (Evergreen.V29.Discord.Id.Id Evergreen.V29.Discord.Id.MessageId) Int
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    , name : Evergreen.V29.GuildName.GuildName
    , icon : Maybe Evergreen.V29.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V29.SecretId.SecretId Evergreen.V29.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
            }
    , announcementChannel : Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId
    }
