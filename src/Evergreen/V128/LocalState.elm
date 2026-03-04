module Evergreen.V128.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V128.ChannelName
import Evergreen.V128.Discord
import Evergreen.V128.Discord.Id
import Evergreen.V128.DmChannel
import Evergreen.V128.FileStatus
import Evergreen.V128.GuildName
import Evergreen.V128.Id
import Evergreen.V128.Log
import Evergreen.V128.Message
import Evergreen.V128.NonemptyDict
import Evergreen.V128.NonemptySet
import Evergreen.V128.OneToOne
import Evergreen.V128.SecretId
import Evergreen.V128.SessionIdHash
import Evergreen.V128.Slack
import Evergreen.V128.TextEditor
import Evergreen.V128.Thread
import Evergreen.V128.User
import Evergreen.V128.UserAgent
import Evergreen.V128.UserSession
import Evergreen.V128.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members : Evergreen.V128.NonemptySet.NonemptySet (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId)
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V128.Message.Message Evergreen.V128.Id.ChannelMessageId (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V128.Discord.PartialUser
        , icon : Maybe Evergreen.V128.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V128.Discord.User
        , linkedTo : Evergreen.V128.Id.Id Evergreen.V128.Id.UserId
        , icon : Maybe Evergreen.V128.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V128.User.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V128.Discord.User
        , linkedTo : Evergreen.V128.Id.Id Evergreen.V128.Id.UserId
        , icon : Maybe Evergreen.V128.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V128.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V128.Message.Message Evergreen.V128.Id.ChannelMessageId (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V128.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId) AdminData_DiscordChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V128.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V128.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V128.Id.Id Evergreen.V128.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V128.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId) (LoadingDiscordChannelStep messages)


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V128.Id.Id Evergreen.V128.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V128.Id.Id Evergreen.V128.Id.UserId
    , name : Evergreen.V128.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V128.Message.MessageState Evergreen.V128.Id.ChannelMessageId (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId))
    , visibleMessages : Evergreen.V128.VisibleMessages.VisibleMessages Evergreen.V128.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) (Evergreen.V128.Thread.LastTypedAt Evergreen.V128.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) Evergreen.V128.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V128.Id.Id Evergreen.V128.Id.UserId
    , name : Evergreen.V128.GuildName.GuildName
    , icon : Maybe Evergreen.V128.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V128.Id.Id Evergreen.V128.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V128.SecretId.SecretId Evergreen.V128.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V128.Id.Id Evergreen.V128.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V128.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V128.Message.MessageState Evergreen.V128.Id.ChannelMessageId (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId))
    , visibleMessages : Evergreen.V128.VisibleMessages.VisibleMessages Evergreen.V128.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (Evergreen.V128.Thread.LastTypedAt Evergreen.V128.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) Evergreen.V128.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V128.GuildName.GuildName
    , icon : Maybe Evergreen.V128.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V128.NonemptyDict.NonemptyDict (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) Evergreen.V128.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V128.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (LoadingDiscordChannel Int)
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V128.UserSession.UserSession
    , user : Evergreen.V128.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) Evergreen.V128.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) Evergreen.V128.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) Evergreen.V128.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V128.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) Evergreen.V128.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId) Evergreen.V128.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V128.SessionIdHash.SessionIdHash Evergreen.V128.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V128.TextEditor.LocalState
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V128.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V128.Id.Id Evergreen.V128.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V128.Id.Id Evergreen.V128.Id.UserId
    , name : Evergreen.V128.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V128.Message.Message Evergreen.V128.Id.ChannelMessageId (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) (Evergreen.V128.Thread.LastTypedAt Evergreen.V128.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) Evergreen.V128.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V128.Id.Id Evergreen.V128.Id.UserId
    , name : Evergreen.V128.GuildName.GuildName
    , icon : Maybe Evergreen.V128.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V128.Id.Id Evergreen.V128.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V128.SecretId.SecretId Evergreen.V128.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V128.Id.Id Evergreen.V128.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V128.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V128.Message.Message Evergreen.V128.Id.ChannelMessageId (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (Evergreen.V128.Thread.LastTypedAt Evergreen.V128.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V128.OneToOne.OneToOne (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.MessageId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) Evergreen.V128.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V128.GuildName.GuildName
    , icon : Maybe Evergreen.V128.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId
    }
