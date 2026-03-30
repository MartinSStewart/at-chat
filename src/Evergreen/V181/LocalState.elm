module Evergreen.V181.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V181.ChannelDescription
import Evergreen.V181.ChannelName
import Evergreen.V181.Discord
import Evergreen.V181.DiscordUserData
import Evergreen.V181.DmChannel
import Evergreen.V181.FileStatus
import Evergreen.V181.GuildName
import Evergreen.V181.Id
import Evergreen.V181.Log
import Evergreen.V181.MembersAndOwner
import Evergreen.V181.Message
import Evergreen.V181.NonemptyDict
import Evergreen.V181.OneToOne
import Evergreen.V181.Pagination
import Evergreen.V181.SecretId
import Evergreen.V181.SessionIdHash
import Evergreen.V181.Slack
import Evergreen.V181.TextEditor
import Evergreen.V181.Thread
import Evergreen.V181.User
import Evergreen.V181.UserAgent
import Evergreen.V181.UserSession
import Evergreen.V181.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V181.NonemptyDict.NonemptyDict
            (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V181.Message.Message Evergreen.V181.Id.ChannelMessageId (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V181.Discord.PartialUser
        , icon : Maybe Evergreen.V181.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V181.Discord.User
        , linkedTo : Evergreen.V181.Id.Id Evergreen.V181.Id.UserId
        , icon : Maybe Evergreen.V181.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V181.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V181.Discord.User
        , linkedTo : Evergreen.V181.Id.Id Evergreen.V181.Id.UserId
        , icon : Maybe Evergreen.V181.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V181.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V181.Message.Message Evergreen.V181.Id.ChannelMessageId (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V181.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V181.MembersAndOwner.MembersAndOwner
            (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V181.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V181.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V181.Id.Id Evergreen.V181.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V181.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V181.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V181.Id.Id Evergreen.V181.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V181.Id.Id Evergreen.V181.Id.UserId
    , name : Evergreen.V181.ChannelName.ChannelName
    , description : Evergreen.V181.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V181.Message.MessageState Evergreen.V181.Id.ChannelMessageId (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId))
    , visibleMessages : Evergreen.V181.VisibleMessages.VisibleMessages Evergreen.V181.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) (Evergreen.V181.Thread.LastTypedAt Evergreen.V181.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) Evergreen.V181.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V181.Id.Id Evergreen.V181.Id.UserId
    , name : Evergreen.V181.GuildName.GuildName
    , icon : Maybe Evergreen.V181.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V181.MembersAndOwner.MembersAndOwner
            (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V181.SecretId.SecretId Evergreen.V181.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V181.Id.Id Evergreen.V181.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V181.ChannelName.ChannelName
    , description : Evergreen.V181.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V181.Message.MessageState Evergreen.V181.Id.ChannelMessageId (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId))
    , visibleMessages : Evergreen.V181.VisibleMessages.VisibleMessages Evergreen.V181.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Evergreen.V181.Thread.LastTypedAt Evergreen.V181.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) Evergreen.V181.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V181.GuildName.GuildName
    , icon : Maybe Evergreen.V181.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V181.MembersAndOwner.MembersAndOwner
            (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V181.NonemptyDict.NonemptyDict (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) Evergreen.V181.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V181.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V181.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V181.SessionIdHash.SessionIdHash (Evergreen.V181.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V181.UserSession.UserSession
    , user : Evergreen.V181.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) Evergreen.V181.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) Evergreen.V181.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) Evergreen.V181.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V181.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) Evergreen.V181.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId) Evergreen.V181.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V181.SessionIdHash.SessionIdHash Evergreen.V181.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V181.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V181.Id.Id Evergreen.V181.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V181.Id.Id Evergreen.V181.Id.UserId
    , name : Evergreen.V181.ChannelName.ChannelName
    , description : Evergreen.V181.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V181.Message.Message Evergreen.V181.Id.ChannelMessageId (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) (Evergreen.V181.Thread.LastTypedAt Evergreen.V181.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) Evergreen.V181.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V181.Id.Id Evergreen.V181.Id.UserId
    , name : Evergreen.V181.GuildName.GuildName
    , icon : Maybe Evergreen.V181.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V181.MembersAndOwner.MembersAndOwner
            (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V181.SecretId.SecretId Evergreen.V181.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V181.Id.Id Evergreen.V181.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V181.ChannelName.ChannelName
    , description : Evergreen.V181.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V181.Message.Message Evergreen.V181.Id.ChannelMessageId (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Evergreen.V181.Thread.LastTypedAt Evergreen.V181.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V181.OneToOne.OneToOne (Evergreen.V181.Discord.Id Evergreen.V181.Discord.MessageId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) Evergreen.V181.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V181.GuildName.GuildName
    , icon : Maybe Evergreen.V181.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V181.MembersAndOwner.MembersAndOwner
            (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }
