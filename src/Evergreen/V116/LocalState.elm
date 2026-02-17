module Evergreen.V116.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V116.ChannelName
import Evergreen.V116.Discord.Id
import Evergreen.V116.DmChannel
import Evergreen.V116.FileStatus
import Evergreen.V116.GuildName
import Evergreen.V116.Id
import Evergreen.V116.Log
import Evergreen.V116.Message
import Evergreen.V116.NonemptyDict
import Evergreen.V116.OneToOne
import Evergreen.V116.SecretId
import Evergreen.V116.SessionIdHash
import Evergreen.V116.Slack
import Evergreen.V116.TextEditor
import Evergreen.V116.Thread
import Evergreen.V116.User
import Evergreen.V116.UserAgent
import Evergreen.V116.UserSession
import Evergreen.V116.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
    , name : Evergreen.V116.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V116.Message.MessageState Evergreen.V116.Id.ChannelMessageId (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId))
    , visibleMessages : Evergreen.V116.VisibleMessages.VisibleMessages Evergreen.V116.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) (Evergreen.V116.Thread.LastTypedAt Evergreen.V116.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) Evergreen.V116.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
    , name : Evergreen.V116.GuildName.GuildName
    , icon : Maybe Evergreen.V116.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V116.SecretId.SecretId Evergreen.V116.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V116.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V116.Message.MessageState Evergreen.V116.Id.ChannelMessageId (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId))
    , visibleMessages : Evergreen.V116.VisibleMessages.VisibleMessages Evergreen.V116.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) (Evergreen.V116.Thread.LastTypedAt Evergreen.V116.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) Evergreen.V116.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V116.GuildName.GuildName
    , icon : Maybe Evergreen.V116.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V116.NonemptyDict.NonemptyDict (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) Evergreen.V116.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V116.Slack.ClientSecret
    , openRouterKey : Maybe String
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V116.UserSession.UserSession
    , user : Evergreen.V116.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) Evergreen.V116.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) Evergreen.V116.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) Evergreen.V116.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V116.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) Evergreen.V116.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.PrivateChannelId) Evergreen.V116.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V116.SessionIdHash.SessionIdHash Evergreen.V116.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V116.TextEditor.LocalState
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V116.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
    , name : Evergreen.V116.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V116.Message.Message Evergreen.V116.Id.ChannelMessageId (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) (Evergreen.V116.Thread.LastTypedAt Evergreen.V116.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) Evergreen.V116.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
    , name : Evergreen.V116.GuildName.GuildName
    , icon : Maybe Evergreen.V116.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V116.SecretId.SecretId Evergreen.V116.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V116.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V116.Message.Message Evergreen.V116.Id.ChannelMessageId (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) (Evergreen.V116.Thread.LastTypedAt Evergreen.V116.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V116.OneToOne.OneToOne (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.MessageId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) Evergreen.V116.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V116.GuildName.GuildName
    , icon : Maybe Evergreen.V116.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId
    }
