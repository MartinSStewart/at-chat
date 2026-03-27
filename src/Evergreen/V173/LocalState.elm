module Evergreen.V173.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V173.ChannelDescription
import Evergreen.V173.ChannelName
import Evergreen.V173.Discord
import Evergreen.V173.DiscordUserData
import Evergreen.V173.DmChannel
import Evergreen.V173.FileStatus
import Evergreen.V173.GuildName
import Evergreen.V173.Id
import Evergreen.V173.Log
import Evergreen.V173.MembersAndOwner
import Evergreen.V173.Message
import Evergreen.V173.NonemptyDict
import Evergreen.V173.OneToOne
import Evergreen.V173.Pagination
import Evergreen.V173.SecretId
import Evergreen.V173.SessionIdHash
import Evergreen.V173.Slack
import Evergreen.V173.TextEditor
import Evergreen.V173.Thread
import Evergreen.V173.User
import Evergreen.V173.UserAgent
import Evergreen.V173.UserSession
import Evergreen.V173.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V173.NonemptyDict.NonemptyDict
            (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V173.Message.Message Evergreen.V173.Id.ChannelMessageId (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V173.Discord.PartialUser
        , icon : Maybe Evergreen.V173.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V173.Discord.User
        , linkedTo : Evergreen.V173.Id.Id Evergreen.V173.Id.UserId
        , icon : Maybe Evergreen.V173.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V173.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V173.Discord.User
        , linkedTo : Evergreen.V173.Id.Id Evergreen.V173.Id.UserId
        , icon : Maybe Evergreen.V173.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V173.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V173.Message.Message Evergreen.V173.Id.ChannelMessageId (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V173.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V173.MembersAndOwner.MembersAndOwner
            (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V173.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V173.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V173.Id.Id Evergreen.V173.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V173.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V173.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V173.Id.Id Evergreen.V173.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V173.Id.Id Evergreen.V173.Id.UserId
    , name : Evergreen.V173.ChannelName.ChannelName
    , description : Evergreen.V173.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V173.Message.MessageState Evergreen.V173.Id.ChannelMessageId (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId))
    , visibleMessages : Evergreen.V173.VisibleMessages.VisibleMessages Evergreen.V173.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) (Evergreen.V173.Thread.LastTypedAt Evergreen.V173.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) Evergreen.V173.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V173.Id.Id Evergreen.V173.Id.UserId
    , name : Evergreen.V173.GuildName.GuildName
    , icon : Maybe Evergreen.V173.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V173.MembersAndOwner.MembersAndOwner
            (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V173.SecretId.SecretId Evergreen.V173.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V173.Id.Id Evergreen.V173.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V173.ChannelName.ChannelName
    , description : Evergreen.V173.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V173.Message.MessageState Evergreen.V173.Id.ChannelMessageId (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId))
    , visibleMessages : Evergreen.V173.VisibleMessages.VisibleMessages Evergreen.V173.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Evergreen.V173.Thread.LastTypedAt Evergreen.V173.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) Evergreen.V173.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V173.GuildName.GuildName
    , icon : Maybe Evergreen.V173.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V173.MembersAndOwner.MembersAndOwner
            (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V173.NonemptyDict.NonemptyDict (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) Evergreen.V173.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V173.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V173.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V173.SessionIdHash.SessionIdHash (Evergreen.V173.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V173.UserSession.UserSession
    , user : Evergreen.V173.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) Evergreen.V173.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) Evergreen.V173.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) Evergreen.V173.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V173.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) Evergreen.V173.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId) Evergreen.V173.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V173.SessionIdHash.SessionIdHash Evergreen.V173.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V173.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V173.Id.Id Evergreen.V173.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V173.Id.Id Evergreen.V173.Id.UserId
    , name : Evergreen.V173.ChannelName.ChannelName
    , description : Evergreen.V173.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V173.Message.Message Evergreen.V173.Id.ChannelMessageId (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) (Evergreen.V173.Thread.LastTypedAt Evergreen.V173.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) Evergreen.V173.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V173.Id.Id Evergreen.V173.Id.UserId
    , name : Evergreen.V173.GuildName.GuildName
    , icon : Maybe Evergreen.V173.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V173.MembersAndOwner.MembersAndOwner
            (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V173.SecretId.SecretId Evergreen.V173.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V173.Id.Id Evergreen.V173.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V173.ChannelName.ChannelName
    , description : Evergreen.V173.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V173.Message.Message Evergreen.V173.Id.ChannelMessageId (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Evergreen.V173.Thread.LastTypedAt Evergreen.V173.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V173.OneToOne.OneToOne (Evergreen.V173.Discord.Id Evergreen.V173.Discord.MessageId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) Evergreen.V173.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V173.GuildName.GuildName
    , icon : Maybe Evergreen.V173.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V173.MembersAndOwner.MembersAndOwner
            (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }
