module Evergreen.V186.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V186.ChannelDescription
import Evergreen.V186.ChannelName
import Evergreen.V186.Discord
import Evergreen.V186.DiscordUserData
import Evergreen.V186.DmChannel
import Evergreen.V186.FileStatus
import Evergreen.V186.GuildName
import Evergreen.V186.Id
import Evergreen.V186.Log
import Evergreen.V186.MembersAndOwner
import Evergreen.V186.Message
import Evergreen.V186.NonemptyDict
import Evergreen.V186.OneToOne
import Evergreen.V186.Pagination
import Evergreen.V186.SecretId
import Evergreen.V186.SessionIdHash
import Evergreen.V186.Slack
import Evergreen.V186.TextEditor
import Evergreen.V186.Thread
import Evergreen.V186.User
import Evergreen.V186.UserAgent
import Evergreen.V186.UserSession
import Evergreen.V186.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V186.NonemptyDict.NonemptyDict
            (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V186.Message.Message Evergreen.V186.Id.ChannelMessageId (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V186.Discord.PartialUser
        , icon : Maybe Evergreen.V186.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V186.Discord.User
        , linkedTo : Evergreen.V186.Id.Id Evergreen.V186.Id.UserId
        , icon : Maybe Evergreen.V186.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V186.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V186.Discord.User
        , linkedTo : Evergreen.V186.Id.Id Evergreen.V186.Id.UserId
        , icon : Maybe Evergreen.V186.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V186.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V186.Message.Message Evergreen.V186.Id.ChannelMessageId (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V186.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V186.MembersAndOwner.MembersAndOwner
            (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V186.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V186.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V186.Id.Id Evergreen.V186.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V186.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V186.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V186.Id.Id Evergreen.V186.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V186.Id.Id Evergreen.V186.Id.UserId
    , name : Evergreen.V186.ChannelName.ChannelName
    , description : Evergreen.V186.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V186.Message.MessageState Evergreen.V186.Id.ChannelMessageId (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId))
    , visibleMessages : Evergreen.V186.VisibleMessages.VisibleMessages Evergreen.V186.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) (Evergreen.V186.Thread.LastTypedAt Evergreen.V186.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) Evergreen.V186.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V186.Id.Id Evergreen.V186.Id.UserId
    , name : Evergreen.V186.GuildName.GuildName
    , icon : Maybe Evergreen.V186.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V186.MembersAndOwner.MembersAndOwner
            (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V186.SecretId.SecretId Evergreen.V186.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V186.Id.Id Evergreen.V186.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V186.ChannelName.ChannelName
    , description : Evergreen.V186.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V186.Message.MessageState Evergreen.V186.Id.ChannelMessageId (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId))
    , visibleMessages : Evergreen.V186.VisibleMessages.VisibleMessages Evergreen.V186.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Evergreen.V186.Thread.LastTypedAt Evergreen.V186.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) Evergreen.V186.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V186.GuildName.GuildName
    , icon : Maybe Evergreen.V186.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V186.MembersAndOwner.MembersAndOwner
            (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V186.NonemptyDict.NonemptyDict (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) Evergreen.V186.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V186.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V186.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V186.SessionIdHash.SessionIdHash (Evergreen.V186.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , filesCount : Int
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V186.UserSession.UserSession
    , user : Evergreen.V186.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) Evergreen.V186.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) Evergreen.V186.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) Evergreen.V186.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V186.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) Evergreen.V186.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId) Evergreen.V186.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V186.SessionIdHash.SessionIdHash Evergreen.V186.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V186.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V186.Id.Id Evergreen.V186.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V186.Id.Id Evergreen.V186.Id.UserId
    , name : Evergreen.V186.ChannelName.ChannelName
    , description : Evergreen.V186.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V186.Message.Message Evergreen.V186.Id.ChannelMessageId (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) (Evergreen.V186.Thread.LastTypedAt Evergreen.V186.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) Evergreen.V186.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V186.Id.Id Evergreen.V186.Id.UserId
    , name : Evergreen.V186.GuildName.GuildName
    , icon : Maybe Evergreen.V186.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V186.MembersAndOwner.MembersAndOwner
            (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V186.SecretId.SecretId Evergreen.V186.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V186.Id.Id Evergreen.V186.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V186.ChannelName.ChannelName
    , description : Evergreen.V186.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V186.Message.Message Evergreen.V186.Id.ChannelMessageId (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Evergreen.V186.Thread.LastTypedAt Evergreen.V186.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V186.OneToOne.OneToOne (Evergreen.V186.Discord.Id Evergreen.V186.Discord.MessageId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) Evergreen.V186.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V186.GuildName.GuildName
    , icon : Maybe Evergreen.V186.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V186.MembersAndOwner.MembersAndOwner
            (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }
