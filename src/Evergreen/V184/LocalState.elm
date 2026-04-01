module Evergreen.V184.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V184.ChannelDescription
import Evergreen.V184.ChannelName
import Evergreen.V184.Discord
import Evergreen.V184.DiscordUserData
import Evergreen.V184.DmChannel
import Evergreen.V184.FileStatus
import Evergreen.V184.GuildName
import Evergreen.V184.Id
import Evergreen.V184.Log
import Evergreen.V184.MembersAndOwner
import Evergreen.V184.Message
import Evergreen.V184.NonemptyDict
import Evergreen.V184.OneToOne
import Evergreen.V184.Pagination
import Evergreen.V184.SecretId
import Evergreen.V184.SessionIdHash
import Evergreen.V184.Slack
import Evergreen.V184.TextEditor
import Evergreen.V184.Thread
import Evergreen.V184.User
import Evergreen.V184.UserAgent
import Evergreen.V184.UserSession
import Evergreen.V184.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V184.NonemptyDict.NonemptyDict
            (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V184.Message.Message Evergreen.V184.Id.ChannelMessageId (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V184.Discord.PartialUser
        , icon : Maybe Evergreen.V184.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V184.Discord.User
        , linkedTo : Evergreen.V184.Id.Id Evergreen.V184.Id.UserId
        , icon : Maybe Evergreen.V184.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V184.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V184.Discord.User
        , linkedTo : Evergreen.V184.Id.Id Evergreen.V184.Id.UserId
        , icon : Maybe Evergreen.V184.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V184.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V184.Message.Message Evergreen.V184.Id.ChannelMessageId (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V184.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V184.MembersAndOwner.MembersAndOwner
            (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V184.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V184.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V184.Id.Id Evergreen.V184.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V184.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V184.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V184.Id.Id Evergreen.V184.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V184.Id.Id Evergreen.V184.Id.UserId
    , name : Evergreen.V184.ChannelName.ChannelName
    , description : Evergreen.V184.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V184.Message.MessageState Evergreen.V184.Id.ChannelMessageId (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId))
    , visibleMessages : Evergreen.V184.VisibleMessages.VisibleMessages Evergreen.V184.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) (Evergreen.V184.Thread.LastTypedAt Evergreen.V184.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) Evergreen.V184.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V184.Id.Id Evergreen.V184.Id.UserId
    , name : Evergreen.V184.GuildName.GuildName
    , icon : Maybe Evergreen.V184.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V184.MembersAndOwner.MembersAndOwner
            (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V184.SecretId.SecretId Evergreen.V184.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V184.Id.Id Evergreen.V184.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V184.ChannelName.ChannelName
    , description : Evergreen.V184.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V184.Message.MessageState Evergreen.V184.Id.ChannelMessageId (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId))
    , visibleMessages : Evergreen.V184.VisibleMessages.VisibleMessages Evergreen.V184.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Evergreen.V184.Thread.LastTypedAt Evergreen.V184.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) Evergreen.V184.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V184.GuildName.GuildName
    , icon : Maybe Evergreen.V184.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V184.MembersAndOwner.MembersAndOwner
            (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V184.NonemptyDict.NonemptyDict (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) Evergreen.V184.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V184.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V184.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V184.SessionIdHash.SessionIdHash (Evergreen.V184.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V184.UserSession.UserSession
    , user : Evergreen.V184.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) Evergreen.V184.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) Evergreen.V184.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) Evergreen.V184.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V184.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) Evergreen.V184.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId) Evergreen.V184.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V184.SessionIdHash.SessionIdHash Evergreen.V184.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V184.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V184.Id.Id Evergreen.V184.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V184.Id.Id Evergreen.V184.Id.UserId
    , name : Evergreen.V184.ChannelName.ChannelName
    , description : Evergreen.V184.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V184.Message.Message Evergreen.V184.Id.ChannelMessageId (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) (Evergreen.V184.Thread.LastTypedAt Evergreen.V184.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) Evergreen.V184.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V184.Id.Id Evergreen.V184.Id.UserId
    , name : Evergreen.V184.GuildName.GuildName
    , icon : Maybe Evergreen.V184.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V184.MembersAndOwner.MembersAndOwner
            (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V184.SecretId.SecretId Evergreen.V184.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V184.Id.Id Evergreen.V184.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V184.ChannelName.ChannelName
    , description : Evergreen.V184.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V184.Message.Message Evergreen.V184.Id.ChannelMessageId (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Evergreen.V184.Thread.LastTypedAt Evergreen.V184.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V184.OneToOne.OneToOne (Evergreen.V184.Discord.Id Evergreen.V184.Discord.MessageId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) Evergreen.V184.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V184.GuildName.GuildName
    , icon : Maybe Evergreen.V184.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V184.MembersAndOwner.MembersAndOwner
            (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }
