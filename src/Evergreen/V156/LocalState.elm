module Evergreen.V156.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V156.ChannelName
import Evergreen.V156.Discord
import Evergreen.V156.DiscordUserData
import Evergreen.V156.DmChannel
import Evergreen.V156.FileStatus
import Evergreen.V156.GuildName
import Evergreen.V156.Id
import Evergreen.V156.Log
import Evergreen.V156.Message
import Evergreen.V156.NonemptyDict
import Evergreen.V156.OneToOne
import Evergreen.V156.Pagination
import Evergreen.V156.SecretId
import Evergreen.V156.SessionIdHash
import Evergreen.V156.Slack
import Evergreen.V156.TextEditor
import Evergreen.V156.Thread
import Evergreen.V156.User
import Evergreen.V156.UserAgent
import Evergreen.V156.UserSession
import Evergreen.V156.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V156.NonemptyDict.NonemptyDict
            (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V156.Message.Message Evergreen.V156.Id.ChannelMessageId (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V156.Discord.PartialUser
        , icon : Maybe Evergreen.V156.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V156.Discord.User
        , linkedTo : Evergreen.V156.Id.Id Evergreen.V156.Id.UserId
        , icon : Maybe Evergreen.V156.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V156.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V156.Discord.User
        , linkedTo : Evergreen.V156.Id.Id Evergreen.V156.Id.UserId
        , icon : Maybe Evergreen.V156.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V156.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V156.Message.Message Evergreen.V156.Id.ChannelMessageId (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V156.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId) AdminData_DiscordChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V156.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V156.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V156.Id.Id Evergreen.V156.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V156.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V156.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V156.Id.Id Evergreen.V156.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V156.Id.Id Evergreen.V156.Id.UserId
    , name : Evergreen.V156.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V156.Message.MessageState Evergreen.V156.Id.ChannelMessageId (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId))
    , visibleMessages : Evergreen.V156.VisibleMessages.VisibleMessages Evergreen.V156.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) (Evergreen.V156.Thread.LastTypedAt Evergreen.V156.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) Evergreen.V156.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V156.Id.Id Evergreen.V156.Id.UserId
    , name : Evergreen.V156.GuildName.GuildName
    , icon : Maybe Evergreen.V156.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V156.Id.Id Evergreen.V156.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V156.SecretId.SecretId Evergreen.V156.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V156.Id.Id Evergreen.V156.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V156.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V156.Message.MessageState Evergreen.V156.Id.ChannelMessageId (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId))
    , visibleMessages : Evergreen.V156.VisibleMessages.VisibleMessages Evergreen.V156.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Evergreen.V156.Thread.LastTypedAt Evergreen.V156.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) Evergreen.V156.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V156.GuildName.GuildName
    , icon : Maybe Evergreen.V156.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V156.NonemptyDict.NonemptyDict (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) Evergreen.V156.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V156.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V156.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V156.SessionIdHash.SessionIdHash (Evergreen.V156.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V156.UserSession.UserSession
    , user : Evergreen.V156.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) Evergreen.V156.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) Evergreen.V156.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) Evergreen.V156.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V156.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) Evergreen.V156.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId) Evergreen.V156.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V156.SessionIdHash.SessionIdHash Evergreen.V156.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V156.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V156.Id.Id Evergreen.V156.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V156.Id.Id Evergreen.V156.Id.UserId
    , name : Evergreen.V156.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V156.Message.Message Evergreen.V156.Id.ChannelMessageId (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) (Evergreen.V156.Thread.LastTypedAt Evergreen.V156.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) Evergreen.V156.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V156.Id.Id Evergreen.V156.Id.UserId
    , name : Evergreen.V156.GuildName.GuildName
    , icon : Maybe Evergreen.V156.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V156.Id.Id Evergreen.V156.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V156.SecretId.SecretId Evergreen.V156.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V156.Id.Id Evergreen.V156.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V156.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V156.Message.Message Evergreen.V156.Id.ChannelMessageId (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Evergreen.V156.Thread.LastTypedAt Evergreen.V156.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V156.OneToOne.OneToOne (Evergreen.V156.Discord.Id Evergreen.V156.Discord.MessageId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) Evergreen.V156.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V156.GuildName.GuildName
    , icon : Maybe Evergreen.V156.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId
    }
