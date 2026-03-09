module Evergreen.V149.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V149.ChannelName
import Evergreen.V149.Discord
import Evergreen.V149.DiscordUserData
import Evergreen.V149.DmChannel
import Evergreen.V149.FileStatus
import Evergreen.V149.GuildName
import Evergreen.V149.Id
import Evergreen.V149.Log
import Evergreen.V149.Message
import Evergreen.V149.NonemptyDict
import Evergreen.V149.NonemptySet
import Evergreen.V149.OneToOne
import Evergreen.V149.Pagination
import Evergreen.V149.SecretId
import Evergreen.V149.SessionIdHash
import Evergreen.V149.Slack
import Evergreen.V149.TextEditor
import Evergreen.V149.Thread
import Evergreen.V149.User
import Evergreen.V149.UserAgent
import Evergreen.V149.UserSession
import Evergreen.V149.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members : Evergreen.V149.NonemptySet.NonemptySet (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId)
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V149.Message.Message Evergreen.V149.Id.ChannelMessageId (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V149.Discord.PartialUser
        , icon : Maybe Evergreen.V149.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V149.Discord.User
        , linkedTo : Evergreen.V149.Id.Id Evergreen.V149.Id.UserId
        , icon : Maybe Evergreen.V149.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V149.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V149.Discord.User
        , linkedTo : Evergreen.V149.Id.Id Evergreen.V149.Id.UserId
        , icon : Maybe Evergreen.V149.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V149.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V149.Message.Message Evergreen.V149.Id.ChannelMessageId (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V149.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId) AdminData_DiscordChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V149.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V149.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V149.Id.Id Evergreen.V149.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V149.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V149.Log.Log
    , isHidden : Bool
    }


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V149.Id.Id Evergreen.V149.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V149.Id.Id Evergreen.V149.Id.UserId
    , name : Evergreen.V149.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V149.Message.MessageState Evergreen.V149.Id.ChannelMessageId (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId))
    , visibleMessages : Evergreen.V149.VisibleMessages.VisibleMessages Evergreen.V149.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) (Evergreen.V149.Thread.LastTypedAt Evergreen.V149.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) Evergreen.V149.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V149.Id.Id Evergreen.V149.Id.UserId
    , name : Evergreen.V149.GuildName.GuildName
    , icon : Maybe Evergreen.V149.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V149.Id.Id Evergreen.V149.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V149.SecretId.SecretId Evergreen.V149.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V149.Id.Id Evergreen.V149.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V149.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V149.Message.MessageState Evergreen.V149.Id.ChannelMessageId (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId))
    , visibleMessages : Evergreen.V149.VisibleMessages.VisibleMessages Evergreen.V149.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Evergreen.V149.Thread.LastTypedAt Evergreen.V149.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) Evergreen.V149.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V149.GuildName.GuildName
    , icon : Maybe Evergreen.V149.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V149.NonemptyDict.NonemptyDict (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) Evergreen.V149.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V149.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V149.Pagination.Pagination LogWithTime
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V149.UserSession.UserSession
    , user : Evergreen.V149.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) Evergreen.V149.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) Evergreen.V149.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) Evergreen.V149.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V149.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) Evergreen.V149.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId) Evergreen.V149.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V149.SessionIdHash.SessionIdHash Evergreen.V149.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V149.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V149.Id.Id Evergreen.V149.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V149.Id.Id Evergreen.V149.Id.UserId
    , name : Evergreen.V149.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V149.Message.Message Evergreen.V149.Id.ChannelMessageId (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) (Evergreen.V149.Thread.LastTypedAt Evergreen.V149.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) Evergreen.V149.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V149.Id.Id Evergreen.V149.Id.UserId
    , name : Evergreen.V149.GuildName.GuildName
    , icon : Maybe Evergreen.V149.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V149.Id.Id Evergreen.V149.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V149.SecretId.SecretId Evergreen.V149.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V149.Id.Id Evergreen.V149.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V149.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V149.Message.Message Evergreen.V149.Id.ChannelMessageId (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Evergreen.V149.Thread.LastTypedAt Evergreen.V149.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V149.OneToOne.OneToOne (Evergreen.V149.Discord.Id Evergreen.V149.Discord.MessageId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) Evergreen.V149.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V149.GuildName.GuildName
    , icon : Maybe Evergreen.V149.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId
    }
