module Evergreen.V45.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V45.ChannelName
import Evergreen.V45.Discord.Id
import Evergreen.V45.DmChannel
import Evergreen.V45.FileStatus
import Evergreen.V45.GuildName
import Evergreen.V45.Id
import Evergreen.V45.Log
import Evergreen.V45.Message
import Evergreen.V45.NonemptyDict
import Evergreen.V45.OneToOne
import Evergreen.V45.SecretId
import Evergreen.V45.User
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V45.Id.Id Evergreen.V45.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V45.Id.Id Evergreen.V45.Id.UserId
    , name : Evergreen.V45.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V45.Message.Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) (Evergreen.V45.DmChannel.LastTypedAt Evergreen.V45.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V45.OneToOne.OneToOne (Evergreen.V45.Discord.Id.Id Evergreen.V45.Discord.Id.MessageId) (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId) Evergreen.V45.DmChannel.Thread
    , linkedThreadIds : Evergreen.V45.OneToOne.OneToOne (Evergreen.V45.Discord.Id.Id Evergreen.V45.Discord.Id.ChannelId) (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId)
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V45.Id.Id Evergreen.V45.Id.UserId
    , name : Evergreen.V45.GuildName.GuildName
    , icon : Maybe Evergreen.V45.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V45.Id.Id Evergreen.V45.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V45.SecretId.SecretId Evergreen.V45.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V45.Id.Id Evergreen.V45.Id.UserId
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V45.NonemptyDict.NonemptyDict (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) Evergreen.V45.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    , privateVapidKey : PrivateVapidKey
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V45.Id.Id Evergreen.V45.Id.UserId
    , user : Evergreen.V45.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) Evergreen.V45.User.FrontendUser
    , timezone : Effect.Time.Zone
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) Evergreen.V45.DmChannel.DmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , publicVapidKey : String
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V45.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V45.Id.Id Evergreen.V45.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V45.Id.Id Evergreen.V45.Id.UserId
    , name : Evergreen.V45.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V45.Message.Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) (Evergreen.V45.DmChannel.LastTypedAt Evergreen.V45.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V45.OneToOne.OneToOne (Evergreen.V45.Discord.Id.Id Evergreen.V45.Discord.Id.MessageId) (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId) Evergreen.V45.DmChannel.Thread
    , linkedThreadIds : Evergreen.V45.OneToOne.OneToOne (Evergreen.V45.Discord.Id.Id Evergreen.V45.Discord.Id.ChannelId) (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId)
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V45.Id.Id Evergreen.V45.Id.UserId
    , name : Evergreen.V45.GuildName.GuildName
    , icon : Maybe Evergreen.V45.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelId) BackendChannel
    , linkedChannelIds : Evergreen.V45.OneToOne.OneToOne (Evergreen.V45.Discord.Id.Id Evergreen.V45.Discord.Id.ChannelId) (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelId)
    , members :
        SeqDict.SeqDict
            (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V45.Id.Id Evergreen.V45.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V45.SecretId.SecretId Evergreen.V45.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V45.Id.Id Evergreen.V45.Id.UserId
            }
    }
