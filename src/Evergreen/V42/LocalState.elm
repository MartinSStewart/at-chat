module Evergreen.V42.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V42.ChannelName
import Evergreen.V42.Discord.Id
import Evergreen.V42.DmChannel
import Evergreen.V42.FileStatus
import Evergreen.V42.GuildName
import Evergreen.V42.Id
import Evergreen.V42.Log
import Evergreen.V42.Message
import Evergreen.V42.NonemptyDict
import Evergreen.V42.OneToOne
import Evergreen.V42.SecretId
import Evergreen.V42.User
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V42.Id.Id Evergreen.V42.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V42.Id.Id Evergreen.V42.Id.UserId
    , name : Evergreen.V42.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V42.Message.Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) (Evergreen.V42.DmChannel.LastTypedAt Evergreen.V42.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V42.OneToOne.OneToOne (Evergreen.V42.Discord.Id.Id Evergreen.V42.Discord.Id.MessageId) (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId) Evergreen.V42.DmChannel.Thread
    , linkedThreadIds : Evergreen.V42.OneToOne.OneToOne (Evergreen.V42.Discord.Id.Id Evergreen.V42.Discord.Id.ChannelId) (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId)
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V42.Id.Id Evergreen.V42.Id.UserId
    , name : Evergreen.V42.GuildName.GuildName
    , icon : Maybe Evergreen.V42.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V42.Id.Id Evergreen.V42.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V42.SecretId.SecretId Evergreen.V42.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V42.Id.Id Evergreen.V42.Id.UserId
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V42.NonemptyDict.NonemptyDict (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) Evergreen.V42.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    , privateVapidKey : PrivateVapidKey
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V42.Id.Id Evergreen.V42.Id.UserId
    , user : Evergreen.V42.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) Evergreen.V42.User.FrontendUser
    , timezone : Effect.Time.Zone
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) Evergreen.V42.DmChannel.DmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , publicVapidKey : String
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V42.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V42.Id.Id Evergreen.V42.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V42.Id.Id Evergreen.V42.Id.UserId
    , name : Evergreen.V42.ChannelName.ChannelName
    , messages : Array.Array Evergreen.V42.Message.Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) (Evergreen.V42.DmChannel.LastTypedAt Evergreen.V42.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V42.OneToOne.OneToOne (Evergreen.V42.Discord.Id.Id Evergreen.V42.Discord.Id.MessageId) (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId) Evergreen.V42.DmChannel.Thread
    , linkedThreadIds : Evergreen.V42.OneToOne.OneToOne (Evergreen.V42.Discord.Id.Id Evergreen.V42.Discord.Id.ChannelId) (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId)
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V42.Id.Id Evergreen.V42.Id.UserId
    , name : Evergreen.V42.GuildName.GuildName
    , icon : Maybe Evergreen.V42.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelId) BackendChannel
    , linkedChannelIds : Evergreen.V42.OneToOne.OneToOne (Evergreen.V42.Discord.Id.Id Evergreen.V42.Discord.Id.ChannelId) (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelId)
    , members :
        SeqDict.SeqDict
            (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V42.Id.Id Evergreen.V42.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V42.SecretId.SecretId Evergreen.V42.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V42.Id.Id Evergreen.V42.Id.UserId
            }
    }
