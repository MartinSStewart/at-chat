module Evergreen.V169.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V169.ChannelDescription
import Evergreen.V169.ChannelName
import Evergreen.V169.Discord
import Evergreen.V169.DiscordUserData
import Evergreen.V169.DmChannel
import Evergreen.V169.FileStatus
import Evergreen.V169.GuildName
import Evergreen.V169.Id
import Evergreen.V169.Log
import Evergreen.V169.MembersAndOwner
import Evergreen.V169.Message
import Evergreen.V169.NonemptyDict
import Evergreen.V169.OneToOne
import Evergreen.V169.Pagination
import Evergreen.V169.SecretId
import Evergreen.V169.SessionIdHash
import Evergreen.V169.Slack
import Evergreen.V169.TextEditor
import Evergreen.V169.Thread
import Evergreen.V169.User
import Evergreen.V169.UserAgent
import Evergreen.V169.UserSession
import Evergreen.V169.VisibleMessages
import SeqDict


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V169.NonemptyDict.NonemptyDict
            (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V169.Message.Message Evergreen.V169.Id.ChannelMessageId (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V169.Discord.PartialUser
        , icon : Maybe Evergreen.V169.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V169.Discord.User
        , linkedTo : Evergreen.V169.Id.Id Evergreen.V169.Id.UserId
        , icon : Maybe Evergreen.V169.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V169.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V169.Discord.User
        , linkedTo : Evergreen.V169.Id.Id Evergreen.V169.Id.UserId
        , icon : Maybe Evergreen.V169.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V169.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V169.Message.Message Evergreen.V169.Id.ChannelMessageId (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V169.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V169.MembersAndOwner.MembersAndOwner
            (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V169.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V169.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V169.Id.Id Evergreen.V169.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V169.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V169.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V169.Id.Id Evergreen.V169.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V169.Id.Id Evergreen.V169.Id.UserId
    , name : Evergreen.V169.ChannelName.ChannelName
    , description : Evergreen.V169.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V169.Message.MessageState Evergreen.V169.Id.ChannelMessageId (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId))
    , visibleMessages : Evergreen.V169.VisibleMessages.VisibleMessages Evergreen.V169.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) (Evergreen.V169.Thread.LastTypedAt Evergreen.V169.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) Evergreen.V169.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V169.Id.Id Evergreen.V169.Id.UserId
    , name : Evergreen.V169.GuildName.GuildName
    , icon : Maybe Evergreen.V169.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V169.MembersAndOwner.MembersAndOwner
            (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V169.SecretId.SecretId Evergreen.V169.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V169.Id.Id Evergreen.V169.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V169.ChannelName.ChannelName
    , description : Evergreen.V169.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V169.Message.MessageState Evergreen.V169.Id.ChannelMessageId (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId))
    , visibleMessages : Evergreen.V169.VisibleMessages.VisibleMessages Evergreen.V169.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Evergreen.V169.Thread.LastTypedAt Evergreen.V169.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) Evergreen.V169.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V169.GuildName.GuildName
    , icon : Maybe Evergreen.V169.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V169.MembersAndOwner.MembersAndOwner
            (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V169.NonemptyDict.NonemptyDict (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) Evergreen.V169.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V169.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V169.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V169.SessionIdHash.SessionIdHash (Evergreen.V169.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V169.UserSession.UserSession
    , user : Evergreen.V169.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) Evergreen.V169.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) Evergreen.V169.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) Evergreen.V169.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V169.UserAgent.UserAgent
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) Evergreen.V169.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId) Evergreen.V169.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V169.SessionIdHash.SessionIdHash Evergreen.V169.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V169.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V169.Id.Id Evergreen.V169.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V169.Id.Id Evergreen.V169.Id.UserId
    , name : Evergreen.V169.ChannelName.ChannelName
    , description : Evergreen.V169.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V169.Message.Message Evergreen.V169.Id.ChannelMessageId (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) (Evergreen.V169.Thread.LastTypedAt Evergreen.V169.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) Evergreen.V169.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V169.Id.Id Evergreen.V169.Id.UserId
    , name : Evergreen.V169.GuildName.GuildName
    , icon : Maybe Evergreen.V169.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V169.MembersAndOwner.MembersAndOwner
            (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V169.SecretId.SecretId Evergreen.V169.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V169.Id.Id Evergreen.V169.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V169.ChannelName.ChannelName
    , description : Evergreen.V169.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V169.Message.Message Evergreen.V169.Id.ChannelMessageId (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Evergreen.V169.Thread.LastTypedAt Evergreen.V169.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V169.OneToOne.OneToOne (Evergreen.V169.Discord.Id Evergreen.V169.Discord.MessageId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) Evergreen.V169.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V169.GuildName.GuildName
    , icon : Maybe Evergreen.V169.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V169.MembersAndOwner.MembersAndOwner
            (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }
