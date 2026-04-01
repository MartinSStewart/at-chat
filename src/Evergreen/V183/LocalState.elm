module Evergreen.V183.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V183.ChannelDescription
import Evergreen.V183.ChannelName
import Evergreen.V183.Discord
import Evergreen.V183.DiscordUserData
import Evergreen.V183.DmChannel
import Evergreen.V183.FileStatus
import Evergreen.V183.GuildName
import Evergreen.V183.Id
import Evergreen.V183.Log
import Evergreen.V183.MembersAndOwner
import Evergreen.V183.Message
import Evergreen.V183.NonemptyDict
import Evergreen.V183.OneToOne
import Evergreen.V183.Pagination
import Evergreen.V183.SecretId
import Evergreen.V183.SessionIdHash
import Evergreen.V183.Slack
import Evergreen.V183.TextEditor
import Evergreen.V183.Thread
import Evergreen.V183.User
import Evergreen.V183.UserAgent
import Evergreen.V183.UserSession
import Evergreen.V183.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V183.NonemptyDict.NonemptyDict
            (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V183.Message.Message Evergreen.V183.Id.ChannelMessageId (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V183.Discord.PartialUser
        , icon : Maybe Evergreen.V183.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V183.Discord.User
        , linkedTo : Evergreen.V183.Id.Id Evergreen.V183.Id.UserId
        , icon : Maybe Evergreen.V183.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V183.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V183.Discord.User
        , linkedTo : Evergreen.V183.Id.Id Evergreen.V183.Id.UserId
        , icon : Maybe Evergreen.V183.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V183.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V183.Message.Message Evergreen.V183.Id.ChannelMessageId (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V183.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V183.MembersAndOwner.MembersAndOwner
            (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V183.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V183.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V183.Id.Id Evergreen.V183.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V183.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V183.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V183.Id.Id Evergreen.V183.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V183.Id.Id Evergreen.V183.Id.UserId
    , name : Evergreen.V183.ChannelName.ChannelName
    , description : Evergreen.V183.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V183.Message.MessageState Evergreen.V183.Id.ChannelMessageId (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId))
    , visibleMessages : Evergreen.V183.VisibleMessages.VisibleMessages Evergreen.V183.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) (Evergreen.V183.Thread.LastTypedAt Evergreen.V183.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) Evergreen.V183.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V183.Id.Id Evergreen.V183.Id.UserId
    , name : Evergreen.V183.GuildName.GuildName
    , icon : Maybe Evergreen.V183.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V183.MembersAndOwner.MembersAndOwner
            (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V183.SecretId.SecretId Evergreen.V183.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V183.Id.Id Evergreen.V183.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V183.ChannelName.ChannelName
    , description : Evergreen.V183.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V183.Message.MessageState Evergreen.V183.Id.ChannelMessageId (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId))
    , visibleMessages : Evergreen.V183.VisibleMessages.VisibleMessages Evergreen.V183.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Evergreen.V183.Thread.LastTypedAt Evergreen.V183.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) Evergreen.V183.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V183.GuildName.GuildName
    , icon : Maybe Evergreen.V183.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V183.MembersAndOwner.MembersAndOwner
            (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V183.NonemptyDict.NonemptyDict (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) Evergreen.V183.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V183.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V183.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V183.SessionIdHash.SessionIdHash (Evergreen.V183.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V183.UserSession.UserSession
    , user : Evergreen.V183.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) Evergreen.V183.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) Evergreen.V183.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) Evergreen.V183.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V183.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) Evergreen.V183.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId) Evergreen.V183.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V183.SessionIdHash.SessionIdHash Evergreen.V183.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V183.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V183.Id.Id Evergreen.V183.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V183.Id.Id Evergreen.V183.Id.UserId
    , name : Evergreen.V183.ChannelName.ChannelName
    , description : Evergreen.V183.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V183.Message.Message Evergreen.V183.Id.ChannelMessageId (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) (Evergreen.V183.Thread.LastTypedAt Evergreen.V183.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) Evergreen.V183.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V183.Id.Id Evergreen.V183.Id.UserId
    , name : Evergreen.V183.GuildName.GuildName
    , icon : Maybe Evergreen.V183.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V183.MembersAndOwner.MembersAndOwner
            (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V183.SecretId.SecretId Evergreen.V183.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V183.Id.Id Evergreen.V183.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V183.ChannelName.ChannelName
    , description : Evergreen.V183.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V183.Message.Message Evergreen.V183.Id.ChannelMessageId (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Evergreen.V183.Thread.LastTypedAt Evergreen.V183.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V183.OneToOne.OneToOne (Evergreen.V183.Discord.Id Evergreen.V183.Discord.MessageId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) Evergreen.V183.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V183.GuildName.GuildName
    , icon : Maybe Evergreen.V183.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V183.MembersAndOwner.MembersAndOwner
            (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }
