module Evergreen.V121.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V121.ChannelName
import Evergreen.V121.Discord
import Evergreen.V121.Discord.Id
import Evergreen.V121.DmChannel
import Evergreen.V121.FileStatus
import Evergreen.V121.GuildName
import Evergreen.V121.Id
import Evergreen.V121.Log
import Evergreen.V121.Message
import Evergreen.V121.NonemptyDict
import Evergreen.V121.NonemptySet
import Evergreen.V121.OneToOne
import Evergreen.V121.SecretId
import Evergreen.V121.SessionIdHash
import Evergreen.V121.Slack
import Evergreen.V121.TextEditor
import Evergreen.V121.Thread
import Evergreen.V121.User
import Evergreen.V121.UserAgent
import Evergreen.V121.UserSession
import Evergreen.V121.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V121.Discord.PartialUser
        , icon : Maybe Evergreen.V121.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V121.Discord.User
        , linkedTo : Evergreen.V121.Id.Id Evergreen.V121.Id.UserId
        , icon : Maybe Evergreen.V121.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V121.User.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V121.Discord.User
        , linkedTo : Evergreen.V121.Id.Id Evergreen.V121.Id.UserId
        , icon : Maybe Evergreen.V121.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V121.Id.Id Evergreen.V121.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V121.Id.Id Evergreen.V121.Id.UserId
    , name : Evergreen.V121.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V121.Message.MessageState Evergreen.V121.Id.ChannelMessageId (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId))
    , visibleMessages : Evergreen.V121.VisibleMessages.VisibleMessages Evergreen.V121.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId) (Evergreen.V121.Thread.LastTypedAt Evergreen.V121.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelMessageId) Evergreen.V121.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V121.Id.Id Evergreen.V121.Id.UserId
    , name : Evergreen.V121.GuildName.GuildName
    , icon : Maybe Evergreen.V121.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V121.Id.Id Evergreen.V121.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V121.SecretId.SecretId Evergreen.V121.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V121.Id.Id Evergreen.V121.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V121.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V121.Message.MessageState Evergreen.V121.Id.ChannelMessageId (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId))
    , visibleMessages : Evergreen.V121.VisibleMessages.VisibleMessages Evergreen.V121.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId) (Evergreen.V121.Thread.LastTypedAt Evergreen.V121.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelMessageId) Evergreen.V121.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V121.GuildName.GuildName
    , icon : Maybe Evergreen.V121.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V121.NonemptyDict.NonemptyDict (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId) Evergreen.V121.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V121.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels :
        SeqDict.SeqDict
            (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.PrivateChannelId)
            { members : Evergreen.V121.NonemptySet.NonemptySet (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId)
            , messageCount : Int
            }
    , discordUsers : SeqDict.SeqDict (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId) DiscordUserData_ForAdmin
    , discordGuilds :
        SeqDict.SeqDict
            (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.GuildId)
            { name : Evergreen.V121.GuildName.GuildName
            , channelCount : Int
            , memberCount : Int
            , owner : Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId
            }
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V121.UserSession.UserSession
    , user : Evergreen.V121.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId) Evergreen.V121.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId) Evergreen.V121.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId) Evergreen.V121.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V121.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId) Evergreen.V121.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.PrivateChannelId) Evergreen.V121.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V121.SessionIdHash.SessionIdHash Evergreen.V121.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V121.TextEditor.LocalState
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V121.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V121.Id.Id Evergreen.V121.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V121.Id.Id Evergreen.V121.Id.UserId
    , name : Evergreen.V121.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V121.Message.Message Evergreen.V121.Id.ChannelMessageId (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId) (Evergreen.V121.Thread.LastTypedAt Evergreen.V121.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelMessageId) Evergreen.V121.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V121.Id.Id Evergreen.V121.Id.UserId
    , name : Evergreen.V121.GuildName.GuildName
    , icon : Maybe Evergreen.V121.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V121.Id.Id Evergreen.V121.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V121.SecretId.SecretId Evergreen.V121.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V121.Id.Id Evergreen.V121.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V121.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V121.Message.Message Evergreen.V121.Id.ChannelMessageId (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId) (Evergreen.V121.Thread.LastTypedAt Evergreen.V121.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V121.OneToOne.OneToOne (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.MessageId) (Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelMessageId) Evergreen.V121.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V121.GuildName.GuildName
    , icon : Maybe Evergreen.V121.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId
    }
