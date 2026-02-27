module Evergreen.V124.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V124.ChannelName
import Evergreen.V124.Discord
import Evergreen.V124.Discord.Id
import Evergreen.V124.DmChannel
import Evergreen.V124.FileStatus
import Evergreen.V124.GuildName
import Evergreen.V124.Id
import Evergreen.V124.Log
import Evergreen.V124.Message
import Evergreen.V124.NonemptyDict
import Evergreen.V124.NonemptySet
import Evergreen.V124.OneToOne
import Evergreen.V124.SecretId
import Evergreen.V124.SessionIdHash
import Evergreen.V124.Slack
import Evergreen.V124.TextEditor
import Evergreen.V124.Thread
import Evergreen.V124.User
import Evergreen.V124.UserAgent
import Evergreen.V124.UserSession
import Evergreen.V124.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V124.Discord.PartialUser
        , icon : Maybe Evergreen.V124.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V124.Discord.User
        , linkedTo : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
        , icon : Maybe Evergreen.V124.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V124.User.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V124.Discord.User
        , linkedTo : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
        , icon : Maybe Evergreen.V124.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
    , name : Evergreen.V124.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V124.Message.MessageState Evergreen.V124.Id.ChannelMessageId (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId))
    , visibleMessages : Evergreen.V124.VisibleMessages.VisibleMessages Evergreen.V124.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) (Evergreen.V124.Thread.LastTypedAt Evergreen.V124.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) Evergreen.V124.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
    , name : Evergreen.V124.GuildName.GuildName
    , icon : Maybe Evergreen.V124.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V124.SecretId.SecretId Evergreen.V124.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V124.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V124.Message.MessageState Evergreen.V124.Id.ChannelMessageId (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId))
    , visibleMessages : Evergreen.V124.VisibleMessages.VisibleMessages Evergreen.V124.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) (Evergreen.V124.Thread.LastTypedAt Evergreen.V124.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) Evergreen.V124.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V124.GuildName.GuildName
    , icon : Maybe Evergreen.V124.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V124.NonemptyDict.NonemptyDict (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) Evergreen.V124.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V124.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels :
        SeqDict.SeqDict
            (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.PrivateChannelId)
            { members : Evergreen.V124.NonemptySet.NonemptySet (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId)
            , messageCount : Int
            }
    , discordUsers : SeqDict.SeqDict (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) DiscordUserData_ForAdmin
    , discordGuilds :
        SeqDict.SeqDict
            (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId)
            { name : Evergreen.V124.GuildName.GuildName
            , channelCount : Int
            , memberCount : Int
            , owner : Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId
            }
    , guilds :
        SeqDict.SeqDict
            (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId)
            { name : Evergreen.V124.GuildName.GuildName
            , channelCount : Int
            , memberCount : Int
            , owner : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
            }
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V124.UserSession.UserSession
    , user : Evergreen.V124.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) Evergreen.V124.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) Evergreen.V124.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) Evergreen.V124.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V124.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) Evergreen.V124.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.PrivateChannelId) Evergreen.V124.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V124.SessionIdHash.SessionIdHash Evergreen.V124.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V124.TextEditor.LocalState
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V124.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
    , name : Evergreen.V124.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V124.Message.Message Evergreen.V124.Id.ChannelMessageId (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) (Evergreen.V124.Thread.LastTypedAt Evergreen.V124.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) Evergreen.V124.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
    , name : Evergreen.V124.GuildName.GuildName
    , icon : Maybe Evergreen.V124.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V124.SecretId.SecretId Evergreen.V124.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V124.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V124.Message.Message Evergreen.V124.Id.ChannelMessageId (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) (Evergreen.V124.Thread.LastTypedAt Evergreen.V124.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V124.OneToOne.OneToOne (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.MessageId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) Evergreen.V124.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V124.GuildName.GuildName
    , icon : Maybe Evergreen.V124.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId
    }
