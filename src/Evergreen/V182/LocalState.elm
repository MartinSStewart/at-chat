module Evergreen.V182.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V182.ChannelDescription
import Evergreen.V182.ChannelName
import Evergreen.V182.Discord
import Evergreen.V182.DiscordUserData
import Evergreen.V182.DmChannel
import Evergreen.V182.FileStatus
import Evergreen.V182.GuildName
import Evergreen.V182.Id
import Evergreen.V182.Log
import Evergreen.V182.MembersAndOwner
import Evergreen.V182.Message
import Evergreen.V182.NonemptyDict
import Evergreen.V182.OneToOne
import Evergreen.V182.Pagination
import Evergreen.V182.SecretId
import Evergreen.V182.SessionIdHash
import Evergreen.V182.Slack
import Evergreen.V182.TextEditor
import Evergreen.V182.Thread
import Evergreen.V182.User
import Evergreen.V182.UserAgent
import Evergreen.V182.UserSession
import Evergreen.V182.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V182.NonemptyDict.NonemptyDict
            (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V182.Message.Message Evergreen.V182.Id.ChannelMessageId (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V182.Discord.PartialUser
        , icon : Maybe Evergreen.V182.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V182.Discord.User
        , linkedTo : Evergreen.V182.Id.Id Evergreen.V182.Id.UserId
        , icon : Maybe Evergreen.V182.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V182.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V182.Discord.User
        , linkedTo : Evergreen.V182.Id.Id Evergreen.V182.Id.UserId
        , icon : Maybe Evergreen.V182.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V182.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V182.Message.Message Evergreen.V182.Id.ChannelMessageId (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V182.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V182.Discord.Id Evergreen.V182.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V182.MembersAndOwner.MembersAndOwner
            (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V182.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V182.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V182.Id.Id Evergreen.V182.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V182.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V182.Discord.Id Evergreen.V182.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V182.Discord.Id Evergreen.V182.Discord.GuildId) (Evergreen.V182.Discord.Id Evergreen.V182.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V182.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V182.Id.Id Evergreen.V182.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V182.Id.Id Evergreen.V182.Id.UserId
    , name : Evergreen.V182.ChannelName.ChannelName
    , description : Evergreen.V182.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V182.Message.MessageState Evergreen.V182.Id.ChannelMessageId (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId))
    , visibleMessages : Evergreen.V182.VisibleMessages.VisibleMessages Evergreen.V182.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId) (Evergreen.V182.Thread.LastTypedAt Evergreen.V182.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelMessageId) Evergreen.V182.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V182.Id.Id Evergreen.V182.Id.UserId
    , name : Evergreen.V182.GuildName.GuildName
    , icon : Maybe Evergreen.V182.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V182.MembersAndOwner.MembersAndOwner
            (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V182.SecretId.SecretId Evergreen.V182.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V182.Id.Id Evergreen.V182.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V182.ChannelName.ChannelName
    , description : Evergreen.V182.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V182.Message.MessageState Evergreen.V182.Id.ChannelMessageId (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId))
    , visibleMessages : Evergreen.V182.VisibleMessages.VisibleMessages Evergreen.V182.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId) (Evergreen.V182.Thread.LastTypedAt Evergreen.V182.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelMessageId) Evergreen.V182.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V182.GuildName.GuildName
    , icon : Maybe Evergreen.V182.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V182.Discord.Id Evergreen.V182.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V182.MembersAndOwner.MembersAndOwner
            (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V182.NonemptyDict.NonemptyDict (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId) Evergreen.V182.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V182.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V182.Discord.Id Evergreen.V182.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V182.Discord.Id Evergreen.V182.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V182.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V182.SessionIdHash.SessionIdHash (Evergreen.V182.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V182.UserSession.UserSession
    , user : Evergreen.V182.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId) Evergreen.V182.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId) Evergreen.V182.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId) Evergreen.V182.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V182.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V182.Discord.Id Evergreen.V182.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId) Evergreen.V182.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V182.Discord.Id Evergreen.V182.Discord.PrivateChannelId) Evergreen.V182.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V182.SessionIdHash.SessionIdHash Evergreen.V182.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V182.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V182.Id.Id Evergreen.V182.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V182.Id.Id Evergreen.V182.Id.UserId
    , name : Evergreen.V182.ChannelName.ChannelName
    , description : Evergreen.V182.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V182.Message.Message Evergreen.V182.Id.ChannelMessageId (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId) (Evergreen.V182.Thread.LastTypedAt Evergreen.V182.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelMessageId) Evergreen.V182.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V182.Id.Id Evergreen.V182.Id.UserId
    , name : Evergreen.V182.GuildName.GuildName
    , icon : Maybe Evergreen.V182.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V182.MembersAndOwner.MembersAndOwner
            (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V182.SecretId.SecretId Evergreen.V182.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V182.Id.Id Evergreen.V182.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V182.ChannelName.ChannelName
    , description : Evergreen.V182.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V182.Message.Message Evergreen.V182.Id.ChannelMessageId (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId) (Evergreen.V182.Thread.LastTypedAt Evergreen.V182.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V182.OneToOne.OneToOne (Evergreen.V182.Discord.Id Evergreen.V182.Discord.MessageId) (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelMessageId) Evergreen.V182.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V182.GuildName.GuildName
    , icon : Maybe Evergreen.V182.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V182.Discord.Id Evergreen.V182.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V182.MembersAndOwner.MembersAndOwner
            (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }
