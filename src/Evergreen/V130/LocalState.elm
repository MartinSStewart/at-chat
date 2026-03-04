module Evergreen.V130.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V130.ChannelName
import Evergreen.V130.Discord
import Evergreen.V130.Discord.Id
import Evergreen.V130.DmChannel
import Evergreen.V130.FileStatus
import Evergreen.V130.GuildName
import Evergreen.V130.Id
import Evergreen.V130.Log
import Evergreen.V130.Message
import Evergreen.V130.NonemptyDict
import Evergreen.V130.NonemptySet
import Evergreen.V130.OneToOne
import Evergreen.V130.SecretId
import Evergreen.V130.SessionIdHash
import Evergreen.V130.Slack
import Evergreen.V130.TextEditor
import Evergreen.V130.Thread
import Evergreen.V130.User
import Evergreen.V130.UserAgent
import Evergreen.V130.UserSession
import Evergreen.V130.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members : Evergreen.V130.NonemptySet.NonemptySet (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId)
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V130.Message.Message Evergreen.V130.Id.ChannelMessageId (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V130.Discord.PartialUser
        , icon : Maybe Evergreen.V130.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V130.Discord.User
        , linkedTo : Evergreen.V130.Id.Id Evergreen.V130.Id.UserId
        , icon : Maybe Evergreen.V130.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V130.User.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V130.Discord.User
        , linkedTo : Evergreen.V130.Id.Id Evergreen.V130.Id.UserId
        , icon : Maybe Evergreen.V130.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V130.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V130.Message.Message Evergreen.V130.Id.ChannelMessageId (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V130.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId) AdminData_DiscordChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V130.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V130.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V130.Id.Id Evergreen.V130.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V130.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId) (LoadingDiscordChannelStep messages)


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V130.Id.Id Evergreen.V130.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V130.Id.Id Evergreen.V130.Id.UserId
    , name : Evergreen.V130.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V130.Message.MessageState Evergreen.V130.Id.ChannelMessageId (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId))
    , visibleMessages : Evergreen.V130.VisibleMessages.VisibleMessages Evergreen.V130.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) (Evergreen.V130.Thread.LastTypedAt Evergreen.V130.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) Evergreen.V130.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V130.Id.Id Evergreen.V130.Id.UserId
    , name : Evergreen.V130.GuildName.GuildName
    , icon : Maybe Evergreen.V130.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V130.Id.Id Evergreen.V130.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V130.SecretId.SecretId Evergreen.V130.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V130.Id.Id Evergreen.V130.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V130.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V130.Message.MessageState Evergreen.V130.Id.ChannelMessageId (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId))
    , visibleMessages : Evergreen.V130.VisibleMessages.VisibleMessages Evergreen.V130.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (Evergreen.V130.Thread.LastTypedAt Evergreen.V130.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) Evergreen.V130.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V130.GuildName.GuildName
    , icon : Maybe Evergreen.V130.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V130.NonemptyDict.NonemptyDict (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) Evergreen.V130.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V130.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (LoadingDiscordChannel Int)
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V130.UserSession.UserSession
    , user : Evergreen.V130.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) Evergreen.V130.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) Evergreen.V130.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) Evergreen.V130.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V130.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) Evergreen.V130.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId) Evergreen.V130.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V130.SessionIdHash.SessionIdHash Evergreen.V130.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V130.TextEditor.LocalState
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V130.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V130.Id.Id Evergreen.V130.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V130.Id.Id Evergreen.V130.Id.UserId
    , name : Evergreen.V130.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V130.Message.Message Evergreen.V130.Id.ChannelMessageId (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) (Evergreen.V130.Thread.LastTypedAt Evergreen.V130.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) Evergreen.V130.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V130.Id.Id Evergreen.V130.Id.UserId
    , name : Evergreen.V130.GuildName.GuildName
    , icon : Maybe Evergreen.V130.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V130.Id.Id Evergreen.V130.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V130.SecretId.SecretId Evergreen.V130.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V130.Id.Id Evergreen.V130.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V130.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V130.Message.Message Evergreen.V130.Id.ChannelMessageId (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (Evergreen.V130.Thread.LastTypedAt Evergreen.V130.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V130.OneToOne.OneToOne (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.MessageId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) Evergreen.V130.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V130.GuildName.GuildName
    , icon : Maybe Evergreen.V130.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId
    }
