module Evergreen.V115.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V115.ChannelName
import Evergreen.V115.Discord.Id
import Evergreen.V115.DmChannel
import Evergreen.V115.FileStatus
import Evergreen.V115.GuildName
import Evergreen.V115.Id
import Evergreen.V115.Log
import Evergreen.V115.Message
import Evergreen.V115.NonemptyDict
import Evergreen.V115.OneToOne
import Evergreen.V115.SecretId
import Evergreen.V115.SessionIdHash
import Evergreen.V115.Slack
import Evergreen.V115.TextEditor
import Evergreen.V115.Thread
import Evergreen.V115.User
import Evergreen.V115.UserAgent
import Evergreen.V115.UserSession
import Evergreen.V115.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
    , name : Evergreen.V115.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V115.Message.MessageState Evergreen.V115.Id.ChannelMessageId (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId))
    , visibleMessages : Evergreen.V115.VisibleMessages.VisibleMessages Evergreen.V115.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) (Evergreen.V115.Thread.LastTypedAt Evergreen.V115.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) Evergreen.V115.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
    , name : Evergreen.V115.GuildName.GuildName
    , icon : Maybe Evergreen.V115.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V115.SecretId.SecretId Evergreen.V115.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V115.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V115.Message.MessageState Evergreen.V115.Id.ChannelMessageId (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId))
    , visibleMessages : Evergreen.V115.VisibleMessages.VisibleMessages Evergreen.V115.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) (Evergreen.V115.Thread.LastTypedAt Evergreen.V115.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) Evergreen.V115.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V115.GuildName.GuildName
    , icon : Maybe Evergreen.V115.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V115.NonemptyDict.NonemptyDict (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) Evergreen.V115.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V115.Slack.ClientSecret
    , openRouterKey : Maybe String
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V115.UserSession.UserSession
    , user : Evergreen.V115.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) Evergreen.V115.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) Evergreen.V115.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) Evergreen.V115.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V115.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) Evergreen.V115.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.PrivateChannelId) Evergreen.V115.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V115.SessionIdHash.SessionIdHash Evergreen.V115.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V115.TextEditor.LocalState
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V115.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
    , name : Evergreen.V115.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V115.Message.Message Evergreen.V115.Id.ChannelMessageId (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) (Evergreen.V115.Thread.LastTypedAt Evergreen.V115.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) Evergreen.V115.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
    , name : Evergreen.V115.GuildName.GuildName
    , icon : Maybe Evergreen.V115.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V115.SecretId.SecretId Evergreen.V115.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V115.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V115.Message.Message Evergreen.V115.Id.ChannelMessageId (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) (Evergreen.V115.Thread.LastTypedAt Evergreen.V115.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V115.OneToOne.OneToOne (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.MessageId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) Evergreen.V115.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V115.GuildName.GuildName
    , icon : Maybe Evergreen.V115.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId
    }
