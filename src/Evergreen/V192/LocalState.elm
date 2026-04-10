module Evergreen.V192.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V192.ChannelDescription
import Evergreen.V192.ChannelName
import Evergreen.V192.Discord
import Evergreen.V192.DiscordUserData
import Evergreen.V192.DmChannel
import Evergreen.V192.FileStatus
import Evergreen.V192.GuildName
import Evergreen.V192.Id
import Evergreen.V192.Log
import Evergreen.V192.MembersAndOwner
import Evergreen.V192.Message
import Evergreen.V192.NonemptyDict
import Evergreen.V192.OneToOne
import Evergreen.V192.Pagination
import Evergreen.V192.SecretId
import Evergreen.V192.SessionIdHash
import Evergreen.V192.Slack
import Evergreen.V192.Sticker
import Evergreen.V192.TextEditor
import Evergreen.V192.Thread
import Evergreen.V192.ToBackendLog
import Evergreen.V192.User
import Evergreen.V192.UserAgent
import Evergreen.V192.UserSession
import Evergreen.V192.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V192.NonemptyDict.NonemptyDict
            (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V192.Message.Message Evergreen.V192.Id.ChannelMessageId (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V192.Discord.PartialUser
        , icon : Maybe Evergreen.V192.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V192.Discord.User
        , linkedTo : Evergreen.V192.Id.Id Evergreen.V192.Id.UserId
        , icon : Maybe Evergreen.V192.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V192.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V192.Discord.User
        , linkedTo : Evergreen.V192.Id.Id Evergreen.V192.Id.UserId
        , icon : Maybe Evergreen.V192.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V192.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V192.Message.Message Evergreen.V192.Id.ChannelMessageId (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V192.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V192.MembersAndOwner.MembersAndOwner
            (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V192.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V192.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V192.Id.Id Evergreen.V192.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V192.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V192.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V192.Id.Id Evergreen.V192.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V192.Id.Id Evergreen.V192.Id.UserId
    , name : Evergreen.V192.ChannelName.ChannelName
    , description : Evergreen.V192.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V192.Message.MessageState Evergreen.V192.Id.ChannelMessageId (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId))
    , visibleMessages : Evergreen.V192.VisibleMessages.VisibleMessages Evergreen.V192.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) (Evergreen.V192.Thread.LastTypedAt Evergreen.V192.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) Evergreen.V192.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V192.Id.Id Evergreen.V192.Id.UserId
    , name : Evergreen.V192.GuildName.GuildName
    , icon : Maybe Evergreen.V192.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V192.MembersAndOwner.MembersAndOwner
            (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V192.SecretId.SecretId Evergreen.V192.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V192.Id.Id Evergreen.V192.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V192.ChannelName.ChannelName
    , description : Evergreen.V192.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V192.Message.MessageState Evergreen.V192.Id.ChannelMessageId (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId))
    , visibleMessages : Evergreen.V192.VisibleMessages.VisibleMessages Evergreen.V192.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Evergreen.V192.Thread.LastTypedAt Evergreen.V192.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) Evergreen.V192.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V192.GuildName.GuildName
    , icon : Maybe Evergreen.V192.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V192.MembersAndOwner.MembersAndOwner
            (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V192.Id.Id Evergreen.V192.Id.StickerId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V192.NonemptyDict.NonemptyDict (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) Evergreen.V192.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V192.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V192.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V192.SessionIdHash.SessionIdHash (Evergreen.V192.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V192.ToBackendLog.ToBackendLogData
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V192.UserSession.UserSession
    , user : Evergreen.V192.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) Evergreen.V192.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) Evergreen.V192.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) Evergreen.V192.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V192.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.StickerId) Evergreen.V192.Sticker.StickerData
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) Evergreen.V192.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId) Evergreen.V192.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V192.SessionIdHash.SessionIdHash Evergreen.V192.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V192.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V192.Id.Id Evergreen.V192.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V192.Id.Id Evergreen.V192.Id.UserId
    , name : Evergreen.V192.ChannelName.ChannelName
    , description : Evergreen.V192.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V192.Message.Message Evergreen.V192.Id.ChannelMessageId (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) (Evergreen.V192.Thread.LastTypedAt Evergreen.V192.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) Evergreen.V192.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V192.Id.Id Evergreen.V192.Id.UserId
    , name : Evergreen.V192.GuildName.GuildName
    , icon : Maybe Evergreen.V192.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V192.MembersAndOwner.MembersAndOwner
            (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V192.SecretId.SecretId Evergreen.V192.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V192.Id.Id Evergreen.V192.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V192.ChannelName.ChannelName
    , description : Evergreen.V192.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V192.Message.Message Evergreen.V192.Id.ChannelMessageId (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Evergreen.V192.Thread.LastTypedAt Evergreen.V192.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V192.OneToOne.OneToOne (Evergreen.V192.Discord.Id Evergreen.V192.Discord.MessageId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) Evergreen.V192.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V192.GuildName.GuildName
    , icon : Maybe Evergreen.V192.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V192.MembersAndOwner.MembersAndOwner
            (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V192.Id.Id Evergreen.V192.Id.StickerId)
    }
