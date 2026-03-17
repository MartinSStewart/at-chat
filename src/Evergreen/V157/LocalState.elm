module Evergreen.V157.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V157.ChannelDescription
import Evergreen.V157.ChannelName
import Evergreen.V157.Discord
import Evergreen.V157.DiscordUserData
import Evergreen.V157.DmChannel
import Evergreen.V157.FileStatus
import Evergreen.V157.GuildName
import Evergreen.V157.Id
import Evergreen.V157.Log
import Evergreen.V157.Message
import Evergreen.V157.NonemptyDict
import Evergreen.V157.OneToOne
import Evergreen.V157.Pagination
import Evergreen.V157.SecretId
import Evergreen.V157.SessionIdHash
import Evergreen.V157.Slack
import Evergreen.V157.TextEditor
import Evergreen.V157.Thread
import Evergreen.V157.User
import Evergreen.V157.UserAgent
import Evergreen.V157.UserSession
import Evergreen.V157.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V157.NonemptyDict.NonemptyDict
            (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V157.Message.Message Evergreen.V157.Id.ChannelMessageId (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V157.Discord.PartialUser
        , icon : Maybe Evergreen.V157.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V157.Discord.User
        , linkedTo : Evergreen.V157.Id.Id Evergreen.V157.Id.UserId
        , icon : Maybe Evergreen.V157.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V157.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V157.Discord.User
        , linkedTo : Evergreen.V157.Id.Id Evergreen.V157.Id.UserId
        , icon : Maybe Evergreen.V157.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V157.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V157.Message.Message Evergreen.V157.Id.ChannelMessageId (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V157.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) AdminData_DiscordChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V157.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V157.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V157.Id.Id Evergreen.V157.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V157.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V157.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V157.Id.Id Evergreen.V157.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V157.Id.Id Evergreen.V157.Id.UserId
    , name : Evergreen.V157.ChannelName.ChannelName
    , description : Evergreen.V157.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V157.Message.MessageState Evergreen.V157.Id.ChannelMessageId (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId))
    , visibleMessages : Evergreen.V157.VisibleMessages.VisibleMessages Evergreen.V157.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) (Evergreen.V157.Thread.LastTypedAt Evergreen.V157.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) Evergreen.V157.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V157.Id.Id Evergreen.V157.Id.UserId
    , name : Evergreen.V157.GuildName.GuildName
    , icon : Maybe Evergreen.V157.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V157.Id.Id Evergreen.V157.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V157.SecretId.SecretId Evergreen.V157.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V157.Id.Id Evergreen.V157.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V157.ChannelName.ChannelName
    , description : Evergreen.V157.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V157.Message.MessageState Evergreen.V157.Id.ChannelMessageId (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId))
    , visibleMessages : Evergreen.V157.VisibleMessages.VisibleMessages Evergreen.V157.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Evergreen.V157.Thread.LastTypedAt Evergreen.V157.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) Evergreen.V157.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V157.GuildName.GuildName
    , icon : Maybe Evergreen.V157.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V157.NonemptyDict.NonemptyDict (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) Evergreen.V157.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V157.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V157.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V157.SessionIdHash.SessionIdHash (Evergreen.V157.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V157.UserSession.UserSession
    , user : Evergreen.V157.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) Evergreen.V157.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) Evergreen.V157.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) Evergreen.V157.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V157.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) Evergreen.V157.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId) Evergreen.V157.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V157.SessionIdHash.SessionIdHash Evergreen.V157.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V157.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V157.Id.Id Evergreen.V157.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V157.Id.Id Evergreen.V157.Id.UserId
    , name : Evergreen.V157.ChannelName.ChannelName
    , description : Evergreen.V157.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V157.Message.Message Evergreen.V157.Id.ChannelMessageId (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) (Evergreen.V157.Thread.LastTypedAt Evergreen.V157.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) Evergreen.V157.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V157.Id.Id Evergreen.V157.Id.UserId
    , name : Evergreen.V157.GuildName.GuildName
    , icon : Maybe Evergreen.V157.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V157.Id.Id Evergreen.V157.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V157.SecretId.SecretId Evergreen.V157.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V157.Id.Id Evergreen.V157.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V157.ChannelName.ChannelName
    , description : Evergreen.V157.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V157.Message.Message Evergreen.V157.Id.ChannelMessageId (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Evergreen.V157.Thread.LastTypedAt Evergreen.V157.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V157.OneToOne.OneToOne (Evergreen.V157.Discord.Id Evergreen.V157.Discord.MessageId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) Evergreen.V157.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V157.GuildName.GuildName
    , icon : Maybe Evergreen.V157.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId
    }
