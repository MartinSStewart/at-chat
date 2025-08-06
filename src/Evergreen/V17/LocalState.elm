module Evergreen.V17.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V17.ChannelName
import Evergreen.V17.Discord.Id
import Evergreen.V17.DmChannel
import Evergreen.V17.GuildName
import Evergreen.V17.Id
import Evergreen.V17.Image
import Evergreen.V17.Log
import Evergreen.V17.Message
import Evergreen.V17.NonemptyDict
import Evergreen.V17.OneToOne
import Evergreen.V17.SecretId
import Evergreen.V17.User
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V17.Id.Id Evergreen.V17.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V17.Id.Id Evergreen.V17.Id.UserId
    , name : Evergreen.V17.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V17.Message.Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) Evergreen.V17.DmChannel.LastTypedAt
    , linkedMessageIds : Evergreen.V17.OneToOne.OneToOne (Evergreen.V17.Discord.Id.Id Evergreen.V17.Discord.Id.MessageId) Int
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V17.Id.Id Evergreen.V17.Id.UserId
    , name : Evergreen.V17.GuildName.GuildName
    , icon : Maybe Evergreen.V17.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V17.Id.Id Evergreen.V17.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V17.Id.Id Evergreen.V17.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V17.SecretId.SecretId Evergreen.V17.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V17.Id.Id Evergreen.V17.Id.UserId
            }
    , announcementChannel : Evergreen.V17.Id.Id Evergreen.V17.Id.ChannelId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V17.NonemptyDict.NonemptyDict (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) Evergreen.V17.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V17.Id.Id Evergreen.V17.Id.UserId
    , user : Evergreen.V17.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) Evergreen.V17.User.FrontendUser
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) Evergreen.V17.DmChannel.DmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V17.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V17.Id.Id Evergreen.V17.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V17.Id.Id Evergreen.V17.Id.UserId
    , name : Evergreen.V17.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V17.Message.Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) Evergreen.V17.DmChannel.LastTypedAt
    , linkedId : Maybe (Evergreen.V17.Discord.Id.Id Evergreen.V17.Discord.Id.ChannelId)
    , linkedMessageIds : Evergreen.V17.OneToOne.OneToOne (Evergreen.V17.Discord.Id.Id Evergreen.V17.Discord.Id.MessageId) Int
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V17.Id.Id Evergreen.V17.Id.UserId
    , name : Evergreen.V17.GuildName.GuildName
    , icon : Maybe Evergreen.V17.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V17.Id.Id Evergreen.V17.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V17.Id.Id Evergreen.V17.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V17.SecretId.SecretId Evergreen.V17.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V17.Id.Id Evergreen.V17.Id.UserId
            }
    , announcementChannel : Evergreen.V17.Id.Id Evergreen.V17.Id.ChannelId
    }
