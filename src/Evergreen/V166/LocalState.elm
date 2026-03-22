module Evergreen.V166.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V166.ChannelDescription
import Evergreen.V166.ChannelName
import Evergreen.V166.Discord
import Evergreen.V166.DiscordUserData
import Evergreen.V166.DmChannel
import Evergreen.V166.FileStatus
import Evergreen.V166.GuildName
import Evergreen.V166.Id
import Evergreen.V166.Log
import Evergreen.V166.MembersAndOwner
import Evergreen.V166.Message
import Evergreen.V166.NonemptyDict
import Evergreen.V166.OneToOne
import Evergreen.V166.Pagination
import Evergreen.V166.SecretId
import Evergreen.V166.SessionIdHash
import Evergreen.V166.Slack
import Evergreen.V166.TextEditor
import Evergreen.V166.Thread
import Evergreen.V166.User
import Evergreen.V166.UserAgent
import Evergreen.V166.UserSession
import Evergreen.V166.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V166.NonemptyDict.NonemptyDict
            (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V166.Message.Message Evergreen.V166.Id.ChannelMessageId (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V166.Discord.PartialUser
        , icon : Maybe Evergreen.V166.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V166.Discord.User
        , linkedTo : Evergreen.V166.Id.Id Evergreen.V166.Id.UserId
        , icon : Maybe Evergreen.V166.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V166.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V166.Discord.User
        , linkedTo : Evergreen.V166.Id.Id Evergreen.V166.Id.UserId
        , icon : Maybe Evergreen.V166.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V166.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V166.Message.Message Evergreen.V166.Id.ChannelMessageId (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V166.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V166.MembersAndOwner.MembersAndOwner
            (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V166.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V166.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V166.Id.Id Evergreen.V166.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V166.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V166.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V166.Id.Id Evergreen.V166.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V166.Id.Id Evergreen.V166.Id.UserId
    , name : Evergreen.V166.ChannelName.ChannelName
    , description : Evergreen.V166.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V166.Message.MessageState Evergreen.V166.Id.ChannelMessageId (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId))
    , visibleMessages : Evergreen.V166.VisibleMessages.VisibleMessages Evergreen.V166.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) (Evergreen.V166.Thread.LastTypedAt Evergreen.V166.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) Evergreen.V166.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V166.Id.Id Evergreen.V166.Id.UserId
    , name : Evergreen.V166.GuildName.GuildName
    , icon : Maybe Evergreen.V166.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V166.MembersAndOwner.MembersAndOwner
            (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V166.SecretId.SecretId Evergreen.V166.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V166.Id.Id Evergreen.V166.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V166.ChannelName.ChannelName
    , description : Evergreen.V166.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V166.Message.MessageState Evergreen.V166.Id.ChannelMessageId (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId))
    , visibleMessages : Evergreen.V166.VisibleMessages.VisibleMessages Evergreen.V166.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Evergreen.V166.Thread.LastTypedAt Evergreen.V166.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) Evergreen.V166.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V166.GuildName.GuildName
    , icon : Maybe Evergreen.V166.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V166.MembersAndOwner.MembersAndOwner
            (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V166.NonemptyDict.NonemptyDict (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) Evergreen.V166.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V166.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V166.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V166.SessionIdHash.SessionIdHash (Evergreen.V166.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V166.UserSession.UserSession
    , user : Evergreen.V166.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) Evergreen.V166.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) Evergreen.V166.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) Evergreen.V166.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V166.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) Evergreen.V166.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId) Evergreen.V166.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V166.SessionIdHash.SessionIdHash Evergreen.V166.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V166.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V166.Id.Id Evergreen.V166.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V166.Id.Id Evergreen.V166.Id.UserId
    , name : Evergreen.V166.ChannelName.ChannelName
    , description : Evergreen.V166.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V166.Message.Message Evergreen.V166.Id.ChannelMessageId (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) (Evergreen.V166.Thread.LastTypedAt Evergreen.V166.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) Evergreen.V166.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V166.Id.Id Evergreen.V166.Id.UserId
    , name : Evergreen.V166.GuildName.GuildName
    , icon : Maybe Evergreen.V166.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V166.MembersAndOwner.MembersAndOwner
            (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V166.SecretId.SecretId Evergreen.V166.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V166.Id.Id Evergreen.V166.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V166.ChannelName.ChannelName
    , description : Evergreen.V166.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V166.Message.Message Evergreen.V166.Id.ChannelMessageId (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Evergreen.V166.Thread.LastTypedAt Evergreen.V166.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V166.OneToOne.OneToOne (Evergreen.V166.Discord.Id Evergreen.V166.Discord.MessageId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) Evergreen.V166.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V166.GuildName.GuildName
    , icon : Maybe Evergreen.V166.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V166.MembersAndOwner.MembersAndOwner
            (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }
