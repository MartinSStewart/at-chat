module Evergreen.V46.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V46.ChannelName
import Evergreen.V46.Discord.Id
import Evergreen.V46.DmChannel
import Evergreen.V46.FileStatus
import Evergreen.V46.GuildName
import Evergreen.V46.Id
import Evergreen.V46.Log
import Evergreen.V46.Message
import Evergreen.V46.NonemptyDict
import Evergreen.V46.OneToOne
import Evergreen.V46.SecretId
import Evergreen.V46.User
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
    , name : Evergreen.V46.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V46.Message.Message Evergreen.V46.Id.ChannelMessageId)
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) (Evergreen.V46.DmChannel.LastTypedAt Evergreen.V46.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V46.OneToOne.OneToOne (Evergreen.V46.Discord.Id.Id Evergreen.V46.Discord.Id.MessageId) (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelMessageId) Evergreen.V46.DmChannel.Thread
    , linkedThreadIds : Evergreen.V46.OneToOne.OneToOne (Evergreen.V46.Discord.Id.Id Evergreen.V46.Discord.Id.ChannelId) (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelMessageId)
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
    , name : Evergreen.V46.GuildName.GuildName
    , icon : Maybe Evergreen.V46.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V46.SecretId.SecretId Evergreen.V46.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V46.NonemptyDict.NonemptyDict (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) Evergreen.V46.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    , privateVapidKey : PrivateVapidKey
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
    , user : Evergreen.V46.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) Evergreen.V46.User.FrontendUser
    , timezone : Effect.Time.Zone
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) Evergreen.V46.DmChannel.DmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , publicVapidKey : String
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V46.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
    , name : Evergreen.V46.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V46.Message.Message Evergreen.V46.Id.ChannelMessageId)
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) (Evergreen.V46.DmChannel.LastTypedAt Evergreen.V46.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V46.OneToOne.OneToOne (Evergreen.V46.Discord.Id.Id Evergreen.V46.Discord.Id.MessageId) (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelMessageId) Evergreen.V46.DmChannel.Thread
    , linkedThreadIds : Evergreen.V46.OneToOne.OneToOne (Evergreen.V46.Discord.Id.Id Evergreen.V46.Discord.Id.ChannelId) (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelMessageId)
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
    , name : Evergreen.V46.GuildName.GuildName
    , icon : Maybe Evergreen.V46.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelId) BackendChannel
    , linkedChannelIds : Evergreen.V46.OneToOne.OneToOne (Evergreen.V46.Discord.Id.Id Evergreen.V46.Discord.Id.ChannelId) (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelId)
    , members :
        SeqDict.SeqDict
            (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V46.SecretId.SecretId Evergreen.V46.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
            }
    }
