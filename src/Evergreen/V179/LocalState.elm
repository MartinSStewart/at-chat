module Evergreen.V179.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V179.ChannelDescription
import Evergreen.V179.ChannelName
import Evergreen.V179.Discord
import Evergreen.V179.DiscordUserData
import Evergreen.V179.DmChannel
import Evergreen.V179.FileStatus
import Evergreen.V179.GuildName
import Evergreen.V179.Id
import Evergreen.V179.Log
import Evergreen.V179.MembersAndOwner
import Evergreen.V179.Message
import Evergreen.V179.NonemptyDict
import Evergreen.V179.OneToOne
import Evergreen.V179.Pagination
import Evergreen.V179.SecretId
import Evergreen.V179.SessionIdHash
import Evergreen.V179.Slack
import Evergreen.V179.TextEditor
import Evergreen.V179.Thread
import Evergreen.V179.User
import Evergreen.V179.UserAgent
import Evergreen.V179.UserSession
import Evergreen.V179.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V179.NonemptyDict.NonemptyDict
            (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V179.Message.Message Evergreen.V179.Id.ChannelMessageId (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V179.Discord.PartialUser
        , icon : Maybe Evergreen.V179.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V179.Discord.User
        , linkedTo : Evergreen.V179.Id.Id Evergreen.V179.Id.UserId
        , icon : Maybe Evergreen.V179.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V179.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V179.Discord.User
        , linkedTo : Evergreen.V179.Id.Id Evergreen.V179.Id.UserId
        , icon : Maybe Evergreen.V179.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V179.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V179.Message.Message Evergreen.V179.Id.ChannelMessageId (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V179.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V179.MembersAndOwner.MembersAndOwner
            (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V179.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V179.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V179.Id.Id Evergreen.V179.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V179.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V179.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V179.Id.Id Evergreen.V179.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V179.Id.Id Evergreen.V179.Id.UserId
    , name : Evergreen.V179.ChannelName.ChannelName
    , description : Evergreen.V179.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V179.Message.MessageState Evergreen.V179.Id.ChannelMessageId (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId))
    , visibleMessages : Evergreen.V179.VisibleMessages.VisibleMessages Evergreen.V179.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) (Evergreen.V179.Thread.LastTypedAt Evergreen.V179.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) Evergreen.V179.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V179.Id.Id Evergreen.V179.Id.UserId
    , name : Evergreen.V179.GuildName.GuildName
    , icon : Maybe Evergreen.V179.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V179.MembersAndOwner.MembersAndOwner
            (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V179.SecretId.SecretId Evergreen.V179.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V179.Id.Id Evergreen.V179.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V179.ChannelName.ChannelName
    , description : Evergreen.V179.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V179.Message.MessageState Evergreen.V179.Id.ChannelMessageId (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId))
    , visibleMessages : Evergreen.V179.VisibleMessages.VisibleMessages Evergreen.V179.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Evergreen.V179.Thread.LastTypedAt Evergreen.V179.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) Evergreen.V179.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V179.GuildName.GuildName
    , icon : Maybe Evergreen.V179.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V179.MembersAndOwner.MembersAndOwner
            (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V179.NonemptyDict.NonemptyDict (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) Evergreen.V179.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V179.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V179.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V179.SessionIdHash.SessionIdHash (Evergreen.V179.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V179.UserSession.UserSession
    , user : Evergreen.V179.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) Evergreen.V179.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) Evergreen.V179.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) Evergreen.V179.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V179.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) Evergreen.V179.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId) Evergreen.V179.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V179.SessionIdHash.SessionIdHash Evergreen.V179.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V179.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V179.Id.Id Evergreen.V179.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V179.Id.Id Evergreen.V179.Id.UserId
    , name : Evergreen.V179.ChannelName.ChannelName
    , description : Evergreen.V179.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V179.Message.Message Evergreen.V179.Id.ChannelMessageId (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) (Evergreen.V179.Thread.LastTypedAt Evergreen.V179.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) Evergreen.V179.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V179.Id.Id Evergreen.V179.Id.UserId
    , name : Evergreen.V179.GuildName.GuildName
    , icon : Maybe Evergreen.V179.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V179.MembersAndOwner.MembersAndOwner
            (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V179.SecretId.SecretId Evergreen.V179.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V179.Id.Id Evergreen.V179.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V179.ChannelName.ChannelName
    , description : Evergreen.V179.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V179.Message.Message Evergreen.V179.Id.ChannelMessageId (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Evergreen.V179.Thread.LastTypedAt Evergreen.V179.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V179.OneToOne.OneToOne (Evergreen.V179.Discord.Id Evergreen.V179.Discord.MessageId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) Evergreen.V179.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V179.GuildName.GuildName
    , icon : Maybe Evergreen.V179.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V179.MembersAndOwner.MembersAndOwner
            (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }
