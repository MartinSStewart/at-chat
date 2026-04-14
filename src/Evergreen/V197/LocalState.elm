module Evergreen.V197.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V197.ChannelDescription
import Evergreen.V197.ChannelName
import Evergreen.V197.Discord
import Evergreen.V197.DiscordUserData
import Evergreen.V197.DmChannel
import Evergreen.V197.FileStatus
import Evergreen.V197.GuildName
import Evergreen.V197.Id
import Evergreen.V197.Log
import Evergreen.V197.MembersAndOwner
import Evergreen.V197.Message
import Evergreen.V197.NonemptyDict
import Evergreen.V197.OneToOne
import Evergreen.V197.Pagination
import Evergreen.V197.SecretId
import Evergreen.V197.SessionIdHash
import Evergreen.V197.Slack
import Evergreen.V197.Sticker
import Evergreen.V197.TextEditor
import Evergreen.V197.Thread
import Evergreen.V197.ToBackendLog
import Evergreen.V197.User
import Evergreen.V197.UserAgent
import Evergreen.V197.UserSession
import Evergreen.V197.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V197.NonemptyDict.NonemptyDict
            (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V197.Message.Message Evergreen.V197.Id.ChannelMessageId (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V197.Discord.PartialUser
        , icon : Maybe Evergreen.V197.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V197.Discord.User
        , linkedTo : Evergreen.V197.Id.Id Evergreen.V197.Id.UserId
        , icon : Maybe Evergreen.V197.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V197.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V197.Discord.User
        , linkedTo : Evergreen.V197.Id.Id Evergreen.V197.Id.UserId
        , icon : Maybe Evergreen.V197.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V197.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V197.Message.Message Evergreen.V197.Id.ChannelMessageId (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V197.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V197.MembersAndOwner.MembersAndOwner
            (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V197.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V197.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V197.Id.Id Evergreen.V197.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V197.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V197.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V197.Id.Id Evergreen.V197.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V197.Id.Id Evergreen.V197.Id.UserId
    , name : Evergreen.V197.ChannelName.ChannelName
    , description : Evergreen.V197.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V197.Message.MessageState Evergreen.V197.Id.ChannelMessageId (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId))
    , visibleMessages : Evergreen.V197.VisibleMessages.VisibleMessages Evergreen.V197.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) (Evergreen.V197.Thread.LastTypedAt Evergreen.V197.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) Evergreen.V197.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V197.Id.Id Evergreen.V197.Id.UserId
    , name : Evergreen.V197.GuildName.GuildName
    , icon : Maybe Evergreen.V197.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V197.MembersAndOwner.MembersAndOwner
            (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V197.SecretId.SecretId Evergreen.V197.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V197.Id.Id Evergreen.V197.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V197.ChannelName.ChannelName
    , description : Evergreen.V197.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V197.Message.MessageState Evergreen.V197.Id.ChannelMessageId (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId))
    , visibleMessages : Evergreen.V197.VisibleMessages.VisibleMessages Evergreen.V197.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Evergreen.V197.Thread.LastTypedAt Evergreen.V197.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) Evergreen.V197.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V197.GuildName.GuildName
    , icon : Maybe Evergreen.V197.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V197.MembersAndOwner.MembersAndOwner
            (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V197.Id.Id Evergreen.V197.Id.StickerId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V197.NonemptyDict.NonemptyDict (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) Evergreen.V197.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V197.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V197.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V197.SessionIdHash.SessionIdHash (Evergreen.V197.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V197.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V197.UserSession.UserSession
    , user : Evergreen.V197.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) Evergreen.V197.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) Evergreen.V197.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) Evergreen.V197.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V197.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.StickerId) Evergreen.V197.Sticker.StickerData
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) Evergreen.V197.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId) Evergreen.V197.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V197.SessionIdHash.SessionIdHash Evergreen.V197.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V197.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V197.Id.Id Evergreen.V197.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V197.Id.Id Evergreen.V197.Id.UserId
    , name : Evergreen.V197.ChannelName.ChannelName
    , description : Evergreen.V197.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V197.Message.Message Evergreen.V197.Id.ChannelMessageId (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) (Evergreen.V197.Thread.LastTypedAt Evergreen.V197.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) Evergreen.V197.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V197.Id.Id Evergreen.V197.Id.UserId
    , name : Evergreen.V197.GuildName.GuildName
    , icon : Maybe Evergreen.V197.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V197.MembersAndOwner.MembersAndOwner
            (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V197.SecretId.SecretId Evergreen.V197.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V197.Id.Id Evergreen.V197.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V197.ChannelName.ChannelName
    , description : Evergreen.V197.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V197.Message.Message Evergreen.V197.Id.ChannelMessageId (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Evergreen.V197.Thread.LastTypedAt Evergreen.V197.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V197.OneToOne.OneToOne (Evergreen.V197.Discord.Id Evergreen.V197.Discord.MessageId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) Evergreen.V197.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V197.GuildName.GuildName
    , icon : Maybe Evergreen.V197.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V197.MembersAndOwner.MembersAndOwner
            (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V197.Id.Id Evergreen.V197.Id.StickerId)
    }
