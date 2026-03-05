module Evergreen.V134.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V134.ChannelName
import Evergreen.V134.Discord
import Evergreen.V134.Discord.Id
import Evergreen.V134.DmChannel
import Evergreen.V134.FileStatus
import Evergreen.V134.GuildName
import Evergreen.V134.Id
import Evergreen.V134.Log
import Evergreen.V134.Message
import Evergreen.V134.NonemptyDict
import Evergreen.V134.NonemptySet
import Evergreen.V134.OneToOne
import Evergreen.V134.SecretId
import Evergreen.V134.SessionIdHash
import Evergreen.V134.Slack
import Evergreen.V134.TextEditor
import Evergreen.V134.Thread
import Evergreen.V134.User
import Evergreen.V134.UserAgent
import Evergreen.V134.UserSession
import Evergreen.V134.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members : Evergreen.V134.NonemptySet.NonemptySet (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId)
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V134.Message.Message Evergreen.V134.Id.ChannelMessageId (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V134.Discord.PartialUser
        , icon : Maybe Evergreen.V134.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V134.Discord.User
        , linkedTo : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
        , icon : Maybe Evergreen.V134.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V134.User.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V134.Discord.User
        , linkedTo : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
        , icon : Maybe Evergreen.V134.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V134.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V134.Message.Message Evergreen.V134.Id.ChannelMessageId (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V134.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId) AdminData_DiscordChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V134.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V134.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V134.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId) (LoadingDiscordChannelStep messages)


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
    , name : Evergreen.V134.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V134.Message.MessageState Evergreen.V134.Id.ChannelMessageId (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId))
    , visibleMessages : Evergreen.V134.VisibleMessages.VisibleMessages Evergreen.V134.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) (Evergreen.V134.Thread.LastTypedAt Evergreen.V134.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) Evergreen.V134.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
    , name : Evergreen.V134.GuildName.GuildName
    , icon : Maybe Evergreen.V134.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V134.SecretId.SecretId Evergreen.V134.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V134.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V134.Message.MessageState Evergreen.V134.Id.ChannelMessageId (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId))
    , visibleMessages : Evergreen.V134.VisibleMessages.VisibleMessages Evergreen.V134.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Evergreen.V134.Thread.LastTypedAt Evergreen.V134.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) Evergreen.V134.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V134.GuildName.GuildName
    , icon : Maybe Evergreen.V134.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V134.NonemptyDict.NonemptyDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V134.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (LoadingDiscordChannel Int)
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V134.UserSession.UserSession
    , user : Evergreen.V134.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) Evergreen.V134.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) Evergreen.V134.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V134.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId) Evergreen.V134.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V134.SessionIdHash.SessionIdHash Evergreen.V134.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V134.TextEditor.LocalState
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V134.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
    , name : Evergreen.V134.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V134.Message.Message Evergreen.V134.Id.ChannelMessageId (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) (Evergreen.V134.Thread.LastTypedAt Evergreen.V134.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) Evergreen.V134.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
    , name : Evergreen.V134.GuildName.GuildName
    , icon : Maybe Evergreen.V134.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V134.SecretId.SecretId Evergreen.V134.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V134.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V134.Message.Message Evergreen.V134.Id.ChannelMessageId (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Evergreen.V134.Thread.LastTypedAt Evergreen.V134.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V134.OneToOne.OneToOne (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.MessageId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) Evergreen.V134.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V134.GuildName.GuildName
    , icon : Maybe Evergreen.V134.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId
    }
