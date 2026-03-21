module Evergreen.V163.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V163.ChannelDescription
import Evergreen.V163.ChannelName
import Evergreen.V163.Discord
import Evergreen.V163.DiscordUserData
import Evergreen.V163.DmChannel
import Evergreen.V163.FileStatus
import Evergreen.V163.GuildName
import Evergreen.V163.Id
import Evergreen.V163.Log
import Evergreen.V163.Message
import Evergreen.V163.NonemptyDict
import Evergreen.V163.OneToOne
import Evergreen.V163.Pagination
import Evergreen.V163.SecretId
import Evergreen.V163.SessionIdHash
import Evergreen.V163.Slack
import Evergreen.V163.TextEditor
import Evergreen.V163.Thread
import Evergreen.V163.User
import Evergreen.V163.UserAgent
import Evergreen.V163.UserSession
import Evergreen.V163.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V163.NonemptyDict.NonemptyDict
            (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V163.Message.Message Evergreen.V163.Id.ChannelMessageId (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V163.Discord.PartialUser
        , icon : Maybe Evergreen.V163.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V163.Discord.User
        , linkedTo : Evergreen.V163.Id.Id Evergreen.V163.Id.UserId
        , icon : Maybe Evergreen.V163.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V163.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V163.Discord.User
        , linkedTo : Evergreen.V163.Id.Id Evergreen.V163.Id.UserId
        , icon : Maybe Evergreen.V163.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V163.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V163.Message.Message Evergreen.V163.Id.ChannelMessageId (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V163.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V163.Discord.Id Evergreen.V163.Discord.ChannelId) AdminData_DiscordChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V163.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V163.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V163.Id.Id Evergreen.V163.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V163.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V163.Discord.Id Evergreen.V163.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V163.Discord.Id Evergreen.V163.Discord.GuildId) (Evergreen.V163.Discord.Id Evergreen.V163.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V163.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V163.Id.Id Evergreen.V163.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V163.Id.Id Evergreen.V163.Id.UserId
    , name : Evergreen.V163.ChannelName.ChannelName
    , description : Evergreen.V163.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V163.Message.MessageState Evergreen.V163.Id.ChannelMessageId (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId))
    , visibleMessages : Evergreen.V163.VisibleMessages.VisibleMessages Evergreen.V163.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId) (Evergreen.V163.Thread.LastTypedAt Evergreen.V163.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelMessageId) Evergreen.V163.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V163.Id.Id Evergreen.V163.Id.UserId
    , name : Evergreen.V163.GuildName.GuildName
    , icon : Maybe Evergreen.V163.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V163.Id.Id Evergreen.V163.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V163.SecretId.SecretId Evergreen.V163.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V163.Id.Id Evergreen.V163.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V163.ChannelName.ChannelName
    , description : Evergreen.V163.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V163.Message.MessageState Evergreen.V163.Id.ChannelMessageId (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId))
    , visibleMessages : Evergreen.V163.VisibleMessages.VisibleMessages Evergreen.V163.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId) (Evergreen.V163.Thread.LastTypedAt Evergreen.V163.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelMessageId) Evergreen.V163.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V163.GuildName.GuildName
    , icon : Maybe Evergreen.V163.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V163.Discord.Id Evergreen.V163.Discord.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V163.NonemptyDict.NonemptyDict (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId) Evergreen.V163.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V163.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V163.Discord.Id Evergreen.V163.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V163.Discord.Id Evergreen.V163.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V163.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V163.SessionIdHash.SessionIdHash (Evergreen.V163.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V163.UserSession.UserSession
    , user : Evergreen.V163.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId) Evergreen.V163.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId) Evergreen.V163.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId) Evergreen.V163.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V163.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V163.Discord.Id Evergreen.V163.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId) Evergreen.V163.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V163.Discord.Id Evergreen.V163.Discord.PrivateChannelId) Evergreen.V163.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V163.SessionIdHash.SessionIdHash Evergreen.V163.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V163.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V163.Id.Id Evergreen.V163.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V163.Id.Id Evergreen.V163.Id.UserId
    , name : Evergreen.V163.ChannelName.ChannelName
    , description : Evergreen.V163.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V163.Message.Message Evergreen.V163.Id.ChannelMessageId (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId) (Evergreen.V163.Thread.LastTypedAt Evergreen.V163.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelMessageId) Evergreen.V163.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V163.Id.Id Evergreen.V163.Id.UserId
    , name : Evergreen.V163.GuildName.GuildName
    , icon : Maybe Evergreen.V163.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V163.Id.Id Evergreen.V163.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V163.SecretId.SecretId Evergreen.V163.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V163.Id.Id Evergreen.V163.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V163.ChannelName.ChannelName
    , description : Evergreen.V163.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V163.Message.Message Evergreen.V163.Id.ChannelMessageId (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId) (Evergreen.V163.Thread.LastTypedAt Evergreen.V163.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V163.OneToOne.OneToOne (Evergreen.V163.Discord.Id Evergreen.V163.Discord.MessageId) (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelMessageId) Evergreen.V163.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V163.GuildName.GuildName
    , icon : Maybe Evergreen.V163.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V163.Discord.Id Evergreen.V163.Discord.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId
    }
