module Evergreen.V114.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V114.ChannelName
import Evergreen.V114.Discord.Id
import Evergreen.V114.DmChannel
import Evergreen.V114.FileStatus
import Evergreen.V114.GuildName
import Evergreen.V114.Id
import Evergreen.V114.Log
import Evergreen.V114.Message
import Evergreen.V114.NonemptyDict
import Evergreen.V114.OneToOne
import Evergreen.V114.SecretId
import Evergreen.V114.SessionIdHash
import Evergreen.V114.Slack
import Evergreen.V114.TextEditor
import Evergreen.V114.Thread
import Evergreen.V114.User
import Evergreen.V114.UserAgent
import Evergreen.V114.UserSession
import Evergreen.V114.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
    , name : Evergreen.V114.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V114.Message.MessageState Evergreen.V114.Id.ChannelMessageId (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId))
    , visibleMessages : Evergreen.V114.VisibleMessages.VisibleMessages Evergreen.V114.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) (Evergreen.V114.Thread.LastTypedAt Evergreen.V114.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) Evergreen.V114.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
    , name : Evergreen.V114.GuildName.GuildName
    , icon : Maybe Evergreen.V114.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V114.SecretId.SecretId Evergreen.V114.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V114.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V114.Message.MessageState Evergreen.V114.Id.ChannelMessageId (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId))
    , visibleMessages : Evergreen.V114.VisibleMessages.VisibleMessages Evergreen.V114.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) (Evergreen.V114.Thread.LastTypedAt Evergreen.V114.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) Evergreen.V114.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V114.GuildName.GuildName
    , icon : Maybe Evergreen.V114.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V114.NonemptyDict.NonemptyDict (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) Evergreen.V114.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V114.Slack.ClientSecret
    , openRouterKey : Maybe String
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V114.UserSession.UserSession
    , user : Evergreen.V114.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) Evergreen.V114.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) Evergreen.V114.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) Evergreen.V114.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V114.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) Evergreen.V114.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.PrivateChannelId) Evergreen.V114.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V114.SessionIdHash.SessionIdHash Evergreen.V114.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V114.TextEditor.LocalState
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V114.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
    , name : Evergreen.V114.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V114.Message.Message Evergreen.V114.Id.ChannelMessageId (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) (Evergreen.V114.Thread.LastTypedAt Evergreen.V114.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) Evergreen.V114.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
    , name : Evergreen.V114.GuildName.GuildName
    , icon : Maybe Evergreen.V114.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V114.SecretId.SecretId Evergreen.V114.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V114.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V114.Message.Message Evergreen.V114.Id.ChannelMessageId (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) (Evergreen.V114.Thread.LastTypedAt Evergreen.V114.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V114.OneToOne.OneToOne (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.MessageId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) Evergreen.V114.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V114.GuildName.GuildName
    , icon : Maybe Evergreen.V114.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId
    }
