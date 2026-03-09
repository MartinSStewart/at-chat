module Evergreen.V146.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V146.ChannelName
import Evergreen.V146.Discord
import Evergreen.V146.DiscordUserData
import Evergreen.V146.DmChannel
import Evergreen.V146.FileStatus
import Evergreen.V146.GuildName
import Evergreen.V146.Id
import Evergreen.V146.Log
import Evergreen.V146.Message
import Evergreen.V146.NonemptyDict
import Evergreen.V146.NonemptySet
import Evergreen.V146.OneToOne
import Evergreen.V146.Pagination
import Evergreen.V146.SecretId
import Evergreen.V146.SessionIdHash
import Evergreen.V146.Slack
import Evergreen.V146.TextEditor
import Evergreen.V146.Thread
import Evergreen.V146.User
import Evergreen.V146.UserAgent
import Evergreen.V146.UserSession
import Evergreen.V146.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members : Evergreen.V146.NonemptySet.NonemptySet (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId)
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V146.Message.Message Evergreen.V146.Id.ChannelMessageId (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V146.Discord.PartialUser
        , icon : Maybe Evergreen.V146.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V146.Discord.User
        , linkedTo : Evergreen.V146.Id.Id Evergreen.V146.Id.UserId
        , icon : Maybe Evergreen.V146.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V146.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V146.Discord.User
        , linkedTo : Evergreen.V146.Id.Id Evergreen.V146.Id.UserId
        , icon : Maybe Evergreen.V146.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V146.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V146.Message.Message Evergreen.V146.Id.ChannelMessageId (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V146.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId) AdminData_DiscordChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V146.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V146.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V146.Id.Id Evergreen.V146.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V146.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V146.Log.Log
    , isHidden : Bool
    }


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V146.Id.Id Evergreen.V146.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V146.Id.Id Evergreen.V146.Id.UserId
    , name : Evergreen.V146.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V146.Message.MessageState Evergreen.V146.Id.ChannelMessageId (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId))
    , visibleMessages : Evergreen.V146.VisibleMessages.VisibleMessages Evergreen.V146.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) (Evergreen.V146.Thread.LastTypedAt Evergreen.V146.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) Evergreen.V146.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V146.Id.Id Evergreen.V146.Id.UserId
    , name : Evergreen.V146.GuildName.GuildName
    , icon : Maybe Evergreen.V146.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V146.Id.Id Evergreen.V146.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V146.SecretId.SecretId Evergreen.V146.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V146.Id.Id Evergreen.V146.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V146.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V146.Message.MessageState Evergreen.V146.Id.ChannelMessageId (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId))
    , visibleMessages : Evergreen.V146.VisibleMessages.VisibleMessages Evergreen.V146.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Evergreen.V146.Thread.LastTypedAt Evergreen.V146.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) Evergreen.V146.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V146.GuildName.GuildName
    , icon : Maybe Evergreen.V146.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V146.NonemptyDict.NonemptyDict (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) Evergreen.V146.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V146.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V146.Pagination.Pagination LogWithTime
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V146.UserSession.UserSession
    , user : Evergreen.V146.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) Evergreen.V146.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) Evergreen.V146.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) Evergreen.V146.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V146.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) Evergreen.V146.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId) Evergreen.V146.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V146.SessionIdHash.SessionIdHash Evergreen.V146.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V146.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V146.Id.Id Evergreen.V146.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V146.Id.Id Evergreen.V146.Id.UserId
    , name : Evergreen.V146.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V146.Message.Message Evergreen.V146.Id.ChannelMessageId (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) (Evergreen.V146.Thread.LastTypedAt Evergreen.V146.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) Evergreen.V146.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V146.Id.Id Evergreen.V146.Id.UserId
    , name : Evergreen.V146.GuildName.GuildName
    , icon : Maybe Evergreen.V146.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V146.Id.Id Evergreen.V146.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V146.SecretId.SecretId Evergreen.V146.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V146.Id.Id Evergreen.V146.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V146.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V146.Message.Message Evergreen.V146.Id.ChannelMessageId (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Evergreen.V146.Thread.LastTypedAt Evergreen.V146.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V146.OneToOne.OneToOne (Evergreen.V146.Discord.Id Evergreen.V146.Discord.MessageId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) Evergreen.V146.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V146.GuildName.GuildName
    , icon : Maybe Evergreen.V146.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId
    }
