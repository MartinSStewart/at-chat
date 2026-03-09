module Evergreen.V148.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V148.ChannelName
import Evergreen.V148.Discord
import Evergreen.V148.DiscordUserData
import Evergreen.V148.DmChannel
import Evergreen.V148.FileStatus
import Evergreen.V148.GuildName
import Evergreen.V148.Id
import Evergreen.V148.Log
import Evergreen.V148.Message
import Evergreen.V148.NonemptyDict
import Evergreen.V148.NonemptySet
import Evergreen.V148.OneToOne
import Evergreen.V148.Pagination
import Evergreen.V148.SecretId
import Evergreen.V148.SessionIdHash
import Evergreen.V148.Slack
import Evergreen.V148.TextEditor
import Evergreen.V148.Thread
import Evergreen.V148.User
import Evergreen.V148.UserAgent
import Evergreen.V148.UserSession
import Evergreen.V148.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members : Evergreen.V148.NonemptySet.NonemptySet (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId)
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V148.Message.Message Evergreen.V148.Id.ChannelMessageId (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V148.Discord.PartialUser
        , icon : Maybe Evergreen.V148.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V148.Discord.User
        , linkedTo : Evergreen.V148.Id.Id Evergreen.V148.Id.UserId
        , icon : Maybe Evergreen.V148.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V148.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V148.Discord.User
        , linkedTo : Evergreen.V148.Id.Id Evergreen.V148.Id.UserId
        , icon : Maybe Evergreen.V148.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V148.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V148.Message.Message Evergreen.V148.Id.ChannelMessageId (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V148.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId) AdminData_DiscordChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V148.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V148.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V148.Id.Id Evergreen.V148.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V148.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V148.Log.Log
    , isHidden : Bool
    }


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V148.Id.Id Evergreen.V148.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V148.Id.Id Evergreen.V148.Id.UserId
    , name : Evergreen.V148.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V148.Message.MessageState Evergreen.V148.Id.ChannelMessageId (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId))
    , visibleMessages : Evergreen.V148.VisibleMessages.VisibleMessages Evergreen.V148.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) (Evergreen.V148.Thread.LastTypedAt Evergreen.V148.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) Evergreen.V148.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V148.Id.Id Evergreen.V148.Id.UserId
    , name : Evergreen.V148.GuildName.GuildName
    , icon : Maybe Evergreen.V148.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V148.Id.Id Evergreen.V148.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V148.SecretId.SecretId Evergreen.V148.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V148.Id.Id Evergreen.V148.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V148.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V148.Message.MessageState Evergreen.V148.Id.ChannelMessageId (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId))
    , visibleMessages : Evergreen.V148.VisibleMessages.VisibleMessages Evergreen.V148.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Evergreen.V148.Thread.LastTypedAt Evergreen.V148.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) Evergreen.V148.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V148.GuildName.GuildName
    , icon : Maybe Evergreen.V148.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V148.NonemptyDict.NonemptyDict (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) Evergreen.V148.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V148.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V148.Pagination.Pagination LogWithTime
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V148.UserSession.UserSession
    , user : Evergreen.V148.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) Evergreen.V148.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) Evergreen.V148.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) Evergreen.V148.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V148.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) Evergreen.V148.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId) Evergreen.V148.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V148.SessionIdHash.SessionIdHash Evergreen.V148.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V148.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V148.Id.Id Evergreen.V148.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V148.Id.Id Evergreen.V148.Id.UserId
    , name : Evergreen.V148.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V148.Message.Message Evergreen.V148.Id.ChannelMessageId (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) (Evergreen.V148.Thread.LastTypedAt Evergreen.V148.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) Evergreen.V148.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V148.Id.Id Evergreen.V148.Id.UserId
    , name : Evergreen.V148.GuildName.GuildName
    , icon : Maybe Evergreen.V148.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V148.Id.Id Evergreen.V148.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V148.SecretId.SecretId Evergreen.V148.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V148.Id.Id Evergreen.V148.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V148.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V148.Message.Message Evergreen.V148.Id.ChannelMessageId (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Evergreen.V148.Thread.LastTypedAt Evergreen.V148.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V148.OneToOne.OneToOne (Evergreen.V148.Discord.Id Evergreen.V148.Discord.MessageId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) Evergreen.V148.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V148.GuildName.GuildName
    , icon : Maybe Evergreen.V148.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId
    }
