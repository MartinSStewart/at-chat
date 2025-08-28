module Evergreen.V41.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V41.ChannelName
import Evergreen.V41.Discord.Id
import Evergreen.V41.DmChannel
import Evergreen.V41.FileStatus
import Evergreen.V41.GuildName
import Evergreen.V41.Id
import Evergreen.V41.Log
import Evergreen.V41.Message
import Evergreen.V41.NonemptyDict
import Evergreen.V41.OneToOne
import Evergreen.V41.SecretId
import Evergreen.V41.User
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V41.Id.Id Evergreen.V41.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V41.Id.Id Evergreen.V41.Id.UserId
    , name : Evergreen.V41.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V41.Message.Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) (Evergreen.V41.DmChannel.LastTypedAt Evergreen.V41.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V41.OneToOne.OneToOne (Evergreen.V41.Discord.Id.Id Evergreen.V41.Discord.Id.MessageId) (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId) Evergreen.V41.DmChannel.Thread
    , linkedThreadIds : Evergreen.V41.OneToOne.OneToOne (Evergreen.V41.Discord.Id.Id Evergreen.V41.Discord.Id.ChannelId) (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId)
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V41.Id.Id Evergreen.V41.Id.UserId
    , name : Evergreen.V41.GuildName.GuildName
    , icon : Maybe Evergreen.V41.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V41.Id.Id Evergreen.V41.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V41.SecretId.SecretId Evergreen.V41.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V41.Id.Id Evergreen.V41.Id.UserId
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V41.NonemptyDict.NonemptyDict (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) Evergreen.V41.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    , privateVapidKey : PrivateVapidKey
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V41.Id.Id Evergreen.V41.Id.UserId
    , user : Evergreen.V41.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) Evergreen.V41.User.FrontendUser
    , timezone : Effect.Time.Zone
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) Evergreen.V41.DmChannel.DmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , publicVapidKey : String
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V41.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V41.Id.Id Evergreen.V41.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V41.Id.Id Evergreen.V41.Id.UserId
    , name : Evergreen.V41.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V41.Message.Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) (Evergreen.V41.DmChannel.LastTypedAt Evergreen.V41.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V41.OneToOne.OneToOne (Evergreen.V41.Discord.Id.Id Evergreen.V41.Discord.Id.MessageId) (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId) Evergreen.V41.DmChannel.Thread
    , linkedThreadIds : Evergreen.V41.OneToOne.OneToOne (Evergreen.V41.Discord.Id.Id Evergreen.V41.Discord.Id.ChannelId) (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId)
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V41.Id.Id Evergreen.V41.Id.UserId
    , name : Evergreen.V41.GuildName.GuildName
    , icon : Maybe Evergreen.V41.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelId) BackendChannel
    , linkedChannelIds : Evergreen.V41.OneToOne.OneToOne (Evergreen.V41.Discord.Id.Id Evergreen.V41.Discord.Id.ChannelId) (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelId)
    , members :
        SeqDict.SeqDict
            (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V41.Id.Id Evergreen.V41.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V41.SecretId.SecretId Evergreen.V41.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V41.Id.Id Evergreen.V41.Id.UserId
            }
    }
