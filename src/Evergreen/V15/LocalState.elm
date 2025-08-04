module Evergreen.V15.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V15.ChannelName
import Evergreen.V15.Discord.Id
import Evergreen.V15.DmChannel
import Evergreen.V15.GuildName
import Evergreen.V15.Id
import Evergreen.V15.Image
import Evergreen.V15.Log
import Evergreen.V15.Message
import Evergreen.V15.NonemptyDict
import Evergreen.V15.OneToOne
import Evergreen.V15.SecretId
import Evergreen.V15.User
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V15.Id.Id Evergreen.V15.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V15.Id.Id Evergreen.V15.Id.UserId
    , name : Evergreen.V15.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V15.Message.Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) Evergreen.V15.DmChannel.LastTypedAt
    , linkedMessageIds : Evergreen.V15.OneToOne.OneToOne (Evergreen.V15.Discord.Id.Id Evergreen.V15.Discord.Id.MessageId) Int
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V15.Id.Id Evergreen.V15.Id.UserId
    , name : Evergreen.V15.GuildName.GuildName
    , icon : Maybe Evergreen.V15.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V15.Id.Id Evergreen.V15.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V15.Id.Id Evergreen.V15.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V15.SecretId.SecretId Evergreen.V15.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V15.Id.Id Evergreen.V15.Id.UserId
            }
    , announcementChannel : Evergreen.V15.Id.Id Evergreen.V15.Id.ChannelId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V15.NonemptyDict.NonemptyDict (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) Evergreen.V15.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V15.Id.Id Evergreen.V15.Id.UserId
    , user : Evergreen.V15.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) Evergreen.V15.User.FrontendUser
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) Evergreen.V15.DmChannel.DmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V15.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V15.Id.Id Evergreen.V15.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V15.Id.Id Evergreen.V15.Id.UserId
    , name : Evergreen.V15.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V15.Message.Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) Evergreen.V15.DmChannel.LastTypedAt
    , linkedId : Maybe (Evergreen.V15.Discord.Id.Id Evergreen.V15.Discord.Id.ChannelId)
    , linkedMessageIds : Evergreen.V15.OneToOne.OneToOne (Evergreen.V15.Discord.Id.Id Evergreen.V15.Discord.Id.MessageId) Int
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V15.Id.Id Evergreen.V15.Id.UserId
    , name : Evergreen.V15.GuildName.GuildName
    , icon : Maybe Evergreen.V15.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V15.Id.Id Evergreen.V15.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V15.Id.Id Evergreen.V15.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V15.SecretId.SecretId Evergreen.V15.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V15.Id.Id Evergreen.V15.Id.UserId
            }
    , announcementChannel : Evergreen.V15.Id.Id Evergreen.V15.Id.ChannelId
    }
