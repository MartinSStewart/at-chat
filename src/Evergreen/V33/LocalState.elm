module Evergreen.V33.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V33.ChannelName
import Evergreen.V33.Discord.Id
import Evergreen.V33.DmChannel
import Evergreen.V33.FileStatus
import Evergreen.V33.GuildName
import Evergreen.V33.Id
import Evergreen.V33.Log
import Evergreen.V33.Message
import Evergreen.V33.NonemptyDict
import Evergreen.V33.OneToOne
import Evergreen.V33.SecretId
import Evergreen.V33.User
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
    , name : Evergreen.V33.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V33.Message.Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) Evergreen.V33.DmChannel.LastTypedAt
    , linkedMessageIds : Evergreen.V33.OneToOne.OneToOne (Evergreen.V33.Discord.Id.Id Evergreen.V33.Discord.Id.MessageId) Int
    , threads : SeqDict.SeqDict Int Evergreen.V33.DmChannel.Thread
    , linkedThreadIds : Evergreen.V33.OneToOne.OneToOne (Evergreen.V33.Discord.Id.Id Evergreen.V33.Discord.Id.ChannelId) Int
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
    , name : Evergreen.V33.GuildName.GuildName
    , icon : Maybe Evergreen.V33.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V33.Id.Id Evergreen.V33.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V33.SecretId.SecretId Evergreen.V33.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V33.NonemptyDict.NonemptyDict (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) Evergreen.V33.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
    , user : Evergreen.V33.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) Evergreen.V33.User.FrontendUser
    , timezone : Effect.Time.Zone
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) Evergreen.V33.DmChannel.DmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V33.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
    , name : Evergreen.V33.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V33.Message.Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) Evergreen.V33.DmChannel.LastTypedAt
    , linkedMessageIds : Evergreen.V33.OneToOne.OneToOne (Evergreen.V33.Discord.Id.Id Evergreen.V33.Discord.Id.MessageId) Int
    , threads : SeqDict.SeqDict Int Evergreen.V33.DmChannel.Thread
    , linkedThreadIds : Evergreen.V33.OneToOne.OneToOne (Evergreen.V33.Discord.Id.Id Evergreen.V33.Discord.Id.ChannelId) Int
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
    , name : Evergreen.V33.GuildName.GuildName
    , icon : Maybe Evergreen.V33.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V33.Id.Id Evergreen.V33.Id.ChannelId) BackendChannel
    , linkedChannelIds : Evergreen.V33.OneToOne.OneToOne (Evergreen.V33.Discord.Id.Id Evergreen.V33.Discord.Id.ChannelId) (Evergreen.V33.Id.Id Evergreen.V33.Id.ChannelId)
    , members :
        SeqDict.SeqDict
            (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V33.SecretId.SecretId Evergreen.V33.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
            }
    }
