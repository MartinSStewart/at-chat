module Evergreen.V147.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V147.ChannelName
import Evergreen.V147.Discord
import Evergreen.V147.DiscordUserData
import Evergreen.V147.DmChannel
import Evergreen.V147.FileStatus
import Evergreen.V147.GuildName
import Evergreen.V147.Id
import Evergreen.V147.Log
import Evergreen.V147.Message
import Evergreen.V147.NonemptyDict
import Evergreen.V147.NonemptySet
import Evergreen.V147.OneToOne
import Evergreen.V147.Pagination
import Evergreen.V147.SecretId
import Evergreen.V147.SessionIdHash
import Evergreen.V147.Slack
import Evergreen.V147.TextEditor
import Evergreen.V147.Thread
import Evergreen.V147.User
import Evergreen.V147.UserAgent
import Evergreen.V147.UserSession
import Evergreen.V147.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members : Evergreen.V147.NonemptySet.NonemptySet (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId)
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V147.Message.Message Evergreen.V147.Id.ChannelMessageId (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V147.Discord.PartialUser
        , icon : Maybe Evergreen.V147.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V147.Discord.User
        , linkedTo : Evergreen.V147.Id.Id Evergreen.V147.Id.UserId
        , icon : Maybe Evergreen.V147.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V147.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V147.Discord.User
        , linkedTo : Evergreen.V147.Id.Id Evergreen.V147.Id.UserId
        , icon : Maybe Evergreen.V147.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V147.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V147.Message.Message Evergreen.V147.Id.ChannelMessageId (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V147.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId) AdminData_DiscordChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V147.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V147.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V147.Id.Id Evergreen.V147.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V147.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V147.Log.Log
    , isHidden : Bool
    }


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V147.Id.Id Evergreen.V147.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V147.Id.Id Evergreen.V147.Id.UserId
    , name : Evergreen.V147.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V147.Message.MessageState Evergreen.V147.Id.ChannelMessageId (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId))
    , visibleMessages : Evergreen.V147.VisibleMessages.VisibleMessages Evergreen.V147.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) (Evergreen.V147.Thread.LastTypedAt Evergreen.V147.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) Evergreen.V147.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V147.Id.Id Evergreen.V147.Id.UserId
    , name : Evergreen.V147.GuildName.GuildName
    , icon : Maybe Evergreen.V147.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V147.Id.Id Evergreen.V147.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V147.SecretId.SecretId Evergreen.V147.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V147.Id.Id Evergreen.V147.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V147.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V147.Message.MessageState Evergreen.V147.Id.ChannelMessageId (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId))
    , visibleMessages : Evergreen.V147.VisibleMessages.VisibleMessages Evergreen.V147.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Evergreen.V147.Thread.LastTypedAt Evergreen.V147.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) Evergreen.V147.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V147.GuildName.GuildName
    , icon : Maybe Evergreen.V147.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V147.NonemptyDict.NonemptyDict (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) Evergreen.V147.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V147.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V147.Pagination.Pagination LogWithTime
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V147.UserSession.UserSession
    , user : Evergreen.V147.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) Evergreen.V147.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) Evergreen.V147.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) Evergreen.V147.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V147.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) Evergreen.V147.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId) Evergreen.V147.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V147.SessionIdHash.SessionIdHash Evergreen.V147.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V147.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V147.Id.Id Evergreen.V147.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V147.Id.Id Evergreen.V147.Id.UserId
    , name : Evergreen.V147.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V147.Message.Message Evergreen.V147.Id.ChannelMessageId (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) (Evergreen.V147.Thread.LastTypedAt Evergreen.V147.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) Evergreen.V147.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V147.Id.Id Evergreen.V147.Id.UserId
    , name : Evergreen.V147.GuildName.GuildName
    , icon : Maybe Evergreen.V147.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V147.Id.Id Evergreen.V147.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V147.SecretId.SecretId Evergreen.V147.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V147.Id.Id Evergreen.V147.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V147.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V147.Message.Message Evergreen.V147.Id.ChannelMessageId (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Evergreen.V147.Thread.LastTypedAt Evergreen.V147.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V147.OneToOne.OneToOne (Evergreen.V147.Discord.Id Evergreen.V147.Discord.MessageId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) Evergreen.V147.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V147.GuildName.GuildName
    , icon : Maybe Evergreen.V147.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId
    }
