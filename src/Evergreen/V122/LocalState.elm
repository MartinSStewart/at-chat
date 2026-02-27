module Evergreen.V122.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V122.ChannelName
import Evergreen.V122.Discord
import Evergreen.V122.Discord.Id
import Evergreen.V122.DmChannel
import Evergreen.V122.FileStatus
import Evergreen.V122.GuildName
import Evergreen.V122.Id
import Evergreen.V122.Log
import Evergreen.V122.Message
import Evergreen.V122.NonemptyDict
import Evergreen.V122.NonemptySet
import Evergreen.V122.OneToOne
import Evergreen.V122.SecretId
import Evergreen.V122.SessionIdHash
import Evergreen.V122.Slack
import Evergreen.V122.TextEditor
import Evergreen.V122.Thread
import Evergreen.V122.User
import Evergreen.V122.UserAgent
import Evergreen.V122.UserSession
import Evergreen.V122.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V122.Discord.PartialUser
        , icon : Maybe Evergreen.V122.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V122.Discord.User
        , linkedTo : Evergreen.V122.Id.Id Evergreen.V122.Id.UserId
        , icon : Maybe Evergreen.V122.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V122.User.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V122.Discord.User
        , linkedTo : Evergreen.V122.Id.Id Evergreen.V122.Id.UserId
        , icon : Maybe Evergreen.V122.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V122.Id.Id Evergreen.V122.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V122.Id.Id Evergreen.V122.Id.UserId
    , name : Evergreen.V122.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V122.Message.MessageState Evergreen.V122.Id.ChannelMessageId (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId))
    , visibleMessages : Evergreen.V122.VisibleMessages.VisibleMessages Evergreen.V122.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) (Evergreen.V122.Thread.LastTypedAt Evergreen.V122.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) Evergreen.V122.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V122.Id.Id Evergreen.V122.Id.UserId
    , name : Evergreen.V122.GuildName.GuildName
    , icon : Maybe Evergreen.V122.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V122.Id.Id Evergreen.V122.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V122.SecretId.SecretId Evergreen.V122.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V122.Id.Id Evergreen.V122.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V122.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V122.Message.MessageState Evergreen.V122.Id.ChannelMessageId (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId))
    , visibleMessages : Evergreen.V122.VisibleMessages.VisibleMessages Evergreen.V122.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) (Evergreen.V122.Thread.LastTypedAt Evergreen.V122.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) Evergreen.V122.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V122.GuildName.GuildName
    , icon : Maybe Evergreen.V122.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V122.NonemptyDict.NonemptyDict (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) Evergreen.V122.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V122.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels :
        SeqDict.SeqDict
            (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.PrivateChannelId)
            { members : Evergreen.V122.NonemptySet.NonemptySet (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId)
            , messageCount : Int
            }
    , discordUsers : SeqDict.SeqDict (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) DiscordUserData_ForAdmin
    , discordGuilds :
        SeqDict.SeqDict
            (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId)
            { name : Evergreen.V122.GuildName.GuildName
            , channelCount : Int
            , memberCount : Int
            , owner : Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId
            }
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V122.UserSession.UserSession
    , user : Evergreen.V122.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) Evergreen.V122.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) Evergreen.V122.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) Evergreen.V122.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V122.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) Evergreen.V122.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.PrivateChannelId) Evergreen.V122.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V122.SessionIdHash.SessionIdHash Evergreen.V122.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V122.TextEditor.LocalState
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V122.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V122.Id.Id Evergreen.V122.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V122.Id.Id Evergreen.V122.Id.UserId
    , name : Evergreen.V122.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V122.Message.Message Evergreen.V122.Id.ChannelMessageId (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) (Evergreen.V122.Thread.LastTypedAt Evergreen.V122.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) Evergreen.V122.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V122.Id.Id Evergreen.V122.Id.UserId
    , name : Evergreen.V122.GuildName.GuildName
    , icon : Maybe Evergreen.V122.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V122.Id.Id Evergreen.V122.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V122.SecretId.SecretId Evergreen.V122.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V122.Id.Id Evergreen.V122.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V122.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V122.Message.Message Evergreen.V122.Id.ChannelMessageId (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) (Evergreen.V122.Thread.LastTypedAt Evergreen.V122.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V122.OneToOne.OneToOne (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.MessageId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) Evergreen.V122.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V122.GuildName.GuildName
    , icon : Maybe Evergreen.V122.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId
    }
