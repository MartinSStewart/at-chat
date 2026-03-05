module Evergreen.V135.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V135.ChannelName
import Evergreen.V135.Discord
import Evergreen.V135.Discord.Id
import Evergreen.V135.DmChannel
import Evergreen.V135.FileStatus
import Evergreen.V135.GuildName
import Evergreen.V135.Id
import Evergreen.V135.Log
import Evergreen.V135.Message
import Evergreen.V135.NonemptyDict
import Evergreen.V135.NonemptySet
import Evergreen.V135.OneToOne
import Evergreen.V135.SecretId
import Evergreen.V135.SessionIdHash
import Evergreen.V135.Slack
import Evergreen.V135.TextEditor
import Evergreen.V135.Thread
import Evergreen.V135.User
import Evergreen.V135.UserAgent
import Evergreen.V135.UserSession
import Evergreen.V135.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members : Evergreen.V135.NonemptySet.NonemptySet (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId)
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V135.Message.Message Evergreen.V135.Id.ChannelMessageId (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V135.Discord.PartialUser
        , icon : Maybe Evergreen.V135.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V135.Discord.User
        , linkedTo : Evergreen.V135.Id.Id Evergreen.V135.Id.UserId
        , icon : Maybe Evergreen.V135.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V135.User.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V135.Discord.User
        , linkedTo : Evergreen.V135.Id.Id Evergreen.V135.Id.UserId
        , icon : Maybe Evergreen.V135.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V135.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V135.Message.Message Evergreen.V135.Id.ChannelMessageId (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V135.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId) AdminData_DiscordChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V135.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V135.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V135.Id.Id Evergreen.V135.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V135.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId) (LoadingDiscordChannelStep messages)


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V135.Id.Id Evergreen.V135.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V135.Id.Id Evergreen.V135.Id.UserId
    , name : Evergreen.V135.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V135.Message.MessageState Evergreen.V135.Id.ChannelMessageId (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId))
    , visibleMessages : Evergreen.V135.VisibleMessages.VisibleMessages Evergreen.V135.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) (Evergreen.V135.Thread.LastTypedAt Evergreen.V135.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) Evergreen.V135.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V135.Id.Id Evergreen.V135.Id.UserId
    , name : Evergreen.V135.GuildName.GuildName
    , icon : Maybe Evergreen.V135.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V135.Id.Id Evergreen.V135.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V135.SecretId.SecretId Evergreen.V135.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V135.Id.Id Evergreen.V135.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V135.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V135.Message.MessageState Evergreen.V135.Id.ChannelMessageId (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId))
    , visibleMessages : Evergreen.V135.VisibleMessages.VisibleMessages Evergreen.V135.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Evergreen.V135.Thread.LastTypedAt Evergreen.V135.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) Evergreen.V135.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V135.GuildName.GuildName
    , icon : Maybe Evergreen.V135.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V135.NonemptyDict.NonemptyDict (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) Evergreen.V135.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V135.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V135.UserSession.UserSession
    , user : Evergreen.V135.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) Evergreen.V135.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) Evergreen.V135.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) Evergreen.V135.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V135.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) Evergreen.V135.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId) Evergreen.V135.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V135.SessionIdHash.SessionIdHash Evergreen.V135.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V135.TextEditor.LocalState
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V135.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V135.Id.Id Evergreen.V135.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V135.Id.Id Evergreen.V135.Id.UserId
    , name : Evergreen.V135.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V135.Message.Message Evergreen.V135.Id.ChannelMessageId (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) (Evergreen.V135.Thread.LastTypedAt Evergreen.V135.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) Evergreen.V135.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V135.Id.Id Evergreen.V135.Id.UserId
    , name : Evergreen.V135.GuildName.GuildName
    , icon : Maybe Evergreen.V135.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V135.Id.Id Evergreen.V135.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V135.SecretId.SecretId Evergreen.V135.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V135.Id.Id Evergreen.V135.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V135.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V135.Message.Message Evergreen.V135.Id.ChannelMessageId (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Evergreen.V135.Thread.LastTypedAt Evergreen.V135.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V135.OneToOne.OneToOne (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.MessageId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) Evergreen.V135.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V135.GuildName.GuildName
    , icon : Maybe Evergreen.V135.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId
    }
