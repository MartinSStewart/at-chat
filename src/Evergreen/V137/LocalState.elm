module Evergreen.V137.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V137.ChannelName
import Evergreen.V137.Discord
import Evergreen.V137.Discord.Id
import Evergreen.V137.DmChannel
import Evergreen.V137.FileStatus
import Evergreen.V137.GuildName
import Evergreen.V137.Id
import Evergreen.V137.Log
import Evergreen.V137.Message
import Evergreen.V137.NonemptyDict
import Evergreen.V137.NonemptySet
import Evergreen.V137.OneToOne
import Evergreen.V137.SecretId
import Evergreen.V137.SessionIdHash
import Evergreen.V137.Slack
import Evergreen.V137.TextEditor
import Evergreen.V137.Thread
import Evergreen.V137.User
import Evergreen.V137.UserAgent
import Evergreen.V137.UserSession
import Evergreen.V137.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members : Evergreen.V137.NonemptySet.NonemptySet (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId)
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V137.Message.Message Evergreen.V137.Id.ChannelMessageId (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V137.Discord.PartialUser
        , icon : Maybe Evergreen.V137.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V137.Discord.User
        , linkedTo : Evergreen.V137.Id.Id Evergreen.V137.Id.UserId
        , icon : Maybe Evergreen.V137.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V137.User.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V137.Discord.User
        , linkedTo : Evergreen.V137.Id.Id Evergreen.V137.Id.UserId
        , icon : Maybe Evergreen.V137.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V137.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V137.Message.Message Evergreen.V137.Id.ChannelMessageId (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V137.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId) AdminData_DiscordChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V137.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V137.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V137.Id.Id Evergreen.V137.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V137.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId) (LoadingDiscordChannelStep messages)


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V137.Id.Id Evergreen.V137.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V137.Id.Id Evergreen.V137.Id.UserId
    , name : Evergreen.V137.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V137.Message.MessageState Evergreen.V137.Id.ChannelMessageId (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId))
    , visibleMessages : Evergreen.V137.VisibleMessages.VisibleMessages Evergreen.V137.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) (Evergreen.V137.Thread.LastTypedAt Evergreen.V137.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) Evergreen.V137.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V137.Id.Id Evergreen.V137.Id.UserId
    , name : Evergreen.V137.GuildName.GuildName
    , icon : Maybe Evergreen.V137.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V137.Id.Id Evergreen.V137.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V137.SecretId.SecretId Evergreen.V137.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V137.Id.Id Evergreen.V137.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V137.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V137.Message.MessageState Evergreen.V137.Id.ChannelMessageId (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId))
    , visibleMessages : Evergreen.V137.VisibleMessages.VisibleMessages Evergreen.V137.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Evergreen.V137.Thread.LastTypedAt Evergreen.V137.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) Evergreen.V137.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V137.GuildName.GuildName
    , icon : Maybe Evergreen.V137.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V137.NonemptyDict.NonemptyDict (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) Evergreen.V137.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V137.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V137.UserSession.UserSession
    , user : Evergreen.V137.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) Evergreen.V137.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) Evergreen.V137.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) Evergreen.V137.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V137.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) Evergreen.V137.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId) Evergreen.V137.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V137.SessionIdHash.SessionIdHash Evergreen.V137.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V137.TextEditor.LocalState
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V137.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V137.Id.Id Evergreen.V137.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V137.Id.Id Evergreen.V137.Id.UserId
    , name : Evergreen.V137.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V137.Message.Message Evergreen.V137.Id.ChannelMessageId (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) (Evergreen.V137.Thread.LastTypedAt Evergreen.V137.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) Evergreen.V137.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V137.Id.Id Evergreen.V137.Id.UserId
    , name : Evergreen.V137.GuildName.GuildName
    , icon : Maybe Evergreen.V137.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V137.Id.Id Evergreen.V137.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V137.SecretId.SecretId Evergreen.V137.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V137.Id.Id Evergreen.V137.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V137.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V137.Message.Message Evergreen.V137.Id.ChannelMessageId (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Evergreen.V137.Thread.LastTypedAt Evergreen.V137.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V137.OneToOne.OneToOne (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.MessageId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) Evergreen.V137.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V137.GuildName.GuildName
    , icon : Maybe Evergreen.V137.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId
    }
