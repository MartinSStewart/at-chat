module Evergreen.V171.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V171.ChannelDescription
import Evergreen.V171.ChannelName
import Evergreen.V171.Discord
import Evergreen.V171.DiscordUserData
import Evergreen.V171.DmChannel
import Evergreen.V171.FileStatus
import Evergreen.V171.GuildName
import Evergreen.V171.Id
import Evergreen.V171.Log
import Evergreen.V171.MembersAndOwner
import Evergreen.V171.Message
import Evergreen.V171.NonemptyDict
import Evergreen.V171.OneToOne
import Evergreen.V171.Pagination
import Evergreen.V171.SecretId
import Evergreen.V171.SessionIdHash
import Evergreen.V171.Slack
import Evergreen.V171.TextEditor
import Evergreen.V171.Thread
import Evergreen.V171.User
import Evergreen.V171.UserAgent
import Evergreen.V171.UserSession
import Evergreen.V171.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V171.NonemptyDict.NonemptyDict
            (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V171.Message.Message Evergreen.V171.Id.ChannelMessageId (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V171.Discord.PartialUser
        , icon : Maybe Evergreen.V171.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V171.Discord.User
        , linkedTo : Evergreen.V171.Id.Id Evergreen.V171.Id.UserId
        , icon : Maybe Evergreen.V171.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V171.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V171.Discord.User
        , linkedTo : Evergreen.V171.Id.Id Evergreen.V171.Id.UserId
        , icon : Maybe Evergreen.V171.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V171.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V171.Message.Message Evergreen.V171.Id.ChannelMessageId (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V171.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V171.Discord.Id Evergreen.V171.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V171.MembersAndOwner.MembersAndOwner
            (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V171.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V171.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V171.Id.Id Evergreen.V171.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V171.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V171.Discord.Id Evergreen.V171.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V171.Discord.Id Evergreen.V171.Discord.GuildId) (Evergreen.V171.Discord.Id Evergreen.V171.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V171.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V171.Id.Id Evergreen.V171.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V171.Id.Id Evergreen.V171.Id.UserId
    , name : Evergreen.V171.ChannelName.ChannelName
    , description : Evergreen.V171.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V171.Message.MessageState Evergreen.V171.Id.ChannelMessageId (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId))
    , visibleMessages : Evergreen.V171.VisibleMessages.VisibleMessages Evergreen.V171.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId) (Evergreen.V171.Thread.LastTypedAt Evergreen.V171.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelMessageId) Evergreen.V171.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V171.Id.Id Evergreen.V171.Id.UserId
    , name : Evergreen.V171.GuildName.GuildName
    , icon : Maybe Evergreen.V171.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V171.MembersAndOwner.MembersAndOwner
            (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V171.SecretId.SecretId Evergreen.V171.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V171.Id.Id Evergreen.V171.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V171.ChannelName.ChannelName
    , description : Evergreen.V171.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V171.Message.MessageState Evergreen.V171.Id.ChannelMessageId (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId))
    , visibleMessages : Evergreen.V171.VisibleMessages.VisibleMessages Evergreen.V171.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId) (Evergreen.V171.Thread.LastTypedAt Evergreen.V171.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelMessageId) Evergreen.V171.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V171.GuildName.GuildName
    , icon : Maybe Evergreen.V171.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V171.Discord.Id Evergreen.V171.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V171.MembersAndOwner.MembersAndOwner
            (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V171.NonemptyDict.NonemptyDict (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId) Evergreen.V171.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V171.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V171.Discord.Id Evergreen.V171.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V171.Discord.Id Evergreen.V171.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V171.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V171.SessionIdHash.SessionIdHash (Evergreen.V171.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V171.UserSession.UserSession
    , user : Evergreen.V171.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId) Evergreen.V171.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId) Evergreen.V171.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId) Evergreen.V171.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V171.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V171.Discord.Id Evergreen.V171.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId) Evergreen.V171.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V171.Discord.Id Evergreen.V171.Discord.PrivateChannelId) Evergreen.V171.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V171.SessionIdHash.SessionIdHash Evergreen.V171.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V171.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V171.Id.Id Evergreen.V171.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V171.Id.Id Evergreen.V171.Id.UserId
    , name : Evergreen.V171.ChannelName.ChannelName
    , description : Evergreen.V171.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V171.Message.Message Evergreen.V171.Id.ChannelMessageId (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId) (Evergreen.V171.Thread.LastTypedAt Evergreen.V171.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelMessageId) Evergreen.V171.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V171.Id.Id Evergreen.V171.Id.UserId
    , name : Evergreen.V171.GuildName.GuildName
    , icon : Maybe Evergreen.V171.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V171.MembersAndOwner.MembersAndOwner
            (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V171.SecretId.SecretId Evergreen.V171.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V171.Id.Id Evergreen.V171.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V171.ChannelName.ChannelName
    , description : Evergreen.V171.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V171.Message.Message Evergreen.V171.Id.ChannelMessageId (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId) (Evergreen.V171.Thread.LastTypedAt Evergreen.V171.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V171.OneToOne.OneToOne (Evergreen.V171.Discord.Id Evergreen.V171.Discord.MessageId) (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelMessageId) Evergreen.V171.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V171.GuildName.GuildName
    , icon : Maybe Evergreen.V171.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V171.Discord.Id Evergreen.V171.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V171.MembersAndOwner.MembersAndOwner
            (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }
