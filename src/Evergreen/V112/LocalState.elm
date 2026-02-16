module Evergreen.V112.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V112.ChannelName
import Evergreen.V112.Discord.Id
import Evergreen.V112.DmChannel
import Evergreen.V112.FileStatus
import Evergreen.V112.GuildName
import Evergreen.V112.Id
import Evergreen.V112.Log
import Evergreen.V112.Message
import Evergreen.V112.NonemptyDict
import Evergreen.V112.OneToOne
import Evergreen.V112.SecretId
import Evergreen.V112.SessionIdHash
import Evergreen.V112.Slack
import Evergreen.V112.TextEditor
import Evergreen.V112.Thread
import Evergreen.V112.User
import Evergreen.V112.UserAgent
import Evergreen.V112.UserSession
import Evergreen.V112.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
    , name : Evergreen.V112.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V112.Message.MessageState Evergreen.V112.Id.ChannelMessageId (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId))
    , visibleMessages : Evergreen.V112.VisibleMessages.VisibleMessages Evergreen.V112.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) (Evergreen.V112.Thread.LastTypedAt Evergreen.V112.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) Evergreen.V112.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
    , name : Evergreen.V112.GuildName.GuildName
    , icon : Maybe Evergreen.V112.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V112.SecretId.SecretId Evergreen.V112.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V112.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V112.Message.MessageState Evergreen.V112.Id.ChannelMessageId (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId))
    , visibleMessages : Evergreen.V112.VisibleMessages.VisibleMessages Evergreen.V112.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) (Evergreen.V112.Thread.LastTypedAt Evergreen.V112.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) Evergreen.V112.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V112.GuildName.GuildName
    , icon : Maybe Evergreen.V112.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V112.NonemptyDict.NonemptyDict (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) Evergreen.V112.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V112.Slack.ClientSecret
    , openRouterKey : Maybe String
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V112.UserSession.UserSession
    , user : Evergreen.V112.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) Evergreen.V112.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) Evergreen.V112.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) Evergreen.V112.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V112.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) Evergreen.V112.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.PrivateChannelId) Evergreen.V112.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V112.SessionIdHash.SessionIdHash Evergreen.V112.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V112.TextEditor.LocalState
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V112.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
    , name : Evergreen.V112.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V112.Message.Message Evergreen.V112.Id.ChannelMessageId (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) (Evergreen.V112.Thread.LastTypedAt Evergreen.V112.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) Evergreen.V112.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
    , name : Evergreen.V112.GuildName.GuildName
    , icon : Maybe Evergreen.V112.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V112.SecretId.SecretId Evergreen.V112.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V112.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V112.Message.Message Evergreen.V112.Id.ChannelMessageId (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) (Evergreen.V112.Thread.LastTypedAt Evergreen.V112.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V112.OneToOne.OneToOne (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.MessageId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) Evergreen.V112.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V112.GuildName.GuildName
    , icon : Maybe Evergreen.V112.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId
    }
