module Evergreen.V158.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V158.ChannelDescription
import Evergreen.V158.ChannelName
import Evergreen.V158.Discord
import Evergreen.V158.DiscordUserData
import Evergreen.V158.DmChannel
import Evergreen.V158.FileStatus
import Evergreen.V158.GuildName
import Evergreen.V158.Id
import Evergreen.V158.Log
import Evergreen.V158.Message
import Evergreen.V158.NonemptyDict
import Evergreen.V158.OneToOne
import Evergreen.V158.Pagination
import Evergreen.V158.SecretId
import Evergreen.V158.SessionIdHash
import Evergreen.V158.Slack
import Evergreen.V158.TextEditor
import Evergreen.V158.Thread
import Evergreen.V158.User
import Evergreen.V158.UserAgent
import Evergreen.V158.UserSession
import Evergreen.V158.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V158.NonemptyDict.NonemptyDict
            (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V158.Message.Message Evergreen.V158.Id.ChannelMessageId (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V158.Discord.PartialUser
        , icon : Maybe Evergreen.V158.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V158.Discord.User
        , linkedTo : Evergreen.V158.Id.Id Evergreen.V158.Id.UserId
        , icon : Maybe Evergreen.V158.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V158.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V158.Discord.User
        , linkedTo : Evergreen.V158.Id.Id Evergreen.V158.Id.UserId
        , icon : Maybe Evergreen.V158.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V158.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V158.Message.Message Evergreen.V158.Id.ChannelMessageId (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V158.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) AdminData_DiscordChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V158.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V158.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V158.Id.Id Evergreen.V158.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V158.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V158.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V158.Id.Id Evergreen.V158.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V158.Id.Id Evergreen.V158.Id.UserId
    , name : Evergreen.V158.ChannelName.ChannelName
    , description : Evergreen.V158.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V158.Message.MessageState Evergreen.V158.Id.ChannelMessageId (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId))
    , visibleMessages : Evergreen.V158.VisibleMessages.VisibleMessages Evergreen.V158.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) (Evergreen.V158.Thread.LastTypedAt Evergreen.V158.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) Evergreen.V158.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V158.Id.Id Evergreen.V158.Id.UserId
    , name : Evergreen.V158.GuildName.GuildName
    , icon : Maybe Evergreen.V158.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V158.Id.Id Evergreen.V158.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V158.SecretId.SecretId Evergreen.V158.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V158.Id.Id Evergreen.V158.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V158.ChannelName.ChannelName
    , description : Evergreen.V158.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V158.Message.MessageState Evergreen.V158.Id.ChannelMessageId (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId))
    , visibleMessages : Evergreen.V158.VisibleMessages.VisibleMessages Evergreen.V158.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Evergreen.V158.Thread.LastTypedAt Evergreen.V158.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) Evergreen.V158.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V158.GuildName.GuildName
    , icon : Maybe Evergreen.V158.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V158.NonemptyDict.NonemptyDict (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) Evergreen.V158.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V158.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V158.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V158.SessionIdHash.SessionIdHash (Evergreen.V158.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V158.UserSession.UserSession
    , user : Evergreen.V158.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) Evergreen.V158.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) Evergreen.V158.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) Evergreen.V158.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V158.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) Evergreen.V158.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId) Evergreen.V158.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V158.SessionIdHash.SessionIdHash Evergreen.V158.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V158.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V158.Id.Id Evergreen.V158.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V158.Id.Id Evergreen.V158.Id.UserId
    , name : Evergreen.V158.ChannelName.ChannelName
    , description : Evergreen.V158.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V158.Message.Message Evergreen.V158.Id.ChannelMessageId (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) (Evergreen.V158.Thread.LastTypedAt Evergreen.V158.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) Evergreen.V158.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V158.Id.Id Evergreen.V158.Id.UserId
    , name : Evergreen.V158.GuildName.GuildName
    , icon : Maybe Evergreen.V158.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V158.Id.Id Evergreen.V158.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V158.SecretId.SecretId Evergreen.V158.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V158.Id.Id Evergreen.V158.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V158.ChannelName.ChannelName
    , description : Evergreen.V158.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V158.Message.Message Evergreen.V158.Id.ChannelMessageId (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Evergreen.V158.Thread.LastTypedAt Evergreen.V158.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V158.OneToOne.OneToOne (Evergreen.V158.Discord.Id Evergreen.V158.Discord.MessageId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) Evergreen.V158.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V158.GuildName.GuildName
    , icon : Maybe Evergreen.V158.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId
    }
