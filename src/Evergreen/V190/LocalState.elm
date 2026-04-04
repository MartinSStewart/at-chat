module Evergreen.V190.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V190.ChannelDescription
import Evergreen.V190.ChannelName
import Evergreen.V190.Discord
import Evergreen.V190.DiscordUserData
import Evergreen.V190.DmChannel
import Evergreen.V190.FileStatus
import Evergreen.V190.GuildName
import Evergreen.V190.Id
import Evergreen.V190.Log
import Evergreen.V190.MembersAndOwner
import Evergreen.V190.Message
import Evergreen.V190.NonemptyDict
import Evergreen.V190.OneToOne
import Evergreen.V190.Pagination
import Evergreen.V190.SecretId
import Evergreen.V190.SessionIdHash
import Evergreen.V190.Slack
import Evergreen.V190.TextEditor
import Evergreen.V190.Thread
import Evergreen.V190.ToBackendLog
import Evergreen.V190.User
import Evergreen.V190.UserAgent
import Evergreen.V190.UserSession
import Evergreen.V190.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V190.NonemptyDict.NonemptyDict
            (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V190.Message.Message Evergreen.V190.Id.ChannelMessageId (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V190.Discord.PartialUser
        , icon : Maybe Evergreen.V190.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V190.Discord.User
        , linkedTo : Evergreen.V190.Id.Id Evergreen.V190.Id.UserId
        , icon : Maybe Evergreen.V190.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V190.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V190.Discord.User
        , linkedTo : Evergreen.V190.Id.Id Evergreen.V190.Id.UserId
        , icon : Maybe Evergreen.V190.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V190.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V190.Message.Message Evergreen.V190.Id.ChannelMessageId (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V190.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V190.MembersAndOwner.MembersAndOwner
            (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V190.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V190.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V190.Id.Id Evergreen.V190.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V190.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V190.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V190.Id.Id Evergreen.V190.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V190.Id.Id Evergreen.V190.Id.UserId
    , name : Evergreen.V190.ChannelName.ChannelName
    , description : Evergreen.V190.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V190.Message.MessageState Evergreen.V190.Id.ChannelMessageId (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId))
    , visibleMessages : Evergreen.V190.VisibleMessages.VisibleMessages Evergreen.V190.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) (Evergreen.V190.Thread.LastTypedAt Evergreen.V190.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) Evergreen.V190.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V190.Id.Id Evergreen.V190.Id.UserId
    , name : Evergreen.V190.GuildName.GuildName
    , icon : Maybe Evergreen.V190.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V190.MembersAndOwner.MembersAndOwner
            (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V190.SecretId.SecretId Evergreen.V190.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V190.Id.Id Evergreen.V190.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V190.ChannelName.ChannelName
    , description : Evergreen.V190.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V190.Message.MessageState Evergreen.V190.Id.ChannelMessageId (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId))
    , visibleMessages : Evergreen.V190.VisibleMessages.VisibleMessages Evergreen.V190.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Evergreen.V190.Thread.LastTypedAt Evergreen.V190.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) Evergreen.V190.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V190.GuildName.GuildName
    , icon : Maybe Evergreen.V190.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V190.MembersAndOwner.MembersAndOwner
            (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V190.NonemptyDict.NonemptyDict (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) Evergreen.V190.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V190.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V190.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V190.SessionIdHash.SessionIdHash (Evergreen.V190.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V190.ToBackendLog.ToBackendLogData
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V190.UserSession.UserSession
    , user : Evergreen.V190.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) Evergreen.V190.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) Evergreen.V190.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) Evergreen.V190.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V190.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) Evergreen.V190.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId) Evergreen.V190.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V190.SessionIdHash.SessionIdHash Evergreen.V190.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V190.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V190.Id.Id Evergreen.V190.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V190.Id.Id Evergreen.V190.Id.UserId
    , name : Evergreen.V190.ChannelName.ChannelName
    , description : Evergreen.V190.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V190.Message.Message Evergreen.V190.Id.ChannelMessageId (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) (Evergreen.V190.Thread.LastTypedAt Evergreen.V190.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) Evergreen.V190.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V190.Id.Id Evergreen.V190.Id.UserId
    , name : Evergreen.V190.GuildName.GuildName
    , icon : Maybe Evergreen.V190.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V190.MembersAndOwner.MembersAndOwner
            (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V190.SecretId.SecretId Evergreen.V190.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V190.Id.Id Evergreen.V190.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V190.ChannelName.ChannelName
    , description : Evergreen.V190.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V190.Message.Message Evergreen.V190.Id.ChannelMessageId (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Evergreen.V190.Thread.LastTypedAt Evergreen.V190.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V190.OneToOne.OneToOne (Evergreen.V190.Discord.Id Evergreen.V190.Discord.MessageId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) Evergreen.V190.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V190.GuildName.GuildName
    , icon : Maybe Evergreen.V190.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V190.MembersAndOwner.MembersAndOwner
            (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }
