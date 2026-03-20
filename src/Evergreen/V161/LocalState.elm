module Evergreen.V161.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V161.ChannelDescription
import Evergreen.V161.ChannelName
import Evergreen.V161.Discord
import Evergreen.V161.DiscordUserData
import Evergreen.V161.DmChannel
import Evergreen.V161.FileStatus
import Evergreen.V161.GuildName
import Evergreen.V161.Id
import Evergreen.V161.Log
import Evergreen.V161.Message
import Evergreen.V161.NonemptyDict
import Evergreen.V161.OneToOne
import Evergreen.V161.Pagination
import Evergreen.V161.SecretId
import Evergreen.V161.SessionIdHash
import Evergreen.V161.Slack
import Evergreen.V161.TextEditor
import Evergreen.V161.Thread
import Evergreen.V161.User
import Evergreen.V161.UserAgent
import Evergreen.V161.UserSession
import Evergreen.V161.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V161.NonemptyDict.NonemptyDict
            (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V161.Message.Message Evergreen.V161.Id.ChannelMessageId (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V161.Discord.PartialUser
        , icon : Maybe Evergreen.V161.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V161.Discord.User
        , linkedTo : Evergreen.V161.Id.Id Evergreen.V161.Id.UserId
        , icon : Maybe Evergreen.V161.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V161.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V161.Discord.User
        , linkedTo : Evergreen.V161.Id.Id Evergreen.V161.Id.UserId
        , icon : Maybe Evergreen.V161.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V161.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V161.Message.Message Evergreen.V161.Id.ChannelMessageId (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V161.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) AdminData_DiscordChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V161.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V161.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V161.Id.Id Evergreen.V161.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V161.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V161.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V161.Id.Id Evergreen.V161.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V161.Id.Id Evergreen.V161.Id.UserId
    , name : Evergreen.V161.ChannelName.ChannelName
    , description : Evergreen.V161.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V161.Message.MessageState Evergreen.V161.Id.ChannelMessageId (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId))
    , visibleMessages : Evergreen.V161.VisibleMessages.VisibleMessages Evergreen.V161.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) (Evergreen.V161.Thread.LastTypedAt Evergreen.V161.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) Evergreen.V161.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V161.Id.Id Evergreen.V161.Id.UserId
    , name : Evergreen.V161.GuildName.GuildName
    , icon : Maybe Evergreen.V161.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V161.Id.Id Evergreen.V161.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V161.SecretId.SecretId Evergreen.V161.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V161.Id.Id Evergreen.V161.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V161.ChannelName.ChannelName
    , description : Evergreen.V161.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V161.Message.MessageState Evergreen.V161.Id.ChannelMessageId (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId))
    , visibleMessages : Evergreen.V161.VisibleMessages.VisibleMessages Evergreen.V161.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Evergreen.V161.Thread.LastTypedAt Evergreen.V161.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) Evergreen.V161.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V161.GuildName.GuildName
    , icon : Maybe Evergreen.V161.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V161.NonemptyDict.NonemptyDict (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) Evergreen.V161.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V161.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V161.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V161.SessionIdHash.SessionIdHash (Evergreen.V161.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V161.UserSession.UserSession
    , user : Evergreen.V161.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) Evergreen.V161.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) Evergreen.V161.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) Evergreen.V161.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V161.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) Evergreen.V161.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId) Evergreen.V161.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V161.SessionIdHash.SessionIdHash Evergreen.V161.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V161.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V161.Id.Id Evergreen.V161.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V161.Id.Id Evergreen.V161.Id.UserId
    , name : Evergreen.V161.ChannelName.ChannelName
    , description : Evergreen.V161.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V161.Message.Message Evergreen.V161.Id.ChannelMessageId (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) (Evergreen.V161.Thread.LastTypedAt Evergreen.V161.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) Evergreen.V161.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V161.Id.Id Evergreen.V161.Id.UserId
    , name : Evergreen.V161.GuildName.GuildName
    , icon : Maybe Evergreen.V161.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V161.Id.Id Evergreen.V161.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V161.SecretId.SecretId Evergreen.V161.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V161.Id.Id Evergreen.V161.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V161.ChannelName.ChannelName
    , description : Evergreen.V161.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V161.Message.Message Evergreen.V161.Id.ChannelMessageId (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Evergreen.V161.Thread.LastTypedAt Evergreen.V161.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V161.OneToOne.OneToOne (Evergreen.V161.Discord.Id Evergreen.V161.Discord.MessageId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) Evergreen.V161.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V161.GuildName.GuildName
    , icon : Maybe Evergreen.V161.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId
    }
