module Evergreen.V16.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V16.ChannelName
import Evergreen.V16.Discord.Id
import Evergreen.V16.DmChannel
import Evergreen.V16.GuildName
import Evergreen.V16.Id
import Evergreen.V16.Image
import Evergreen.V16.Log
import Evergreen.V16.Message
import Evergreen.V16.NonemptyDict
import Evergreen.V16.OneToOne
import Evergreen.V16.SecretId
import Evergreen.V16.User
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
    , name : Evergreen.V16.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V16.Message.Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) Evergreen.V16.DmChannel.LastTypedAt
    , linkedMessageIds : Evergreen.V16.OneToOne.OneToOne (Evergreen.V16.Discord.Id.Id Evergreen.V16.Discord.Id.MessageId) Int
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
    , name : Evergreen.V16.GuildName.GuildName
    , icon : Maybe Evergreen.V16.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V16.Id.Id Evergreen.V16.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V16.SecretId.SecretId Evergreen.V16.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
            }
    , announcementChannel : Evergreen.V16.Id.Id Evergreen.V16.Id.ChannelId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V16.NonemptyDict.NonemptyDict (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) Evergreen.V16.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
    , user : Evergreen.V16.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) Evergreen.V16.User.FrontendUser
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) Evergreen.V16.DmChannel.DmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V16.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
    , name : Evergreen.V16.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V16.Message.Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) Evergreen.V16.DmChannel.LastTypedAt
    , linkedId : Maybe (Evergreen.V16.Discord.Id.Id Evergreen.V16.Discord.Id.ChannelId)
    , linkedMessageIds : Evergreen.V16.OneToOne.OneToOne (Evergreen.V16.Discord.Id.Id Evergreen.V16.Discord.Id.MessageId) Int
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
    , name : Evergreen.V16.GuildName.GuildName
    , icon : Maybe Evergreen.V16.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V16.Id.Id Evergreen.V16.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V16.SecretId.SecretId Evergreen.V16.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
            }
    , announcementChannel : Evergreen.V16.Id.Id Evergreen.V16.Id.ChannelId
    }
