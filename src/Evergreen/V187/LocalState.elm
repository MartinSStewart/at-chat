module Evergreen.V187.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V187.ChannelDescription
import Evergreen.V187.ChannelName
import Evergreen.V187.Discord
import Evergreen.V187.DiscordUserData
import Evergreen.V187.DmChannel
import Evergreen.V187.FileStatus
import Evergreen.V187.GuildName
import Evergreen.V187.Id
import Evergreen.V187.Log
import Evergreen.V187.MembersAndOwner
import Evergreen.V187.Message
import Evergreen.V187.NonemptyDict
import Evergreen.V187.OneToOne
import Evergreen.V187.Pagination
import Evergreen.V187.SecretId
import Evergreen.V187.SessionIdHash
import Evergreen.V187.Slack
import Evergreen.V187.TextEditor
import Evergreen.V187.Thread
import Evergreen.V187.ToBackendLog
import Evergreen.V187.User
import Evergreen.V187.UserAgent
import Evergreen.V187.UserSession
import Evergreen.V187.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V187.NonemptyDict.NonemptyDict
            (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V187.Message.Message Evergreen.V187.Id.ChannelMessageId (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V187.Discord.PartialUser
        , icon : Maybe Evergreen.V187.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V187.Discord.User
        , linkedTo : Evergreen.V187.Id.Id Evergreen.V187.Id.UserId
        , icon : Maybe Evergreen.V187.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V187.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V187.Discord.User
        , linkedTo : Evergreen.V187.Id.Id Evergreen.V187.Id.UserId
        , icon : Maybe Evergreen.V187.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V187.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V187.Message.Message Evergreen.V187.Id.ChannelMessageId (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V187.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V187.MembersAndOwner.MembersAndOwner
            (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V187.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V187.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V187.Id.Id Evergreen.V187.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V187.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V187.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V187.Id.Id Evergreen.V187.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V187.Id.Id Evergreen.V187.Id.UserId
    , name : Evergreen.V187.ChannelName.ChannelName
    , description : Evergreen.V187.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V187.Message.MessageState Evergreen.V187.Id.ChannelMessageId (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId))
    , visibleMessages : Evergreen.V187.VisibleMessages.VisibleMessages Evergreen.V187.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) (Evergreen.V187.Thread.LastTypedAt Evergreen.V187.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) Evergreen.V187.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V187.Id.Id Evergreen.V187.Id.UserId
    , name : Evergreen.V187.GuildName.GuildName
    , icon : Maybe Evergreen.V187.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V187.MembersAndOwner.MembersAndOwner
            (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V187.SecretId.SecretId Evergreen.V187.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V187.Id.Id Evergreen.V187.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V187.ChannelName.ChannelName
    , description : Evergreen.V187.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V187.Message.MessageState Evergreen.V187.Id.ChannelMessageId (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId))
    , visibleMessages : Evergreen.V187.VisibleMessages.VisibleMessages Evergreen.V187.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Evergreen.V187.Thread.LastTypedAt Evergreen.V187.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) Evergreen.V187.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V187.GuildName.GuildName
    , icon : Maybe Evergreen.V187.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V187.MembersAndOwner.MembersAndOwner
            (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V187.NonemptyDict.NonemptyDict (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) Evergreen.V187.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V187.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V187.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V187.SessionIdHash.SessionIdHash (Evergreen.V187.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V187.ToBackendLog.ToBackendLogData
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V187.UserSession.UserSession
    , user : Evergreen.V187.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) Evergreen.V187.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) Evergreen.V187.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) Evergreen.V187.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V187.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) Evergreen.V187.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId) Evergreen.V187.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V187.SessionIdHash.SessionIdHash Evergreen.V187.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V187.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V187.Id.Id Evergreen.V187.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V187.Id.Id Evergreen.V187.Id.UserId
    , name : Evergreen.V187.ChannelName.ChannelName
    , description : Evergreen.V187.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V187.Message.Message Evergreen.V187.Id.ChannelMessageId (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) (Evergreen.V187.Thread.LastTypedAt Evergreen.V187.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) Evergreen.V187.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V187.Id.Id Evergreen.V187.Id.UserId
    , name : Evergreen.V187.GuildName.GuildName
    , icon : Maybe Evergreen.V187.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V187.MembersAndOwner.MembersAndOwner
            (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V187.SecretId.SecretId Evergreen.V187.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V187.Id.Id Evergreen.V187.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V187.ChannelName.ChannelName
    , description : Evergreen.V187.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V187.Message.Message Evergreen.V187.Id.ChannelMessageId (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Evergreen.V187.Thread.LastTypedAt Evergreen.V187.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V187.OneToOne.OneToOne (Evergreen.V187.Discord.Id Evergreen.V187.Discord.MessageId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) Evergreen.V187.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V187.GuildName.GuildName
    , icon : Maybe Evergreen.V187.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V187.MembersAndOwner.MembersAndOwner
            (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }
