module Evergreen.V162.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V162.ChannelDescription
import Evergreen.V162.ChannelName
import Evergreen.V162.Discord
import Evergreen.V162.DiscordUserData
import Evergreen.V162.DmChannel
import Evergreen.V162.FileStatus
import Evergreen.V162.GuildName
import Evergreen.V162.Id
import Evergreen.V162.Log
import Evergreen.V162.Message
import Evergreen.V162.NonemptyDict
import Evergreen.V162.OneToOne
import Evergreen.V162.Pagination
import Evergreen.V162.SecretId
import Evergreen.V162.SessionIdHash
import Evergreen.V162.Slack
import Evergreen.V162.TextEditor
import Evergreen.V162.Thread
import Evergreen.V162.User
import Evergreen.V162.UserAgent
import Evergreen.V162.UserSession
import Evergreen.V162.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V162.NonemptyDict.NonemptyDict
            (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V162.Message.Message Evergreen.V162.Id.ChannelMessageId (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V162.Discord.PartialUser
        , icon : Maybe Evergreen.V162.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V162.Discord.User
        , linkedTo : Evergreen.V162.Id.Id Evergreen.V162.Id.UserId
        , icon : Maybe Evergreen.V162.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V162.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V162.Discord.User
        , linkedTo : Evergreen.V162.Id.Id Evergreen.V162.Id.UserId
        , icon : Maybe Evergreen.V162.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V162.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V162.Message.Message Evergreen.V162.Id.ChannelMessageId (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V162.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V162.Discord.Id Evergreen.V162.Discord.ChannelId) AdminData_DiscordChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V162.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V162.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V162.Id.Id Evergreen.V162.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V162.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V162.Discord.Id Evergreen.V162.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V162.Discord.Id Evergreen.V162.Discord.GuildId) (Evergreen.V162.Discord.Id Evergreen.V162.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V162.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V162.Id.Id Evergreen.V162.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V162.Id.Id Evergreen.V162.Id.UserId
    , name : Evergreen.V162.ChannelName.ChannelName
    , description : Evergreen.V162.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V162.Message.MessageState Evergreen.V162.Id.ChannelMessageId (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId))
    , visibleMessages : Evergreen.V162.VisibleMessages.VisibleMessages Evergreen.V162.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId) (Evergreen.V162.Thread.LastTypedAt Evergreen.V162.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelMessageId) Evergreen.V162.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V162.Id.Id Evergreen.V162.Id.UserId
    , name : Evergreen.V162.GuildName.GuildName
    , icon : Maybe Evergreen.V162.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V162.Id.Id Evergreen.V162.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V162.SecretId.SecretId Evergreen.V162.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V162.Id.Id Evergreen.V162.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V162.ChannelName.ChannelName
    , description : Evergreen.V162.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V162.Message.MessageState Evergreen.V162.Id.ChannelMessageId (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId))
    , visibleMessages : Evergreen.V162.VisibleMessages.VisibleMessages Evergreen.V162.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId) (Evergreen.V162.Thread.LastTypedAt Evergreen.V162.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelMessageId) Evergreen.V162.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V162.GuildName.GuildName
    , icon : Maybe Evergreen.V162.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V162.Discord.Id Evergreen.V162.Discord.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V162.NonemptyDict.NonemptyDict (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId) Evergreen.V162.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V162.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V162.Discord.Id Evergreen.V162.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V162.Discord.Id Evergreen.V162.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V162.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V162.SessionIdHash.SessionIdHash (Evergreen.V162.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V162.UserSession.UserSession
    , user : Evergreen.V162.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId) Evergreen.V162.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId) Evergreen.V162.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId) Evergreen.V162.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V162.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V162.Discord.Id Evergreen.V162.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId) Evergreen.V162.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V162.Discord.Id Evergreen.V162.Discord.PrivateChannelId) Evergreen.V162.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V162.SessionIdHash.SessionIdHash Evergreen.V162.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V162.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V162.Id.Id Evergreen.V162.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V162.Id.Id Evergreen.V162.Id.UserId
    , name : Evergreen.V162.ChannelName.ChannelName
    , description : Evergreen.V162.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V162.Message.Message Evergreen.V162.Id.ChannelMessageId (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId) (Evergreen.V162.Thread.LastTypedAt Evergreen.V162.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelMessageId) Evergreen.V162.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V162.Id.Id Evergreen.V162.Id.UserId
    , name : Evergreen.V162.GuildName.GuildName
    , icon : Maybe Evergreen.V162.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V162.Id.Id Evergreen.V162.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V162.SecretId.SecretId Evergreen.V162.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V162.Id.Id Evergreen.V162.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V162.ChannelName.ChannelName
    , description : Evergreen.V162.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V162.Message.Message Evergreen.V162.Id.ChannelMessageId (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId) (Evergreen.V162.Thread.LastTypedAt Evergreen.V162.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V162.OneToOne.OneToOne (Evergreen.V162.Discord.Id Evergreen.V162.Discord.MessageId) (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelMessageId) Evergreen.V162.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V162.GuildName.GuildName
    , icon : Maybe Evergreen.V162.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V162.Discord.Id Evergreen.V162.Discord.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId
    }
