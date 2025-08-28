module Evergreen.V38.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V38.ChannelName
import Evergreen.V38.Discord.Id
import Evergreen.V38.DmChannel
import Evergreen.V38.FileStatus
import Evergreen.V38.GuildName
import Evergreen.V38.Id
import Evergreen.V38.Log
import Evergreen.V38.Message
import Evergreen.V38.NonemptyDict
import Evergreen.V38.OneToOne
import Evergreen.V38.SecretId
import Evergreen.V38.User
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V38.Id.Id Evergreen.V38.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V38.Id.Id Evergreen.V38.Id.UserId
    , name : Evergreen.V38.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V38.Message.Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) (Evergreen.V38.DmChannel.LastTypedAt Evergreen.V38.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V38.OneToOne.OneToOne (Evergreen.V38.Discord.Id.Id Evergreen.V38.Discord.Id.MessageId) (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId) Evergreen.V38.DmChannel.Thread
    , linkedThreadIds : Evergreen.V38.OneToOne.OneToOne (Evergreen.V38.Discord.Id.Id Evergreen.V38.Discord.Id.ChannelId) (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId)
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V38.Id.Id Evergreen.V38.Id.UserId
    , name : Evergreen.V38.GuildName.GuildName
    , icon : Maybe Evergreen.V38.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V38.Id.Id Evergreen.V38.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V38.SecretId.SecretId Evergreen.V38.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V38.Id.Id Evergreen.V38.Id.UserId
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V38.NonemptyDict.NonemptyDict (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) Evergreen.V38.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    , privateVapidKey : String
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V38.Id.Id Evergreen.V38.Id.UserId
    , user : Evergreen.V38.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) Evergreen.V38.User.FrontendUser
    , timezone : Effect.Time.Zone
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) Evergreen.V38.DmChannel.DmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , publicVapidKey : String
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V38.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V38.Id.Id Evergreen.V38.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V38.Id.Id Evergreen.V38.Id.UserId
    , name : Evergreen.V38.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V38.Message.Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) (Evergreen.V38.DmChannel.LastTypedAt Evergreen.V38.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V38.OneToOne.OneToOne (Evergreen.V38.Discord.Id.Id Evergreen.V38.Discord.Id.MessageId) (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId) Evergreen.V38.DmChannel.Thread
    , linkedThreadIds : Evergreen.V38.OneToOne.OneToOne (Evergreen.V38.Discord.Id.Id Evergreen.V38.Discord.Id.ChannelId) (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId)
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V38.Id.Id Evergreen.V38.Id.UserId
    , name : Evergreen.V38.GuildName.GuildName
    , icon : Maybe Evergreen.V38.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelId) BackendChannel
    , linkedChannelIds : Evergreen.V38.OneToOne.OneToOne (Evergreen.V38.Discord.Id.Id Evergreen.V38.Discord.Id.ChannelId) (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelId)
    , members :
        SeqDict.SeqDict
            (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V38.Id.Id Evergreen.V38.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V38.SecretId.SecretId Evergreen.V38.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V38.Id.Id Evergreen.V38.Id.UserId
            }
    }
