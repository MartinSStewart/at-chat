module Evergreen.V160.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V160.ChannelDescription
import Evergreen.V160.ChannelName
import Evergreen.V160.Discord
import Evergreen.V160.DiscordUserData
import Evergreen.V160.DmChannel
import Evergreen.V160.FileStatus
import Evergreen.V160.GuildName
import Evergreen.V160.Id
import Evergreen.V160.Log
import Evergreen.V160.Message
import Evergreen.V160.NonemptyDict
import Evergreen.V160.OneToOne
import Evergreen.V160.Pagination
import Evergreen.V160.SecretId
import Evergreen.V160.SessionIdHash
import Evergreen.V160.Slack
import Evergreen.V160.TextEditor
import Evergreen.V160.Thread
import Evergreen.V160.User
import Evergreen.V160.UserAgent
import Evergreen.V160.UserSession
import Evergreen.V160.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V160.NonemptyDict.NonemptyDict
            (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V160.Message.Message Evergreen.V160.Id.ChannelMessageId (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V160.Discord.PartialUser
        , icon : Maybe Evergreen.V160.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V160.Discord.User
        , linkedTo : Evergreen.V160.Id.Id Evergreen.V160.Id.UserId
        , icon : Maybe Evergreen.V160.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V160.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V160.Discord.User
        , linkedTo : Evergreen.V160.Id.Id Evergreen.V160.Id.UserId
        , icon : Maybe Evergreen.V160.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V160.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V160.Message.Message Evergreen.V160.Id.ChannelMessageId (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V160.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) AdminData_DiscordChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V160.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V160.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V160.Id.Id Evergreen.V160.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V160.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V160.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V160.Id.Id Evergreen.V160.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V160.Id.Id Evergreen.V160.Id.UserId
    , name : Evergreen.V160.ChannelName.ChannelName
    , description : Evergreen.V160.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V160.Message.MessageState Evergreen.V160.Id.ChannelMessageId (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId))
    , visibleMessages : Evergreen.V160.VisibleMessages.VisibleMessages Evergreen.V160.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) (Evergreen.V160.Thread.LastTypedAt Evergreen.V160.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) Evergreen.V160.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V160.Id.Id Evergreen.V160.Id.UserId
    , name : Evergreen.V160.GuildName.GuildName
    , icon : Maybe Evergreen.V160.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V160.Id.Id Evergreen.V160.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V160.SecretId.SecretId Evergreen.V160.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V160.Id.Id Evergreen.V160.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V160.ChannelName.ChannelName
    , description : Evergreen.V160.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V160.Message.MessageState Evergreen.V160.Id.ChannelMessageId (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId))
    , visibleMessages : Evergreen.V160.VisibleMessages.VisibleMessages Evergreen.V160.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Evergreen.V160.Thread.LastTypedAt Evergreen.V160.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) Evergreen.V160.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V160.GuildName.GuildName
    , icon : Maybe Evergreen.V160.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V160.NonemptyDict.NonemptyDict (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) Evergreen.V160.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V160.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V160.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V160.SessionIdHash.SessionIdHash (Evergreen.V160.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V160.UserSession.UserSession
    , user : Evergreen.V160.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) Evergreen.V160.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) Evergreen.V160.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) Evergreen.V160.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V160.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) Evergreen.V160.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId) Evergreen.V160.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V160.SessionIdHash.SessionIdHash Evergreen.V160.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V160.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V160.Id.Id Evergreen.V160.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V160.Id.Id Evergreen.V160.Id.UserId
    , name : Evergreen.V160.ChannelName.ChannelName
    , description : Evergreen.V160.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V160.Message.Message Evergreen.V160.Id.ChannelMessageId (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) (Evergreen.V160.Thread.LastTypedAt Evergreen.V160.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) Evergreen.V160.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V160.Id.Id Evergreen.V160.Id.UserId
    , name : Evergreen.V160.GuildName.GuildName
    , icon : Maybe Evergreen.V160.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V160.Id.Id Evergreen.V160.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V160.SecretId.SecretId Evergreen.V160.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V160.Id.Id Evergreen.V160.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V160.ChannelName.ChannelName
    , description : Evergreen.V160.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V160.Message.Message Evergreen.V160.Id.ChannelMessageId (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Evergreen.V160.Thread.LastTypedAt Evergreen.V160.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V160.OneToOne.OneToOne (Evergreen.V160.Discord.Id Evergreen.V160.Discord.MessageId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) Evergreen.V160.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V160.GuildName.GuildName
    , icon : Maybe Evergreen.V160.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , owner : Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId
    }
