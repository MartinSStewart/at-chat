module Evergreen.V177.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V177.ChannelDescription
import Evergreen.V177.ChannelName
import Evergreen.V177.Discord
import Evergreen.V177.DiscordUserData
import Evergreen.V177.DmChannel
import Evergreen.V177.FileStatus
import Evergreen.V177.GuildName
import Evergreen.V177.Id
import Evergreen.V177.Log
import Evergreen.V177.MembersAndOwner
import Evergreen.V177.Message
import Evergreen.V177.NonemptyDict
import Evergreen.V177.OneToOne
import Evergreen.V177.Pagination
import Evergreen.V177.SecretId
import Evergreen.V177.SessionIdHash
import Evergreen.V177.Slack
import Evergreen.V177.TextEditor
import Evergreen.V177.Thread
import Evergreen.V177.User
import Evergreen.V177.UserAgent
import Evergreen.V177.UserSession
import Evergreen.V177.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V177.NonemptyDict.NonemptyDict
            (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V177.Message.Message Evergreen.V177.Id.ChannelMessageId (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V177.Discord.PartialUser
        , icon : Maybe Evergreen.V177.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V177.Discord.User
        , linkedTo : Evergreen.V177.Id.Id Evergreen.V177.Id.UserId
        , icon : Maybe Evergreen.V177.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V177.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V177.Discord.User
        , linkedTo : Evergreen.V177.Id.Id Evergreen.V177.Id.UserId
        , icon : Maybe Evergreen.V177.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V177.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V177.Message.Message Evergreen.V177.Id.ChannelMessageId (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V177.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V177.MembersAndOwner.MembersAndOwner
            (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V177.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V177.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V177.Id.Id Evergreen.V177.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V177.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V177.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V177.Id.Id Evergreen.V177.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V177.Id.Id Evergreen.V177.Id.UserId
    , name : Evergreen.V177.ChannelName.ChannelName
    , description : Evergreen.V177.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V177.Message.MessageState Evergreen.V177.Id.ChannelMessageId (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId))
    , visibleMessages : Evergreen.V177.VisibleMessages.VisibleMessages Evergreen.V177.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) (Evergreen.V177.Thread.LastTypedAt Evergreen.V177.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) Evergreen.V177.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V177.Id.Id Evergreen.V177.Id.UserId
    , name : Evergreen.V177.GuildName.GuildName
    , icon : Maybe Evergreen.V177.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V177.MembersAndOwner.MembersAndOwner
            (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V177.SecretId.SecretId Evergreen.V177.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V177.Id.Id Evergreen.V177.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V177.ChannelName.ChannelName
    , description : Evergreen.V177.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V177.Message.MessageState Evergreen.V177.Id.ChannelMessageId (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId))
    , visibleMessages : Evergreen.V177.VisibleMessages.VisibleMessages Evergreen.V177.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Evergreen.V177.Thread.LastTypedAt Evergreen.V177.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) Evergreen.V177.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V177.GuildName.GuildName
    , icon : Maybe Evergreen.V177.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V177.MembersAndOwner.MembersAndOwner
            (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V177.NonemptyDict.NonemptyDict (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) Evergreen.V177.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V177.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V177.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V177.SessionIdHash.SessionIdHash (Evergreen.V177.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V177.UserSession.UserSession
    , user : Evergreen.V177.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) Evergreen.V177.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) Evergreen.V177.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) Evergreen.V177.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V177.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) Evergreen.V177.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId) Evergreen.V177.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V177.SessionIdHash.SessionIdHash Evergreen.V177.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V177.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V177.Id.Id Evergreen.V177.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V177.Id.Id Evergreen.V177.Id.UserId
    , name : Evergreen.V177.ChannelName.ChannelName
    , description : Evergreen.V177.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V177.Message.Message Evergreen.V177.Id.ChannelMessageId (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) (Evergreen.V177.Thread.LastTypedAt Evergreen.V177.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) Evergreen.V177.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V177.Id.Id Evergreen.V177.Id.UserId
    , name : Evergreen.V177.GuildName.GuildName
    , icon : Maybe Evergreen.V177.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V177.MembersAndOwner.MembersAndOwner
            (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V177.SecretId.SecretId Evergreen.V177.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V177.Id.Id Evergreen.V177.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V177.ChannelName.ChannelName
    , description : Evergreen.V177.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V177.Message.Message Evergreen.V177.Id.ChannelMessageId (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Evergreen.V177.Thread.LastTypedAt Evergreen.V177.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V177.OneToOne.OneToOne (Evergreen.V177.Discord.Id Evergreen.V177.Discord.MessageId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) Evergreen.V177.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V177.GuildName.GuildName
    , icon : Maybe Evergreen.V177.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V177.MembersAndOwner.MembersAndOwner
            (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }
