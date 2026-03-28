module Evergreen.V176.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V176.ChannelDescription
import Evergreen.V176.ChannelName
import Evergreen.V176.Discord
import Evergreen.V176.DiscordUserData
import Evergreen.V176.DmChannel
import Evergreen.V176.FileStatus
import Evergreen.V176.GuildName
import Evergreen.V176.Id
import Evergreen.V176.Log
import Evergreen.V176.MembersAndOwner
import Evergreen.V176.Message
import Evergreen.V176.NonemptyDict
import Evergreen.V176.OneToOne
import Evergreen.V176.Pagination
import Evergreen.V176.SecretId
import Evergreen.V176.SessionIdHash
import Evergreen.V176.Slack
import Evergreen.V176.TextEditor
import Evergreen.V176.Thread
import Evergreen.V176.User
import Evergreen.V176.UserAgent
import Evergreen.V176.UserSession
import Evergreen.V176.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V176.NonemptyDict.NonemptyDict
            (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V176.Message.Message Evergreen.V176.Id.ChannelMessageId (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V176.Discord.PartialUser
        , icon : Maybe Evergreen.V176.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V176.Discord.User
        , linkedTo : Evergreen.V176.Id.Id Evergreen.V176.Id.UserId
        , icon : Maybe Evergreen.V176.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V176.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V176.Discord.User
        , linkedTo : Evergreen.V176.Id.Id Evergreen.V176.Id.UserId
        , icon : Maybe Evergreen.V176.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V176.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V176.Message.Message Evergreen.V176.Id.ChannelMessageId (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V176.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V176.MembersAndOwner.MembersAndOwner
            (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V176.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V176.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V176.Id.Id Evergreen.V176.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V176.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V176.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V176.Id.Id Evergreen.V176.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V176.Id.Id Evergreen.V176.Id.UserId
    , name : Evergreen.V176.ChannelName.ChannelName
    , description : Evergreen.V176.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V176.Message.MessageState Evergreen.V176.Id.ChannelMessageId (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId))
    , visibleMessages : Evergreen.V176.VisibleMessages.VisibleMessages Evergreen.V176.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) (Evergreen.V176.Thread.LastTypedAt Evergreen.V176.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) Evergreen.V176.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V176.Id.Id Evergreen.V176.Id.UserId
    , name : Evergreen.V176.GuildName.GuildName
    , icon : Maybe Evergreen.V176.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V176.MembersAndOwner.MembersAndOwner
            (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V176.SecretId.SecretId Evergreen.V176.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V176.Id.Id Evergreen.V176.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V176.ChannelName.ChannelName
    , description : Evergreen.V176.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V176.Message.MessageState Evergreen.V176.Id.ChannelMessageId (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId))
    , visibleMessages : Evergreen.V176.VisibleMessages.VisibleMessages Evergreen.V176.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Evergreen.V176.Thread.LastTypedAt Evergreen.V176.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) Evergreen.V176.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V176.GuildName.GuildName
    , icon : Maybe Evergreen.V176.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V176.MembersAndOwner.MembersAndOwner
            (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V176.NonemptyDict.NonemptyDict (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) Evergreen.V176.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V176.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V176.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V176.SessionIdHash.SessionIdHash (Evergreen.V176.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V176.UserSession.UserSession
    , user : Evergreen.V176.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) Evergreen.V176.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) Evergreen.V176.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) Evergreen.V176.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V176.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) Evergreen.V176.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId) Evergreen.V176.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V176.SessionIdHash.SessionIdHash Evergreen.V176.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V176.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V176.Id.Id Evergreen.V176.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V176.Id.Id Evergreen.V176.Id.UserId
    , name : Evergreen.V176.ChannelName.ChannelName
    , description : Evergreen.V176.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V176.Message.Message Evergreen.V176.Id.ChannelMessageId (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) (Evergreen.V176.Thread.LastTypedAt Evergreen.V176.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) Evergreen.V176.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V176.Id.Id Evergreen.V176.Id.UserId
    , name : Evergreen.V176.GuildName.GuildName
    , icon : Maybe Evergreen.V176.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V176.MembersAndOwner.MembersAndOwner
            (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V176.SecretId.SecretId Evergreen.V176.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V176.Id.Id Evergreen.V176.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V176.ChannelName.ChannelName
    , description : Evergreen.V176.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V176.Message.Message Evergreen.V176.Id.ChannelMessageId (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Evergreen.V176.Thread.LastTypedAt Evergreen.V176.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V176.OneToOne.OneToOne (Evergreen.V176.Discord.Id Evergreen.V176.Discord.MessageId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) Evergreen.V176.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V176.GuildName.GuildName
    , icon : Maybe Evergreen.V176.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V176.MembersAndOwner.MembersAndOwner
            (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }
