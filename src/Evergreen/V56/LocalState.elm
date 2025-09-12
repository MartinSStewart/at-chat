module Evergreen.V56.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V56.ChannelName
import Evergreen.V56.DmChannel
import Evergreen.V56.FileStatus
import Evergreen.V56.GuildName
import Evergreen.V56.Id
import Evergreen.V56.Log
import Evergreen.V56.Message
import Evergreen.V56.NonemptyDict
import Evergreen.V56.OneToOne
import Evergreen.V56.SecretId
import Evergreen.V56.Slack
import Evergreen.V56.User
import Evergreen.V56.VisibleMessages
import SeqDict


type DiscordBotToken
    = DiscordBotToken String


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
    , name : Evergreen.V56.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V56.Message.MessageState Evergreen.V56.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V56.VisibleMessages.VisibleMessages Evergreen.V56.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) (Evergreen.V56.DmChannel.LastTypedAt Evergreen.V56.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelMessageId) Evergreen.V56.DmChannel.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
    , name : Evergreen.V56.GuildName.GuildName
    , icon : Maybe Evergreen.V56.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V56.SecretId.SecretId Evergreen.V56.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V56.NonemptyDict.NonemptyDict (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) Evergreen.V56.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) Effect.Time.Posix
    , botToken : Maybe DiscordBotToken
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V56.Slack.ClientSecret
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
    , user : Evergreen.V56.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) Evergreen.V56.User.FrontendUser
    , timezone : Effect.Time.Zone
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId) FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) Evergreen.V56.DmChannel.FrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , publicVapidKey : String
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V56.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
    , name : Evergreen.V56.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V56.Message.Message Evergreen.V56.Id.ChannelMessageId)
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) (Evergreen.V56.DmChannel.LastTypedAt Evergreen.V56.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V56.OneToOne.OneToOne Evergreen.V56.DmChannel.ExternalMessageId (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelMessageId) Evergreen.V56.DmChannel.Thread
    , linkedThreadIds : Evergreen.V56.OneToOne.OneToOne Evergreen.V56.DmChannel.ExternalChannelId (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelMessageId)
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
    , name : Evergreen.V56.GuildName.GuildName
    , icon : Maybe Evergreen.V56.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelId) BackendChannel
    , linkedChannelIds : Evergreen.V56.OneToOne.OneToOne Evergreen.V56.DmChannel.ExternalChannelId (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelId)
    , members :
        SeqDict.SeqDict
            (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V56.SecretId.SecretId Evergreen.V56.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
            }
    }
