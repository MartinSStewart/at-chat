module Evergreen.V175.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V175.ChannelDescription
import Evergreen.V175.ChannelName
import Evergreen.V175.Discord
import Evergreen.V175.DiscordUserData
import Evergreen.V175.DmChannel
import Evergreen.V175.FileStatus
import Evergreen.V175.GuildName
import Evergreen.V175.Id
import Evergreen.V175.Log
import Evergreen.V175.MembersAndOwner
import Evergreen.V175.Message
import Evergreen.V175.NonemptyDict
import Evergreen.V175.OneToOne
import Evergreen.V175.Pagination
import Evergreen.V175.SecretId
import Evergreen.V175.SessionIdHash
import Evergreen.V175.Slack
import Evergreen.V175.TextEditor
import Evergreen.V175.Thread
import Evergreen.V175.User
import Evergreen.V175.UserAgent
import Evergreen.V175.UserSession
import Evergreen.V175.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V175.NonemptyDict.NonemptyDict
            (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V175.Message.Message Evergreen.V175.Id.ChannelMessageId (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V175.Discord.PartialUser
        , icon : Maybe Evergreen.V175.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V175.Discord.User
        , linkedTo : Evergreen.V175.Id.Id Evergreen.V175.Id.UserId
        , icon : Maybe Evergreen.V175.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V175.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V175.Discord.User
        , linkedTo : Evergreen.V175.Id.Id Evergreen.V175.Id.UserId
        , icon : Maybe Evergreen.V175.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V175.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V175.Message.Message Evergreen.V175.Id.ChannelMessageId (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V175.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V175.MembersAndOwner.MembersAndOwner
            (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V175.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V175.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V175.Id.Id Evergreen.V175.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V175.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V175.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V175.Id.Id Evergreen.V175.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V175.Id.Id Evergreen.V175.Id.UserId
    , name : Evergreen.V175.ChannelName.ChannelName
    , description : Evergreen.V175.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V175.Message.MessageState Evergreen.V175.Id.ChannelMessageId (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId))
    , visibleMessages : Evergreen.V175.VisibleMessages.VisibleMessages Evergreen.V175.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) (Evergreen.V175.Thread.LastTypedAt Evergreen.V175.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) Evergreen.V175.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V175.Id.Id Evergreen.V175.Id.UserId
    , name : Evergreen.V175.GuildName.GuildName
    , icon : Maybe Evergreen.V175.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V175.MembersAndOwner.MembersAndOwner
            (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V175.SecretId.SecretId Evergreen.V175.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V175.Id.Id Evergreen.V175.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V175.ChannelName.ChannelName
    , description : Evergreen.V175.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V175.Message.MessageState Evergreen.V175.Id.ChannelMessageId (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId))
    , visibleMessages : Evergreen.V175.VisibleMessages.VisibleMessages Evergreen.V175.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Evergreen.V175.Thread.LastTypedAt Evergreen.V175.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) Evergreen.V175.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V175.GuildName.GuildName
    , icon : Maybe Evergreen.V175.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V175.MembersAndOwner.MembersAndOwner
            (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V175.NonemptyDict.NonemptyDict (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) Evergreen.V175.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V175.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V175.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V175.SessionIdHash.SessionIdHash (Evergreen.V175.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V175.UserSession.UserSession
    , user : Evergreen.V175.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) Evergreen.V175.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) Evergreen.V175.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) Evergreen.V175.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V175.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) Evergreen.V175.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId) Evergreen.V175.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V175.SessionIdHash.SessionIdHash Evergreen.V175.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V175.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V175.Id.Id Evergreen.V175.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V175.Id.Id Evergreen.V175.Id.UserId
    , name : Evergreen.V175.ChannelName.ChannelName
    , description : Evergreen.V175.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V175.Message.Message Evergreen.V175.Id.ChannelMessageId (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) (Evergreen.V175.Thread.LastTypedAt Evergreen.V175.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) Evergreen.V175.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V175.Id.Id Evergreen.V175.Id.UserId
    , name : Evergreen.V175.GuildName.GuildName
    , icon : Maybe Evergreen.V175.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V175.MembersAndOwner.MembersAndOwner
            (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V175.SecretId.SecretId Evergreen.V175.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V175.Id.Id Evergreen.V175.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V175.ChannelName.ChannelName
    , description : Evergreen.V175.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V175.Message.Message Evergreen.V175.Id.ChannelMessageId (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Evergreen.V175.Thread.LastTypedAt Evergreen.V175.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V175.OneToOne.OneToOne (Evergreen.V175.Discord.Id Evergreen.V175.Discord.MessageId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) Evergreen.V175.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V175.GuildName.GuildName
    , icon : Maybe Evergreen.V175.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V175.MembersAndOwner.MembersAndOwner
            (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }
