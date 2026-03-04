module Evergreen.V125.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V125.ChannelName
import Evergreen.V125.Discord
import Evergreen.V125.Discord.Id
import Evergreen.V125.DmChannel
import Evergreen.V125.FileStatus
import Evergreen.V125.GuildName
import Evergreen.V125.Id
import Evergreen.V125.Log
import Evergreen.V125.Message
import Evergreen.V125.NonemptyDict
import Evergreen.V125.NonemptySet
import Evergreen.V125.OneToOne
import Evergreen.V125.SecretId
import Evergreen.V125.SessionIdHash
import Evergreen.V125.Slack
import Evergreen.V125.TextEditor
import Evergreen.V125.Thread
import Evergreen.V125.User
import Evergreen.V125.UserAgent
import Evergreen.V125.UserSession
import Evergreen.V125.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members : Evergreen.V125.NonemptySet.NonemptySet (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId)
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V125.Message.Message Evergreen.V125.Id.ChannelMessageId (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId))
    , isReloading : Evergreen.V125.DmChannel.DiscordChannelReloadingStatus
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V125.Discord.PartialUser
        , icon : Maybe Evergreen.V125.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V125.Discord.User
        , linkedTo : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
        , icon : Maybe Evergreen.V125.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V125.User.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V125.Discord.User
        , linkedTo : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
        , icon : Maybe Evergreen.V125.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V125.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , isReloading : Evergreen.V125.DmChannel.DiscordChannelReloadingStatus
    , firstMessage : Maybe (Evergreen.V125.Message.Message Evergreen.V125.Id.ChannelMessageId (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V125.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId) AdminData_DiscordChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V125.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V125.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
    }


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
    , name : Evergreen.V125.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V125.Message.MessageState Evergreen.V125.Id.ChannelMessageId (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId))
    , visibleMessages : Evergreen.V125.VisibleMessages.VisibleMessages Evergreen.V125.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) (Evergreen.V125.Thread.LastTypedAt Evergreen.V125.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) Evergreen.V125.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
    , name : Evergreen.V125.GuildName.GuildName
    , icon : Maybe Evergreen.V125.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V125.SecretId.SecretId Evergreen.V125.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V125.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V125.Message.MessageState Evergreen.V125.Id.ChannelMessageId (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId))
    , visibleMessages : Evergreen.V125.VisibleMessages.VisibleMessages Evergreen.V125.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) (Evergreen.V125.Thread.LastTypedAt Evergreen.V125.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) Evergreen.V125.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V125.GuildName.GuildName
    , icon : Maybe Evergreen.V125.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId) DiscordFrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V125.NonemptyDict.NonemptyDict (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) Evergreen.V125.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V125.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) AdminData_Guild
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V125.UserSession.UserSession
    , user : Evergreen.V125.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) Evergreen.V125.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) Evergreen.V125.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) Evergreen.V125.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V125.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) Evergreen.V125.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId) Evergreen.V125.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V125.SessionIdHash.SessionIdHash Evergreen.V125.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V125.TextEditor.LocalState
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V125.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
    , name : Evergreen.V125.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V125.Message.Message Evergreen.V125.Id.ChannelMessageId (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) (Evergreen.V125.Thread.LastTypedAt Evergreen.V125.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) Evergreen.V125.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
    , name : Evergreen.V125.GuildName.GuildName
    , icon : Maybe Evergreen.V125.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V125.SecretId.SecretId Evergreen.V125.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V125.ChannelName.ChannelName
    , messages : Array.Array (Evergreen.V125.Message.Message Evergreen.V125.Id.ChannelMessageId (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) (Evergreen.V125.Thread.LastTypedAt Evergreen.V125.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V125.OneToOne.OneToOne (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.MessageId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) Evergreen.V125.Thread.DiscordBackendThread
    , isReloading : Evergreen.V125.DmChannel.DiscordChannelReloadingStatus
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V125.GuildName.GuildName
    , icon : Maybe Evergreen.V125.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId) DiscordBackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId
    }
