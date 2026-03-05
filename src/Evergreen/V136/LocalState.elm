module Evergreen.V136.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V136.ChannelName
import Evergreen.V136.Discord
import Evergreen.V136.Discord.Id
import Evergreen.V136.DmChannel
import Evergreen.V136.FileStatus
import Evergreen.V136.GuildName
import Evergreen.V136.Id
import Evergreen.V136.Log
import Evergreen.V136.Message
import Evergreen.V136.NonemptyDict
import Evergreen.V136.NonemptySet
import Evergreen.V136.OneToOne
import Evergreen.V136.SecretId
import Evergreen.V136.SessionIdHash
import Evergreen.V136.Slack
import Evergreen.V136.TextEditor
import Evergreen.V136.Thread
import Evergreen.V136.User
import Evergreen.V136.UserAgent
import Evergreen.V136.UserSession
import Evergreen.V136.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members : Evergreen.V136.NonemptySet.NonemptySet (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId)
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V136.Message.Message Evergreen.V136.Id.ChannelMessageId (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V136.Discord.PartialUser
        , icon : Maybe Evergreen.V136.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V136.Discord.User
        , linkedTo : Evergreen.V136.Id.Id Evergreen.V136.Id.UserId
        , icon : Maybe Evergreen.V136.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V136.User.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V136.Discord.User
        , linkedTo : Evergreen.V136.Id.Id Evergreen.V136.Id.UserId
        , icon : Maybe Evergreen.V136.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V136.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V136.Message.Message Evergreen.V136.Id.ChannelMessageId (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V136.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId) AdminData_DiscordChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V136.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V136.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V136.Id.Id Evergreen.V136.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V136.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId) (LoadingDiscordChannelStep messages)


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V136.Id.Id Evergreen.V136.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V136.Id.Id Evergreen.V136.Id.UserId
    , name : Evergreen.V136.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V136.Message.MessageState Evergreen.V136.Id.ChannelMessageId (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId))
    , visibleMessages : Evergreen.V136.VisibleMessages.VisibleMessages Evergreen.V136.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) (Evergreen.V136.Thread.LastTypedAt Evergreen.V136.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) Evergreen.V136.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V136.Id.Id Evergreen.V136.Id.UserId
    , name : Evergreen.V136.GuildName.GuildName
    , icon : Maybe Evergreen.V136.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V136.Id.Id Evergreen.V136.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V136.SecretId.SecretId Evergreen.V136.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V136.Id.Id Evergreen.V136.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V136.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V136.Message.MessageState Evergreen.V136.Id.ChannelMessageId (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId))
    , visibleMessages : Evergreen.V136.VisibleMessages.VisibleMessages Evergreen.V136.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Evergreen.V136.Thread.LastTypedAt Evergreen.V136.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) Evergreen.V136.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V136.GuildName.GuildName
    , icon : Maybe Evergreen.V136.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V136.NonemptyDict.NonemptyDict (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) Evergreen.V136.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V136.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V136.UserSession.UserSession
    , user : Evergreen.V136.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) Evergreen.V136.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) Evergreen.V136.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) Evergreen.V136.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V136.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) Evergreen.V136.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId) Evergreen.V136.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V136.SessionIdHash.SessionIdHash Evergreen.V136.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V136.TextEditor.LocalState
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V136.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V136.Id.Id Evergreen.V136.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V136.Id.Id Evergreen.V136.Id.UserId
    , name : Evergreen.V136.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V136.Message.Message Evergreen.V136.Id.ChannelMessageId (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) (Evergreen.V136.Thread.LastTypedAt Evergreen.V136.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) Evergreen.V136.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V136.Id.Id Evergreen.V136.Id.UserId
    , name : Evergreen.V136.GuildName.GuildName
    , icon : Maybe Evergreen.V136.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V136.Id.Id Evergreen.V136.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V136.SecretId.SecretId Evergreen.V136.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V136.Id.Id Evergreen.V136.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V136.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V136.Message.Message Evergreen.V136.Id.ChannelMessageId (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Evergreen.V136.Thread.LastTypedAt Evergreen.V136.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V136.OneToOne.OneToOne (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.MessageId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) Evergreen.V136.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V136.GuildName.GuildName
    , icon : Maybe Evergreen.V136.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId
    }
