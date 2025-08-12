module Evergreen.V23.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V23.ChannelName
import Evergreen.V23.Discord.Id
import Evergreen.V23.DmChannel
import Evergreen.V23.GuildName
import Evergreen.V23.Id
import Evergreen.V23.Image
import Evergreen.V23.Log
import Evergreen.V23.Message
import Evergreen.V23.NonemptyDict
import Evergreen.V23.OneToOne
import Evergreen.V23.SecretId
import Evergreen.V23.User
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V23.Id.Id Evergreen.V23.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V23.Id.Id Evergreen.V23.Id.UserId
    , name : Evergreen.V23.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V23.Message.Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) Evergreen.V23.DmChannel.LastTypedAt
    , linkedMessageIds : Evergreen.V23.OneToOne.OneToOne (Evergreen.V23.Discord.Id.Id Evergreen.V23.Discord.Id.MessageId) Int
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V23.Id.Id Evergreen.V23.Id.UserId
    , name : Evergreen.V23.GuildName.GuildName
    , icon : Maybe Evergreen.V23.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V23.Id.Id Evergreen.V23.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V23.Id.Id Evergreen.V23.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V23.SecretId.SecretId Evergreen.V23.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V23.Id.Id Evergreen.V23.Id.UserId
            }
    , announcementChannel : Evergreen.V23.Id.Id Evergreen.V23.Id.ChannelId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V23.NonemptyDict.NonemptyDict (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) Evergreen.V23.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V23.Id.Id Evergreen.V23.Id.UserId
    , user : Evergreen.V23.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) Evergreen.V23.User.FrontendUser
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) Evergreen.V23.DmChannel.DmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V23.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V23.Id.Id Evergreen.V23.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V23.Id.Id Evergreen.V23.Id.UserId
    , name : Evergreen.V23.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V23.Message.Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) Evergreen.V23.DmChannel.LastTypedAt
    , linkedId : Maybe (Evergreen.V23.Discord.Id.Id Evergreen.V23.Discord.Id.ChannelId)
    , linkedMessageIds : Evergreen.V23.OneToOne.OneToOne (Evergreen.V23.Discord.Id.Id Evergreen.V23.Discord.Id.MessageId) Int
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V23.Id.Id Evergreen.V23.Id.UserId
    , name : Evergreen.V23.GuildName.GuildName
    , icon : Maybe Evergreen.V23.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V23.Id.Id Evergreen.V23.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V23.Id.Id Evergreen.V23.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V23.SecretId.SecretId Evergreen.V23.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V23.Id.Id Evergreen.V23.Id.UserId
            }
    , announcementChannel : Evergreen.V23.Id.Id Evergreen.V23.Id.ChannelId
    }
