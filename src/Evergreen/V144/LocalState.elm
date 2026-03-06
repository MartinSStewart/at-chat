module Evergreen.V144.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V144.ChannelName
import Evergreen.V144.Discord
import Evergreen.V144.DmChannel
import Evergreen.V144.FileStatus
import Evergreen.V144.GuildName
import Evergreen.V144.Id
import Evergreen.V144.Log
import Evergreen.V144.Message
import Evergreen.V144.NonemptyDict
import Evergreen.V144.NonemptySet
import Evergreen.V144.OneToOne
import Evergreen.V144.SecretId
import Evergreen.V144.SessionIdHash
import Evergreen.V144.Slack
import Evergreen.V144.TextEditor
import Evergreen.V144.Thread
import Evergreen.V144.User
import Evergreen.V144.UserAgent
import Evergreen.V144.UserSession
import Evergreen.V144.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members : Evergreen.V144.NonemptySet.NonemptySet (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId)
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V144.Message.Message Evergreen.V144.Id.ChannelMessageId (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V144.Discord.PartialUser
        , icon : Maybe Evergreen.V144.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V144.Discord.User
        , linkedTo : Evergreen.V144.Id.Id Evergreen.V144.Id.UserId
        , icon : Maybe Evergreen.V144.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V144.User.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V144.Discord.User
        , linkedTo : Evergreen.V144.Id.Id Evergreen.V144.Id.UserId
        , icon : Maybe Evergreen.V144.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V144.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V144.Message.Message Evergreen.V144.Id.ChannelMessageId (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V144.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId) AdminData_DiscordChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V144.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V144.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V144.Id.Id Evergreen.V144.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V144.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V144.Id.Id Evergreen.V144.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V144.Id.Id Evergreen.V144.Id.UserId
    , name : Evergreen.V144.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V144.Message.MessageState Evergreen.V144.Id.ChannelMessageId (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId))
    , visibleMessages : Evergreen.V144.VisibleMessages.VisibleMessages Evergreen.V144.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) (Evergreen.V144.Thread.LastTypedAt Evergreen.V144.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) Evergreen.V144.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V144.Id.Id Evergreen.V144.Id.UserId
    , name : Evergreen.V144.GuildName.GuildName
    , icon : Maybe Evergreen.V144.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V144.Id.Id Evergreen.V144.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V144.SecretId.SecretId Evergreen.V144.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V144.Id.Id Evergreen.V144.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V144.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V144.Message.MessageState Evergreen.V144.Id.ChannelMessageId (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId))
    , visibleMessages : Evergreen.V144.VisibleMessages.VisibleMessages Evergreen.V144.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Evergreen.V144.Thread.LastTypedAt Evergreen.V144.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) Evergreen.V144.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V144.GuildName.GuildName
    , icon : Maybe Evergreen.V144.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V144.NonemptyDict.NonemptyDict (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) Evergreen.V144.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V144.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V144.UserSession.UserSession
    , user : Evergreen.V144.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) Evergreen.V144.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) Evergreen.V144.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) Evergreen.V144.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V144.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) Evergreen.V144.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId) Evergreen.V144.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V144.SessionIdHash.SessionIdHash Evergreen.V144.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V144.TextEditor.LocalState
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V144.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V144.Id.Id Evergreen.V144.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V144.Id.Id Evergreen.V144.Id.UserId
    , name : Evergreen.V144.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V144.Message.Message Evergreen.V144.Id.ChannelMessageId (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) (Evergreen.V144.Thread.LastTypedAt Evergreen.V144.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) Evergreen.V144.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V144.Id.Id Evergreen.V144.Id.UserId
    , name : Evergreen.V144.GuildName.GuildName
    , icon : Maybe Evergreen.V144.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V144.Id.Id Evergreen.V144.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V144.SecretId.SecretId Evergreen.V144.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V144.Id.Id Evergreen.V144.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V144.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V144.Message.Message Evergreen.V144.Id.ChannelMessageId (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Evergreen.V144.Thread.LastTypedAt Evergreen.V144.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V144.OneToOne.OneToOne (Evergreen.V144.Discord.Id Evergreen.V144.Discord.MessageId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) Evergreen.V144.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V144.GuildName.GuildName
    , icon : Maybe Evergreen.V144.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId
    }
