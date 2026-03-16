module Evergreen.V154.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V154.ChannelName
import Evergreen.V154.Discord
import Evergreen.V154.DiscordUserData
import Evergreen.V154.DmChannel
import Evergreen.V154.FileStatus
import Evergreen.V154.GuildName
import Evergreen.V154.Id
import Evergreen.V154.Log
import Evergreen.V154.Message
import Evergreen.V154.NonemptyDict
import Evergreen.V154.OneToOne
import Evergreen.V154.Pagination
import Evergreen.V154.SecretId
import Evergreen.V154.SessionIdHash
import Evergreen.V154.Slack
import Evergreen.V154.TextEditor
import Evergreen.V154.Thread
import Evergreen.V154.User
import Evergreen.V154.UserAgent
import Evergreen.V154.UserSession
import Evergreen.V154.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V154.NonemptyDict.NonemptyDict
            (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V154.Message.Message Evergreen.V154.Id.ChannelMessageId (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V154.Discord.PartialUser
        , icon : Maybe Evergreen.V154.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V154.Discord.User
        , linkedTo : Evergreen.V154.Id.Id Evergreen.V154.Id.UserId
        , icon : Maybe Evergreen.V154.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V154.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V154.Discord.User
        , linkedTo : Evergreen.V154.Id.Id Evergreen.V154.Id.UserId
        , icon : Maybe Evergreen.V154.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V154.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V154.Message.Message Evergreen.V154.Id.ChannelMessageId (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V154.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId) AdminData_DiscordChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V154.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V154.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V154.Id.Id Evergreen.V154.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V154.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V154.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V154.Id.Id Evergreen.V154.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V154.Id.Id Evergreen.V154.Id.UserId
    , name : Evergreen.V154.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V154.Message.MessageState Evergreen.V154.Id.ChannelMessageId (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId))
    , visibleMessages : Evergreen.V154.VisibleMessages.VisibleMessages Evergreen.V154.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) (Evergreen.V154.Thread.LastTypedAt Evergreen.V154.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) Evergreen.V154.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V154.Id.Id Evergreen.V154.Id.UserId
    , name : Evergreen.V154.GuildName.GuildName
    , icon : Maybe Evergreen.V154.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V154.Id.Id Evergreen.V154.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V154.SecretId.SecretId Evergreen.V154.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V154.Id.Id Evergreen.V154.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V154.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V154.Message.MessageState Evergreen.V154.Id.ChannelMessageId (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId))
    , visibleMessages : Evergreen.V154.VisibleMessages.VisibleMessages Evergreen.V154.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Evergreen.V154.Thread.LastTypedAt Evergreen.V154.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) Evergreen.V154.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V154.GuildName.GuildName
    , icon : Maybe Evergreen.V154.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V154.NonemptyDict.NonemptyDict (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) Evergreen.V154.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V154.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V154.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V154.SessionIdHash.SessionIdHash (Evergreen.V154.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V154.UserSession.UserSession
    , user : Evergreen.V154.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) Evergreen.V154.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) Evergreen.V154.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) Evergreen.V154.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V154.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) Evergreen.V154.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId) Evergreen.V154.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V154.SessionIdHash.SessionIdHash Evergreen.V154.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V154.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V154.Id.Id Evergreen.V154.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V154.Id.Id Evergreen.V154.Id.UserId
    , name : Evergreen.V154.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V154.Message.Message Evergreen.V154.Id.ChannelMessageId (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) (Evergreen.V154.Thread.LastTypedAt Evergreen.V154.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) Evergreen.V154.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V154.Id.Id Evergreen.V154.Id.UserId
    , name : Evergreen.V154.GuildName.GuildName
    , icon : Maybe Evergreen.V154.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V154.Id.Id Evergreen.V154.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V154.SecretId.SecretId Evergreen.V154.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V154.Id.Id Evergreen.V154.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V154.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V154.Message.Message Evergreen.V154.Id.ChannelMessageId (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Evergreen.V154.Thread.LastTypedAt Evergreen.V154.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V154.OneToOne.OneToOne (Evergreen.V154.Discord.Id Evergreen.V154.Discord.MessageId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) Evergreen.V154.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V154.GuildName.GuildName
    , icon : Maybe Evergreen.V154.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId
    }
