module Evergreen.V120.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V120.ChannelName
import Evergreen.V120.Discord
import Evergreen.V120.Discord.Id
import Evergreen.V120.DmChannel
import Evergreen.V120.FileStatus
import Evergreen.V120.GuildName
import Evergreen.V120.Id
import Evergreen.V120.Log
import Evergreen.V120.Message
import Evergreen.V120.NonemptyDict
import Evergreen.V120.NonemptySet
import Evergreen.V120.OneToOne
import Evergreen.V120.SecretId
import Evergreen.V120.SessionIdHash
import Evergreen.V120.Slack
import Evergreen.V120.TextEditor
import Evergreen.V120.Thread
import Evergreen.V120.User
import Evergreen.V120.UserAgent
import Evergreen.V120.UserSession
import Evergreen.V120.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V120.Discord.PartialUser
        , icon : Maybe Evergreen.V120.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V120.Discord.User
        , linkedTo : Evergreen.V120.Id.Id Evergreen.V120.Id.UserId
        , icon : Maybe Evergreen.V120.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V120.User.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V120.Discord.User
        , linkedTo : Evergreen.V120.Id.Id Evergreen.V120.Id.UserId
        , icon : Maybe Evergreen.V120.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V120.Id.Id Evergreen.V120.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V120.Id.Id Evergreen.V120.Id.UserId
    , name : Evergreen.V120.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V120.Message.MessageState Evergreen.V120.Id.ChannelMessageId (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId))
    , visibleMessages : Evergreen.V120.VisibleMessages.VisibleMessages Evergreen.V120.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) (Evergreen.V120.Thread.LastTypedAt Evergreen.V120.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) Evergreen.V120.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V120.Id.Id Evergreen.V120.Id.UserId
    , name : Evergreen.V120.GuildName.GuildName
    , icon : Maybe Evergreen.V120.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V120.Id.Id Evergreen.V120.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V120.SecretId.SecretId Evergreen.V120.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V120.Id.Id Evergreen.V120.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V120.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V120.Message.MessageState Evergreen.V120.Id.ChannelMessageId (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId))
    , visibleMessages : Evergreen.V120.VisibleMessages.VisibleMessages Evergreen.V120.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) (Evergreen.V120.Thread.LastTypedAt Evergreen.V120.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) Evergreen.V120.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V120.GuildName.GuildName
    , icon : Maybe Evergreen.V120.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V120.NonemptyDict.NonemptyDict (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) Evergreen.V120.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V120.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels :
        SeqDict.SeqDict
            (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.PrivateChannelId)
            { members : Evergreen.V120.NonemptySet.NonemptySet (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId)
            , messageCount : Int
            }
    , discordUsers : SeqDict.SeqDict (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) DiscordUserData_ForAdmin
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V120.UserSession.UserSession
    , user : Evergreen.V120.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) Evergreen.V120.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) Evergreen.V120.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) Evergreen.V120.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V120.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) Evergreen.V120.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.PrivateChannelId) Evergreen.V120.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V120.SessionIdHash.SessionIdHash Evergreen.V120.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V120.TextEditor.LocalState
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V120.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V120.Id.Id Evergreen.V120.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V120.Id.Id Evergreen.V120.Id.UserId
    , name : Evergreen.V120.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V120.Message.Message Evergreen.V120.Id.ChannelMessageId (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) (Evergreen.V120.Thread.LastTypedAt Evergreen.V120.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) Evergreen.V120.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V120.Id.Id Evergreen.V120.Id.UserId
    , name : Evergreen.V120.GuildName.GuildName
    , icon : Maybe Evergreen.V120.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V120.Id.Id Evergreen.V120.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V120.SecretId.SecretId Evergreen.V120.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V120.Id.Id Evergreen.V120.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V120.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V120.Message.Message Evergreen.V120.Id.ChannelMessageId (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) (Evergreen.V120.Thread.LastTypedAt Evergreen.V120.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V120.OneToOne.OneToOne (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.MessageId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) Evergreen.V120.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V120.GuildName.GuildName
    , icon : Maybe Evergreen.V120.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId
    }
