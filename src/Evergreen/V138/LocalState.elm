module Evergreen.V138.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V138.ChannelName
import Evergreen.V138.Discord
import Evergreen.V138.Discord.Id
import Evergreen.V138.DmChannel
import Evergreen.V138.FileStatus
import Evergreen.V138.GuildName
import Evergreen.V138.Id
import Evergreen.V138.Log
import Evergreen.V138.Message
import Evergreen.V138.NonemptyDict
import Evergreen.V138.NonemptySet
import Evergreen.V138.OneToOne
import Evergreen.V138.SecretId
import Evergreen.V138.SessionIdHash
import Evergreen.V138.Slack
import Evergreen.V138.TextEditor
import Evergreen.V138.Thread
import Evergreen.V138.User
import Evergreen.V138.UserAgent
import Evergreen.V138.UserSession
import Evergreen.V138.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members : Evergreen.V138.NonemptySet.NonemptySet (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId)
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V138.Message.Message Evergreen.V138.Id.ChannelMessageId (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V138.Discord.PartialUser
        , icon : Maybe Evergreen.V138.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V138.Discord.User
        , linkedTo : Evergreen.V138.Id.Id Evergreen.V138.Id.UserId
        , icon : Maybe Evergreen.V138.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V138.User.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V138.Discord.User
        , linkedTo : Evergreen.V138.Id.Id Evergreen.V138.Id.UserId
        , icon : Maybe Evergreen.V138.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V138.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V138.Message.Message Evergreen.V138.Id.ChannelMessageId (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V138.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId) AdminData_DiscordChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V138.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V138.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V138.Id.Id Evergreen.V138.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V138.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId) (LoadingDiscordChannelStep messages)


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V138.Id.Id Evergreen.V138.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V138.Id.Id Evergreen.V138.Id.UserId
    , name : Evergreen.V138.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V138.Message.MessageState Evergreen.V138.Id.ChannelMessageId (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId))
    , visibleMessages : Evergreen.V138.VisibleMessages.VisibleMessages Evergreen.V138.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) (Evergreen.V138.Thread.LastTypedAt Evergreen.V138.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) Evergreen.V138.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V138.Id.Id Evergreen.V138.Id.UserId
    , name : Evergreen.V138.GuildName.GuildName
    , icon : Maybe Evergreen.V138.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V138.Id.Id Evergreen.V138.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V138.SecretId.SecretId Evergreen.V138.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V138.Id.Id Evergreen.V138.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V138.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V138.Message.MessageState Evergreen.V138.Id.ChannelMessageId (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId))
    , visibleMessages : Evergreen.V138.VisibleMessages.VisibleMessages Evergreen.V138.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Evergreen.V138.Thread.LastTypedAt Evergreen.V138.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) Evergreen.V138.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V138.GuildName.GuildName
    , icon : Maybe Evergreen.V138.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V138.NonemptyDict.NonemptyDict (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) Evergreen.V138.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V138.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V138.UserSession.UserSession
    , user : Evergreen.V138.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) Evergreen.V138.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) Evergreen.V138.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) Evergreen.V138.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V138.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) Evergreen.V138.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId) Evergreen.V138.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V138.SessionIdHash.SessionIdHash Evergreen.V138.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V138.TextEditor.LocalState
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V138.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V138.Id.Id Evergreen.V138.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V138.Id.Id Evergreen.V138.Id.UserId
    , name : Evergreen.V138.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V138.Message.Message Evergreen.V138.Id.ChannelMessageId (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) (Evergreen.V138.Thread.LastTypedAt Evergreen.V138.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) Evergreen.V138.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V138.Id.Id Evergreen.V138.Id.UserId
    , name : Evergreen.V138.GuildName.GuildName
    , icon : Maybe Evergreen.V138.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V138.Id.Id Evergreen.V138.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V138.SecretId.SecretId Evergreen.V138.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V138.Id.Id Evergreen.V138.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V138.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V138.Message.Message Evergreen.V138.Id.ChannelMessageId (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Evergreen.V138.Thread.LastTypedAt Evergreen.V138.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V138.OneToOne.OneToOne (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.MessageId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) Evergreen.V138.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V138.GuildName.GuildName
    , icon : Maybe Evergreen.V138.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId
    }
