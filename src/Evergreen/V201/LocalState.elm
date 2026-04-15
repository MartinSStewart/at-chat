module Evergreen.V201.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V201.ChannelDescription
import Evergreen.V201.ChannelName
import Evergreen.V201.Discord
import Evergreen.V201.DiscordUserData
import Evergreen.V201.DmChannel
import Evergreen.V201.FileStatus
import Evergreen.V201.GuildName
import Evergreen.V201.Id
import Evergreen.V201.Log
import Evergreen.V201.MembersAndOwner
import Evergreen.V201.Message
import Evergreen.V201.NonemptyDict
import Evergreen.V201.OneToOne
import Evergreen.V201.Pagination
import Evergreen.V201.SecretId
import Evergreen.V201.SessionIdHash
import Evergreen.V201.Slack
import Evergreen.V201.Sticker
import Evergreen.V201.TextEditor
import Evergreen.V201.Thread
import Evergreen.V201.ToBackendLog
import Evergreen.V201.User
import Evergreen.V201.UserAgent
import Evergreen.V201.UserSession
import Evergreen.V201.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V201.NonemptyDict.NonemptyDict
            (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V201.Message.Message Evergreen.V201.Id.ChannelMessageId (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V201.Discord.PartialUser
        , icon : Maybe Evergreen.V201.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V201.Discord.User
        , linkedTo : Evergreen.V201.Id.Id Evergreen.V201.Id.UserId
        , icon : Maybe Evergreen.V201.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V201.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V201.Discord.User
        , linkedTo : Evergreen.V201.Id.Id Evergreen.V201.Id.UserId
        , icon : Maybe Evergreen.V201.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V201.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V201.Message.Message Evergreen.V201.Id.ChannelMessageId (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V201.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V201.MembersAndOwner.MembersAndOwner
            (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V201.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V201.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V201.Id.Id Evergreen.V201.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V201.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V201.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V201.Id.Id Evergreen.V201.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V201.Id.Id Evergreen.V201.Id.UserId
    , name : Evergreen.V201.ChannelName.ChannelName
    , description : Evergreen.V201.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V201.Message.MessageState Evergreen.V201.Id.ChannelMessageId (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId))
    , visibleMessages : Evergreen.V201.VisibleMessages.VisibleMessages Evergreen.V201.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) (Evergreen.V201.Thread.LastTypedAt Evergreen.V201.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) Evergreen.V201.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V201.Id.Id Evergreen.V201.Id.UserId
    , name : Evergreen.V201.GuildName.GuildName
    , icon : Maybe Evergreen.V201.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V201.MembersAndOwner.MembersAndOwner
            (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V201.SecretId.SecretId Evergreen.V201.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V201.Id.Id Evergreen.V201.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V201.ChannelName.ChannelName
    , description : Evergreen.V201.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V201.Message.MessageState Evergreen.V201.Id.ChannelMessageId (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId))
    , visibleMessages : Evergreen.V201.VisibleMessages.VisibleMessages Evergreen.V201.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Evergreen.V201.Thread.LastTypedAt Evergreen.V201.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) Evergreen.V201.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V201.GuildName.GuildName
    , icon : Maybe Evergreen.V201.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V201.MembersAndOwner.MembersAndOwner
            (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V201.Id.Id Evergreen.V201.Id.StickerId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V201.NonemptyDict.NonemptyDict (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) Evergreen.V201.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V201.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V201.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V201.SessionIdHash.SessionIdHash (Evergreen.V201.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V201.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V201.UserSession.UserSession
    , user : Evergreen.V201.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) Evergreen.V201.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) Evergreen.V201.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) Evergreen.V201.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V201.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.StickerId) Evergreen.V201.Sticker.StickerData
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) Evergreen.V201.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId) Evergreen.V201.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V201.SessionIdHash.SessionIdHash Evergreen.V201.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V201.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V201.Id.Id Evergreen.V201.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V201.Id.Id Evergreen.V201.Id.UserId
    , name : Evergreen.V201.ChannelName.ChannelName
    , description : Evergreen.V201.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V201.Message.Message Evergreen.V201.Id.ChannelMessageId (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) (Evergreen.V201.Thread.LastTypedAt Evergreen.V201.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) Evergreen.V201.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V201.Id.Id Evergreen.V201.Id.UserId
    , name : Evergreen.V201.GuildName.GuildName
    , icon : Maybe Evergreen.V201.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V201.MembersAndOwner.MembersAndOwner
            (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V201.SecretId.SecretId Evergreen.V201.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V201.Id.Id Evergreen.V201.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V201.ChannelName.ChannelName
    , description : Evergreen.V201.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V201.Message.Message Evergreen.V201.Id.ChannelMessageId (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Evergreen.V201.Thread.LastTypedAt Evergreen.V201.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V201.OneToOne.OneToOne (Evergreen.V201.Discord.Id Evergreen.V201.Discord.MessageId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) Evergreen.V201.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V201.GuildName.GuildName
    , icon : Maybe Evergreen.V201.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V201.MembersAndOwner.MembersAndOwner
            (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V201.Id.Id Evergreen.V201.Id.StickerId)
    }
