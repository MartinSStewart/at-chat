module Evergreen.V52.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V52.ChannelName
import Evergreen.V52.DmChannel
import Evergreen.V52.FileStatus
import Evergreen.V52.GuildName
import Evergreen.V52.Id
import Evergreen.V52.Log
import Evergreen.V52.Message
import Evergreen.V52.NonemptyDict
import Evergreen.V52.OneToOne
import Evergreen.V52.SecretId
import Evergreen.V52.Slack
import Evergreen.V52.User
import Evergreen.V52.VisibleMessages
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
    , name : Evergreen.V52.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V52.Message.MessageState Evergreen.V52.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V52.VisibleMessages.VisibleMessages Evergreen.V52.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) (Evergreen.V52.DmChannel.LastTypedAt Evergreen.V52.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelMessageId) Evergreen.V52.DmChannel.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
    , name : Evergreen.V52.GuildName.GuildName
    , icon : Maybe Evergreen.V52.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V52.SecretId.SecretId Evergreen.V52.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V52.NonemptyDict.NonemptyDict (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) Evergreen.V52.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V52.Slack.ClientSecret
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
    , user : Evergreen.V52.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) Evergreen.V52.User.FrontendUser
    , timezone : Effect.Time.Zone
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) Evergreen.V52.DmChannel.FrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , publicVapidKey : String
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V52.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
    , name : Evergreen.V52.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V52.Message.Message Evergreen.V52.Id.ChannelMessageId)
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) (Evergreen.V52.DmChannel.LastTypedAt Evergreen.V52.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V52.OneToOne.OneToOne Evergreen.V52.DmChannel.ExternalMessageId (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelMessageId) Evergreen.V52.DmChannel.Thread
    , linkedThreadIds : Evergreen.V52.OneToOne.OneToOne Evergreen.V52.DmChannel.ExternalChannelId (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelMessageId)
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
    , name : Evergreen.V52.GuildName.GuildName
    , icon : Maybe Evergreen.V52.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelId) BackendChannel
    , linkedChannelIds : Evergreen.V52.OneToOne.OneToOne Evergreen.V52.DmChannel.ExternalChannelId (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelId)
    , members :
        SeqDict.SeqDict
            (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V52.SecretId.SecretId Evergreen.V52.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
            }
    }
