module Evergreen.V185.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V185.ChannelDescription
import Evergreen.V185.ChannelName
import Evergreen.V185.Discord
import Evergreen.V185.DiscordUserData
import Evergreen.V185.DmChannel
import Evergreen.V185.FileStatus
import Evergreen.V185.GuildName
import Evergreen.V185.Id
import Evergreen.V185.Log
import Evergreen.V185.MembersAndOwner
import Evergreen.V185.Message
import Evergreen.V185.NonemptyDict
import Evergreen.V185.OneToOne
import Evergreen.V185.Pagination
import Evergreen.V185.SecretId
import Evergreen.V185.SessionIdHash
import Evergreen.V185.Slack
import Evergreen.V185.TextEditor
import Evergreen.V185.Thread
import Evergreen.V185.User
import Evergreen.V185.UserAgent
import Evergreen.V185.UserSession
import Evergreen.V185.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V185.NonemptyDict.NonemptyDict
            (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V185.Message.Message Evergreen.V185.Id.ChannelMessageId (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V185.Discord.PartialUser
        , icon : Maybe Evergreen.V185.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V185.Discord.User
        , linkedTo : Evergreen.V185.Id.Id Evergreen.V185.Id.UserId
        , icon : Maybe Evergreen.V185.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V185.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V185.Discord.User
        , linkedTo : Evergreen.V185.Id.Id Evergreen.V185.Id.UserId
        , icon : Maybe Evergreen.V185.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V185.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V185.Message.Message Evergreen.V185.Id.ChannelMessageId (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V185.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V185.MembersAndOwner.MembersAndOwner
            (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V185.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V185.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V185.Id.Id Evergreen.V185.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V185.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V185.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V185.Id.Id Evergreen.V185.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V185.Id.Id Evergreen.V185.Id.UserId
    , name : Evergreen.V185.ChannelName.ChannelName
    , description : Evergreen.V185.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V185.Message.MessageState Evergreen.V185.Id.ChannelMessageId (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId))
    , visibleMessages : Evergreen.V185.VisibleMessages.VisibleMessages Evergreen.V185.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) (Evergreen.V185.Thread.LastTypedAt Evergreen.V185.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) Evergreen.V185.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V185.Id.Id Evergreen.V185.Id.UserId
    , name : Evergreen.V185.GuildName.GuildName
    , icon : Maybe Evergreen.V185.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V185.MembersAndOwner.MembersAndOwner
            (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V185.SecretId.SecretId Evergreen.V185.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V185.Id.Id Evergreen.V185.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V185.ChannelName.ChannelName
    , description : Evergreen.V185.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V185.Message.MessageState Evergreen.V185.Id.ChannelMessageId (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId))
    , visibleMessages : Evergreen.V185.VisibleMessages.VisibleMessages Evergreen.V185.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Evergreen.V185.Thread.LastTypedAt Evergreen.V185.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) Evergreen.V185.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V185.GuildName.GuildName
    , icon : Maybe Evergreen.V185.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V185.MembersAndOwner.MembersAndOwner
            (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V185.NonemptyDict.NonemptyDict (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) Evergreen.V185.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V185.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V185.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V185.SessionIdHash.SessionIdHash (Evergreen.V185.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V185.UserSession.UserSession
    , user : Evergreen.V185.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) Evergreen.V185.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) Evergreen.V185.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) Evergreen.V185.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V185.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) Evergreen.V185.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId) Evergreen.V185.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V185.SessionIdHash.SessionIdHash Evergreen.V185.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V185.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V185.Id.Id Evergreen.V185.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V185.Id.Id Evergreen.V185.Id.UserId
    , name : Evergreen.V185.ChannelName.ChannelName
    , description : Evergreen.V185.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V185.Message.Message Evergreen.V185.Id.ChannelMessageId (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) (Evergreen.V185.Thread.LastTypedAt Evergreen.V185.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) Evergreen.V185.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V185.Id.Id Evergreen.V185.Id.UserId
    , name : Evergreen.V185.GuildName.GuildName
    , icon : Maybe Evergreen.V185.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V185.MembersAndOwner.MembersAndOwner
            (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V185.SecretId.SecretId Evergreen.V185.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V185.Id.Id Evergreen.V185.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V185.ChannelName.ChannelName
    , description : Evergreen.V185.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V185.Message.Message Evergreen.V185.Id.ChannelMessageId (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Evergreen.V185.Thread.LastTypedAt Evergreen.V185.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V185.OneToOne.OneToOne (Evergreen.V185.Discord.Id Evergreen.V185.Discord.MessageId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) Evergreen.V185.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V185.GuildName.GuildName
    , icon : Maybe Evergreen.V185.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V185.MembersAndOwner.MembersAndOwner
            (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }
