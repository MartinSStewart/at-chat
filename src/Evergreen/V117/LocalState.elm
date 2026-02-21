module Evergreen.V117.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V117.ChannelName
import Evergreen.V117.Discord.Id
import Evergreen.V117.DmChannel
import Evergreen.V117.FileStatus
import Evergreen.V117.GuildName
import Evergreen.V117.Id
import Evergreen.V117.Log
import Evergreen.V117.Message
import Evergreen.V117.NonemptyDict
import Evergreen.V117.OneToOne
import Evergreen.V117.SecretId
import Evergreen.V117.SessionIdHash
import Evergreen.V117.Slack
import Evergreen.V117.TextEditor
import Evergreen.V117.Thread
import Evergreen.V117.User
import Evergreen.V117.UserAgent
import Evergreen.V117.UserSession
import Evergreen.V117.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V117.Id.Id Evergreen.V117.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V117.Id.Id Evergreen.V117.Id.UserId
    , name : Evergreen.V117.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V117.Message.MessageState Evergreen.V117.Id.ChannelMessageId (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId))
    , visibleMessages : Evergreen.V117.VisibleMessages.VisibleMessages Evergreen.V117.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) (Evergreen.V117.Thread.LastTypedAt Evergreen.V117.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) Evergreen.V117.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V117.Id.Id Evergreen.V117.Id.UserId
    , name : Evergreen.V117.GuildName.GuildName
    , icon : Maybe Evergreen.V117.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V117.Id.Id Evergreen.V117.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V117.SecretId.SecretId Evergreen.V117.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V117.Id.Id Evergreen.V117.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V117.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V117.Message.MessageState Evergreen.V117.Id.ChannelMessageId (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId))
    , visibleMessages : Evergreen.V117.VisibleMessages.VisibleMessages Evergreen.V117.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) (Evergreen.V117.Thread.LastTypedAt Evergreen.V117.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) Evergreen.V117.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V117.GuildName.GuildName
    , icon : Maybe Evergreen.V117.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V117.NonemptyDict.NonemptyDict (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) Evergreen.V117.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V117.Slack.ClientSecret
    , openRouterKey : Maybe String
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V117.UserSession.UserSession
    , user : Evergreen.V117.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) Evergreen.V117.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) Evergreen.V117.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) Evergreen.V117.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V117.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) Evergreen.V117.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.PrivateChannelId) Evergreen.V117.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V117.SessionIdHash.SessionIdHash Evergreen.V117.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V117.TextEditor.LocalState
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V117.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V117.Id.Id Evergreen.V117.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V117.Id.Id Evergreen.V117.Id.UserId
    , name : Evergreen.V117.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V117.Message.Message Evergreen.V117.Id.ChannelMessageId (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) (Evergreen.V117.Thread.LastTypedAt Evergreen.V117.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) Evergreen.V117.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V117.Id.Id Evergreen.V117.Id.UserId
    , name : Evergreen.V117.GuildName.GuildName
    , icon : Maybe Evergreen.V117.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V117.Id.Id Evergreen.V117.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V117.SecretId.SecretId Evergreen.V117.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V117.Id.Id Evergreen.V117.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V117.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V117.Message.Message Evergreen.V117.Id.ChannelMessageId (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) (Evergreen.V117.Thread.LastTypedAt Evergreen.V117.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V117.OneToOne.OneToOne (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.MessageId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) Evergreen.V117.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V117.GuildName.GuildName
    , icon : Maybe Evergreen.V117.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId
    }
