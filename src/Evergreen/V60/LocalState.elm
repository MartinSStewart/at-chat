module Evergreen.V60.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V60.ChannelName
import Evergreen.V60.DmChannel
import Evergreen.V60.FileStatus
import Evergreen.V60.GuildName
import Evergreen.V60.Id
import Evergreen.V60.Log
import Evergreen.V60.Message
import Evergreen.V60.NonemptyDict
import Evergreen.V60.OneToOne
import Evergreen.V60.SecretId
import Evergreen.V60.Slack
import Evergreen.V60.User
import Evergreen.V60.VisibleMessages
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
    , name : Evergreen.V60.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V60.Message.MessageState Evergreen.V60.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V60.VisibleMessages.VisibleMessages Evergreen.V60.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) (Evergreen.V60.DmChannel.LastTypedAt Evergreen.V60.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelMessageId) Evergreen.V60.DmChannel.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
    , name : Evergreen.V60.GuildName.GuildName
    , icon : Maybe Evergreen.V60.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V60.SecretId.SecretId Evergreen.V60.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V60.NonemptyDict.NonemptyDict (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) Evergreen.V60.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V60.Slack.ClientSecret
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
    , user : Evergreen.V60.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) Evergreen.V60.User.FrontendUser
    , timezone : Effect.Time.Zone
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) Evergreen.V60.DmChannel.FrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , publicVapidKey : String
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V60.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
    , name : Evergreen.V60.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V60.Message.Message Evergreen.V60.Id.ChannelMessageId)
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) (Evergreen.V60.DmChannel.LastTypedAt Evergreen.V60.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V60.OneToOne.OneToOne Evergreen.V60.DmChannel.ExternalMessageId (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelMessageId) Evergreen.V60.DmChannel.Thread
    , linkedThreadIds : Evergreen.V60.OneToOne.OneToOne Evergreen.V60.DmChannel.ExternalChannelId (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelMessageId)
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
    , name : Evergreen.V60.GuildName.GuildName
    , icon : Maybe Evergreen.V60.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelId) BackendChannel
    , linkedChannelIds : Evergreen.V60.OneToOne.OneToOne Evergreen.V60.DmChannel.ExternalChannelId (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelId)
    , members :
        SeqDict.SeqDict
            (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V60.SecretId.SecretId Evergreen.V60.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
            }
    }
