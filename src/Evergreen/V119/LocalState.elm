module Evergreen.V119.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V119.ChannelName
import Evergreen.V119.Discord
import Evergreen.V119.Discord.Id
import Evergreen.V119.DmChannel
import Evergreen.V119.FileStatus
import Evergreen.V119.GuildName
import Evergreen.V119.Id
import Evergreen.V119.Log
import Evergreen.V119.Message
import Evergreen.V119.NonemptyDict
import Evergreen.V119.NonemptySet
import Evergreen.V119.OneToOne
import Evergreen.V119.SecretId
import Evergreen.V119.SessionIdHash
import Evergreen.V119.Slack
import Evergreen.V119.TextEditor
import Evergreen.V119.Thread
import Evergreen.V119.User
import Evergreen.V119.UserAgent
import Evergreen.V119.UserSession
import Evergreen.V119.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V119.Discord.PartialUser
        , icon : Maybe Evergreen.V119.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V119.Discord.User
        , linkedTo : Evergreen.V119.Id.Id Evergreen.V119.Id.UserId
        , icon : Maybe Evergreen.V119.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V119.User.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V119.Discord.User
        , linkedTo : Evergreen.V119.Id.Id Evergreen.V119.Id.UserId
        , icon : Maybe Evergreen.V119.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V119.Id.Id Evergreen.V119.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V119.Id.Id Evergreen.V119.Id.UserId
    , name : Evergreen.V119.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V119.Message.MessageState Evergreen.V119.Id.ChannelMessageId (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId))
    , visibleMessages : Evergreen.V119.VisibleMessages.VisibleMessages Evergreen.V119.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) (Evergreen.V119.Thread.LastTypedAt Evergreen.V119.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) Evergreen.V119.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V119.Id.Id Evergreen.V119.Id.UserId
    , name : Evergreen.V119.GuildName.GuildName
    , icon : Maybe Evergreen.V119.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V119.Id.Id Evergreen.V119.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V119.SecretId.SecretId Evergreen.V119.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V119.Id.Id Evergreen.V119.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V119.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V119.Message.MessageState Evergreen.V119.Id.ChannelMessageId (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId))
    , visibleMessages : Evergreen.V119.VisibleMessages.VisibleMessages Evergreen.V119.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) (Evergreen.V119.Thread.LastTypedAt Evergreen.V119.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) Evergreen.V119.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V119.GuildName.GuildName
    , icon : Maybe Evergreen.V119.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V119.NonemptyDict.NonemptyDict (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) Evergreen.V119.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V119.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels :
        SeqDict.SeqDict
            (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.PrivateChannelId)
            { members : Evergreen.V119.NonemptySet.NonemptySet (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId)
            , messageCount : Int
            }
    , discordUsers : SeqDict.SeqDict (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) DiscordUserData_ForAdmin
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V119.UserSession.UserSession
    , user : Evergreen.V119.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) Evergreen.V119.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) Evergreen.V119.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) Evergreen.V119.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V119.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) Evergreen.V119.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.PrivateChannelId) Evergreen.V119.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V119.SessionIdHash.SessionIdHash Evergreen.V119.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V119.TextEditor.LocalState
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V119.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V119.Id.Id Evergreen.V119.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V119.Id.Id Evergreen.V119.Id.UserId
    , name : Evergreen.V119.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V119.Message.Message Evergreen.V119.Id.ChannelMessageId (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) (Evergreen.V119.Thread.LastTypedAt Evergreen.V119.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) Evergreen.V119.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V119.Id.Id Evergreen.V119.Id.UserId
    , name : Evergreen.V119.GuildName.GuildName
    , icon : Maybe Evergreen.V119.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V119.Id.Id Evergreen.V119.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V119.SecretId.SecretId Evergreen.V119.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V119.Id.Id Evergreen.V119.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V119.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V119.Message.Message Evergreen.V119.Id.ChannelMessageId (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) (Evergreen.V119.Thread.LastTypedAt Evergreen.V119.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V119.OneToOne.OneToOne (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.MessageId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) Evergreen.V119.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V119.GuildName.GuildName
    , icon : Maybe Evergreen.V119.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId
    }
