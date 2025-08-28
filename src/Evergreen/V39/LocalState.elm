module Evergreen.V39.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V39.ChannelName
import Evergreen.V39.Discord.Id
import Evergreen.V39.DmChannel
import Evergreen.V39.FileStatus
import Evergreen.V39.GuildName
import Evergreen.V39.Id
import Evergreen.V39.Log
import Evergreen.V39.Message
import Evergreen.V39.NonemptyDict
import Evergreen.V39.OneToOne
import Evergreen.V39.SecretId
import Evergreen.V39.User
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V39.Id.Id Evergreen.V39.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V39.Id.Id Evergreen.V39.Id.UserId
    , name : Evergreen.V39.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V39.Message.Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) (Evergreen.V39.DmChannel.LastTypedAt Evergreen.V39.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V39.OneToOne.OneToOne (Evergreen.V39.Discord.Id.Id Evergreen.V39.Discord.Id.MessageId) (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId) Evergreen.V39.DmChannel.Thread
    , linkedThreadIds : Evergreen.V39.OneToOne.OneToOne (Evergreen.V39.Discord.Id.Id Evergreen.V39.Discord.Id.ChannelId) (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId)
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V39.Id.Id Evergreen.V39.Id.UserId
    , name : Evergreen.V39.GuildName.GuildName
    , icon : Maybe Evergreen.V39.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V39.Id.Id Evergreen.V39.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V39.SecretId.SecretId Evergreen.V39.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V39.Id.Id Evergreen.V39.Id.UserId
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V39.NonemptyDict.NonemptyDict (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) Evergreen.V39.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    , privateVapidKey : PrivateVapidKey
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V39.Id.Id Evergreen.V39.Id.UserId
    , user : Evergreen.V39.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) Evergreen.V39.User.FrontendUser
    , timezone : Effect.Time.Zone
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) Evergreen.V39.DmChannel.DmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , publicVapidKey : String
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V39.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V39.Id.Id Evergreen.V39.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V39.Id.Id Evergreen.V39.Id.UserId
    , name : Evergreen.V39.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V39.Message.Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) (Evergreen.V39.DmChannel.LastTypedAt Evergreen.V39.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V39.OneToOne.OneToOne (Evergreen.V39.Discord.Id.Id Evergreen.V39.Discord.Id.MessageId) (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId) Evergreen.V39.DmChannel.Thread
    , linkedThreadIds : Evergreen.V39.OneToOne.OneToOne (Evergreen.V39.Discord.Id.Id Evergreen.V39.Discord.Id.ChannelId) (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId)
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V39.Id.Id Evergreen.V39.Id.UserId
    , name : Evergreen.V39.GuildName.GuildName
    , icon : Maybe Evergreen.V39.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelId) BackendChannel
    , linkedChannelIds : Evergreen.V39.OneToOne.OneToOne (Evergreen.V39.Discord.Id.Id Evergreen.V39.Discord.Id.ChannelId) (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelId)
    , members :
        SeqDict.SeqDict
            (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V39.Id.Id Evergreen.V39.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V39.SecretId.SecretId Evergreen.V39.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V39.Id.Id Evergreen.V39.Id.UserId
            }
    }
