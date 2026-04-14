module Evergreen.V196.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V196.ChannelDescription
import Evergreen.V196.ChannelName
import Evergreen.V196.Discord
import Evergreen.V196.DiscordUserData
import Evergreen.V196.DmChannel
import Evergreen.V196.FileStatus
import Evergreen.V196.GuildName
import Evergreen.V196.Id
import Evergreen.V196.Log
import Evergreen.V196.MembersAndOwner
import Evergreen.V196.Message
import Evergreen.V196.NonemptyDict
import Evergreen.V196.OneToOne
import Evergreen.V196.Pagination
import Evergreen.V196.SecretId
import Evergreen.V196.SessionIdHash
import Evergreen.V196.Slack
import Evergreen.V196.Sticker
import Evergreen.V196.TextEditor
import Evergreen.V196.Thread
import Evergreen.V196.ToBackendLog
import Evergreen.V196.User
import Evergreen.V196.UserAgent
import Evergreen.V196.UserSession
import Evergreen.V196.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V196.NonemptyDict.NonemptyDict
            (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V196.Message.Message Evergreen.V196.Id.ChannelMessageId (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V196.Discord.PartialUser
        , icon : Maybe Evergreen.V196.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V196.Discord.User
        , linkedTo : Evergreen.V196.Id.Id Evergreen.V196.Id.UserId
        , icon : Maybe Evergreen.V196.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V196.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V196.Discord.User
        , linkedTo : Evergreen.V196.Id.Id Evergreen.V196.Id.UserId
        , icon : Maybe Evergreen.V196.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V196.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V196.Message.Message Evergreen.V196.Id.ChannelMessageId (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V196.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V196.Discord.Id Evergreen.V196.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V196.MembersAndOwner.MembersAndOwner
            (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V196.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V196.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V196.Id.Id Evergreen.V196.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V196.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V196.Discord.Id Evergreen.V196.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V196.Discord.Id Evergreen.V196.Discord.GuildId) (Evergreen.V196.Discord.Id Evergreen.V196.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V196.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V196.Id.Id Evergreen.V196.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V196.Id.Id Evergreen.V196.Id.UserId
    , name : Evergreen.V196.ChannelName.ChannelName
    , description : Evergreen.V196.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V196.Message.MessageState Evergreen.V196.Id.ChannelMessageId (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId))
    , visibleMessages : Evergreen.V196.VisibleMessages.VisibleMessages Evergreen.V196.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId) (Evergreen.V196.Thread.LastTypedAt Evergreen.V196.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelMessageId) Evergreen.V196.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V196.Id.Id Evergreen.V196.Id.UserId
    , name : Evergreen.V196.GuildName.GuildName
    , icon : Maybe Evergreen.V196.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V196.MembersAndOwner.MembersAndOwner
            (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V196.SecretId.SecretId Evergreen.V196.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V196.Id.Id Evergreen.V196.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V196.ChannelName.ChannelName
    , description : Evergreen.V196.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V196.Message.MessageState Evergreen.V196.Id.ChannelMessageId (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId))
    , visibleMessages : Evergreen.V196.VisibleMessages.VisibleMessages Evergreen.V196.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId) (Evergreen.V196.Thread.LastTypedAt Evergreen.V196.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelMessageId) Evergreen.V196.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V196.GuildName.GuildName
    , icon : Maybe Evergreen.V196.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V196.Discord.Id Evergreen.V196.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V196.MembersAndOwner.MembersAndOwner
            (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V196.Id.Id Evergreen.V196.Id.StickerId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V196.NonemptyDict.NonemptyDict (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId) Evergreen.V196.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V196.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V196.Discord.Id Evergreen.V196.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V196.Discord.Id Evergreen.V196.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V196.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V196.SessionIdHash.SessionIdHash (Evergreen.V196.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V196.ToBackendLog.ToBackendLogData
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V196.UserSession.UserSession
    , user : Evergreen.V196.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId) Evergreen.V196.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId) Evergreen.V196.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId) Evergreen.V196.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V196.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.StickerId) Evergreen.V196.Sticker.StickerData
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V196.Discord.Id Evergreen.V196.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId) Evergreen.V196.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V196.Discord.Id Evergreen.V196.Discord.PrivateChannelId) Evergreen.V196.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V196.SessionIdHash.SessionIdHash Evergreen.V196.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V196.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V196.Id.Id Evergreen.V196.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V196.Id.Id Evergreen.V196.Id.UserId
    , name : Evergreen.V196.ChannelName.ChannelName
    , description : Evergreen.V196.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V196.Message.Message Evergreen.V196.Id.ChannelMessageId (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId) (Evergreen.V196.Thread.LastTypedAt Evergreen.V196.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelMessageId) Evergreen.V196.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V196.Id.Id Evergreen.V196.Id.UserId
    , name : Evergreen.V196.GuildName.GuildName
    , icon : Maybe Evergreen.V196.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V196.MembersAndOwner.MembersAndOwner
            (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V196.SecretId.SecretId Evergreen.V196.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V196.Id.Id Evergreen.V196.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V196.ChannelName.ChannelName
    , description : Evergreen.V196.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V196.Message.Message Evergreen.V196.Id.ChannelMessageId (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId) (Evergreen.V196.Thread.LastTypedAt Evergreen.V196.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V196.OneToOne.OneToOne (Evergreen.V196.Discord.Id Evergreen.V196.Discord.MessageId) (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelMessageId) Evergreen.V196.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V196.GuildName.GuildName
    , icon : Maybe Evergreen.V196.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V196.Discord.Id Evergreen.V196.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V196.MembersAndOwner.MembersAndOwner
            (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V196.Id.Id Evergreen.V196.Id.StickerId)
    }
