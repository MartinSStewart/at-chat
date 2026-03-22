module Evergreen.V167.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V167.ChannelDescription
import Evergreen.V167.ChannelName
import Evergreen.V167.Discord
import Evergreen.V167.DiscordUserData
import Evergreen.V167.DmChannel
import Evergreen.V167.FileStatus
import Evergreen.V167.GuildName
import Evergreen.V167.Id
import Evergreen.V167.Log
import Evergreen.V167.MembersAndOwner
import Evergreen.V167.Message
import Evergreen.V167.NonemptyDict
import Evergreen.V167.OneToOne
import Evergreen.V167.Pagination
import Evergreen.V167.SecretId
import Evergreen.V167.SessionIdHash
import Evergreen.V167.Slack
import Evergreen.V167.TextEditor
import Evergreen.V167.Thread
import Evergreen.V167.User
import Evergreen.V167.UserAgent
import Evergreen.V167.UserSession
import Evergreen.V167.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V167.NonemptyDict.NonemptyDict
            (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V167.Message.Message Evergreen.V167.Id.ChannelMessageId (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V167.Discord.PartialUser
        , icon : Maybe Evergreen.V167.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V167.Discord.User
        , linkedTo : Evergreen.V167.Id.Id Evergreen.V167.Id.UserId
        , icon : Maybe Evergreen.V167.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V167.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V167.Discord.User
        , linkedTo : Evergreen.V167.Id.Id Evergreen.V167.Id.UserId
        , icon : Maybe Evergreen.V167.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V167.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V167.Message.Message Evergreen.V167.Id.ChannelMessageId (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V167.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V167.MembersAndOwner.MembersAndOwner
            (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V167.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V167.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V167.Id.Id Evergreen.V167.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V167.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V167.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V167.Id.Id Evergreen.V167.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V167.Id.Id Evergreen.V167.Id.UserId
    , name : Evergreen.V167.ChannelName.ChannelName
    , description : Evergreen.V167.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V167.Message.MessageState Evergreen.V167.Id.ChannelMessageId (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId))
    , visibleMessages : Evergreen.V167.VisibleMessages.VisibleMessages Evergreen.V167.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) (Evergreen.V167.Thread.LastTypedAt Evergreen.V167.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) Evergreen.V167.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V167.Id.Id Evergreen.V167.Id.UserId
    , name : Evergreen.V167.GuildName.GuildName
    , icon : Maybe Evergreen.V167.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V167.MembersAndOwner.MembersAndOwner
            (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V167.SecretId.SecretId Evergreen.V167.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V167.Id.Id Evergreen.V167.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V167.ChannelName.ChannelName
    , description : Evergreen.V167.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V167.Message.MessageState Evergreen.V167.Id.ChannelMessageId (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId))
    , visibleMessages : Evergreen.V167.VisibleMessages.VisibleMessages Evergreen.V167.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Evergreen.V167.Thread.LastTypedAt Evergreen.V167.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) Evergreen.V167.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V167.GuildName.GuildName
    , icon : Maybe Evergreen.V167.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V167.MembersAndOwner.MembersAndOwner
            (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V167.NonemptyDict.NonemptyDict (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) Evergreen.V167.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V167.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V167.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V167.SessionIdHash.SessionIdHash (Evergreen.V167.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V167.UserSession.UserSession
    , user : Evergreen.V167.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) Evergreen.V167.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) Evergreen.V167.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) Evergreen.V167.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V167.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) Evergreen.V167.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId) Evergreen.V167.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V167.SessionIdHash.SessionIdHash Evergreen.V167.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V167.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V167.Id.Id Evergreen.V167.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V167.Id.Id Evergreen.V167.Id.UserId
    , name : Evergreen.V167.ChannelName.ChannelName
    , description : Evergreen.V167.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V167.Message.Message Evergreen.V167.Id.ChannelMessageId (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) (Evergreen.V167.Thread.LastTypedAt Evergreen.V167.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) Evergreen.V167.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V167.Id.Id Evergreen.V167.Id.UserId
    , name : Evergreen.V167.GuildName.GuildName
    , icon : Maybe Evergreen.V167.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V167.MembersAndOwner.MembersAndOwner
            (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V167.SecretId.SecretId Evergreen.V167.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V167.Id.Id Evergreen.V167.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V167.ChannelName.ChannelName
    , description : Evergreen.V167.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V167.Message.Message Evergreen.V167.Id.ChannelMessageId (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Evergreen.V167.Thread.LastTypedAt Evergreen.V167.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V167.OneToOne.OneToOne (Evergreen.V167.Discord.Id Evergreen.V167.Discord.MessageId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) Evergreen.V167.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V167.GuildName.GuildName
    , icon : Maybe Evergreen.V167.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V167.MembersAndOwner.MembersAndOwner
            (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }
