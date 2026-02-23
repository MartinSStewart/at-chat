module Evergreen.V118.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V118.ChannelName
import Evergreen.V118.Discord.Id
import Evergreen.V118.DmChannel
import Evergreen.V118.FileStatus
import Evergreen.V118.GuildName
import Evergreen.V118.Id
import Evergreen.V118.Log
import Evergreen.V118.Message
import Evergreen.V118.NonemptyDict
import Evergreen.V118.OneToOne
import Evergreen.V118.SecretId
import Evergreen.V118.SessionIdHash
import Evergreen.V118.Slack
import Evergreen.V118.TextEditor
import Evergreen.V118.Thread
import Evergreen.V118.User
import Evergreen.V118.UserAgent
import Evergreen.V118.UserSession
import Evergreen.V118.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V118.Id.Id Evergreen.V118.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V118.Id.Id Evergreen.V118.Id.UserId
    , name : Evergreen.V118.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V118.Message.MessageState Evergreen.V118.Id.ChannelMessageId (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId))
    , visibleMessages : Evergreen.V118.VisibleMessages.VisibleMessages Evergreen.V118.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) (Evergreen.V118.Thread.LastTypedAt Evergreen.V118.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) Evergreen.V118.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V118.Id.Id Evergreen.V118.Id.UserId
    , name : Evergreen.V118.GuildName.GuildName
    , icon : Maybe Evergreen.V118.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V118.Id.Id Evergreen.V118.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V118.SecretId.SecretId Evergreen.V118.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V118.Id.Id Evergreen.V118.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V118.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V118.Message.MessageState Evergreen.V118.Id.ChannelMessageId (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId))
    , visibleMessages : Evergreen.V118.VisibleMessages.VisibleMessages Evergreen.V118.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) (Evergreen.V118.Thread.LastTypedAt Evergreen.V118.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) Evergreen.V118.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V118.GuildName.GuildName
    , icon : Maybe Evergreen.V118.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V118.NonemptyDict.NonemptyDict (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) Evergreen.V118.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V118.Slack.ClientSecret
    , openRouterKey : Maybe String
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V118.UserSession.UserSession
    , user : Evergreen.V118.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) Evergreen.V118.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) Evergreen.V118.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) Evergreen.V118.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V118.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) Evergreen.V118.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.PrivateChannelId) Evergreen.V118.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V118.SessionIdHash.SessionIdHash Evergreen.V118.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V118.TextEditor.LocalState
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V118.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V118.Id.Id Evergreen.V118.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V118.Id.Id Evergreen.V118.Id.UserId
    , name : Evergreen.V118.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V118.Message.Message Evergreen.V118.Id.ChannelMessageId (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) (Evergreen.V118.Thread.LastTypedAt Evergreen.V118.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) Evergreen.V118.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V118.Id.Id Evergreen.V118.Id.UserId
    , name : Evergreen.V118.GuildName.GuildName
    , icon : Maybe Evergreen.V118.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V118.Id.Id Evergreen.V118.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V118.SecretId.SecretId Evergreen.V118.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V118.Id.Id Evergreen.V118.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V118.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V118.Message.Message Evergreen.V118.Id.ChannelMessageId (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) (Evergreen.V118.Thread.LastTypedAt Evergreen.V118.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V118.OneToOne.OneToOne (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.MessageId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) Evergreen.V118.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V118.GuildName.GuildName
    , icon : Maybe Evergreen.V118.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId
    }
