module Evergreen.V204.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V204.ChannelDescription
import Evergreen.V204.ChannelName
import Evergreen.V204.Discord
import Evergreen.V204.DiscordUserData
import Evergreen.V204.DmChannel
import Evergreen.V204.FileStatus
import Evergreen.V204.GuildName
import Evergreen.V204.Id
import Evergreen.V204.Log
import Evergreen.V204.MembersAndOwner
import Evergreen.V204.Message
import Evergreen.V204.NonemptyDict
import Evergreen.V204.OneToOne
import Evergreen.V204.Pagination
import Evergreen.V204.SecretId
import Evergreen.V204.SessionIdHash
import Evergreen.V204.Slack
import Evergreen.V204.Sticker
import Evergreen.V204.TextEditor
import Evergreen.V204.Thread
import Evergreen.V204.ToBackendLog
import Evergreen.V204.User
import Evergreen.V204.UserAgent
import Evergreen.V204.UserSession
import Evergreen.V204.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V204.NonemptyDict.NonemptyDict
            (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V204.Message.Message Evergreen.V204.Id.ChannelMessageId (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V204.Discord.PartialUser
        , icon : Maybe Evergreen.V204.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V204.Discord.User
        , linkedTo : Evergreen.V204.Id.Id Evergreen.V204.Id.UserId
        , icon : Maybe Evergreen.V204.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V204.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V204.Discord.User
        , linkedTo : Evergreen.V204.Id.Id Evergreen.V204.Id.UserId
        , icon : Maybe Evergreen.V204.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V204.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V204.Message.Message Evergreen.V204.Id.ChannelMessageId (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V204.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V204.MembersAndOwner.MembersAndOwner
            (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V204.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V204.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V204.Id.Id Evergreen.V204.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V204.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V204.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V204.Id.Id Evergreen.V204.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V204.Id.Id Evergreen.V204.Id.UserId
    , name : Evergreen.V204.ChannelName.ChannelName
    , description : Evergreen.V204.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V204.Message.MessageState Evergreen.V204.Id.ChannelMessageId (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId))
    , visibleMessages : Evergreen.V204.VisibleMessages.VisibleMessages Evergreen.V204.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) (Evergreen.V204.Thread.LastTypedAt Evergreen.V204.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) Evergreen.V204.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V204.Id.Id Evergreen.V204.Id.UserId
    , name : Evergreen.V204.GuildName.GuildName
    , icon : Maybe Evergreen.V204.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V204.MembersAndOwner.MembersAndOwner
            (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V204.SecretId.SecretId Evergreen.V204.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V204.Id.Id Evergreen.V204.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V204.ChannelName.ChannelName
    , description : Evergreen.V204.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V204.Message.MessageState Evergreen.V204.Id.ChannelMessageId (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId))
    , visibleMessages : Evergreen.V204.VisibleMessages.VisibleMessages Evergreen.V204.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Evergreen.V204.Thread.LastTypedAt Evergreen.V204.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) Evergreen.V204.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V204.GuildName.GuildName
    , icon : Maybe Evergreen.V204.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V204.MembersAndOwner.MembersAndOwner
            (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V204.Id.Id Evergreen.V204.Id.StickerId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V204.NonemptyDict.NonemptyDict (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) Evergreen.V204.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V204.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V204.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V204.SessionIdHash.SessionIdHash (Evergreen.V204.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V204.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V204.UserSession.UserSession
    , user : Evergreen.V204.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) Evergreen.V204.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) Evergreen.V204.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) Evergreen.V204.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V204.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.StickerId) Evergreen.V204.Sticker.StickerData
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) Evergreen.V204.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId) Evergreen.V204.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V204.SessionIdHash.SessionIdHash Evergreen.V204.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V204.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V204.Id.Id Evergreen.V204.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V204.Id.Id Evergreen.V204.Id.UserId
    , name : Evergreen.V204.ChannelName.ChannelName
    , description : Evergreen.V204.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V204.Message.Message Evergreen.V204.Id.ChannelMessageId (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) (Evergreen.V204.Thread.LastTypedAt Evergreen.V204.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) Evergreen.V204.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V204.Id.Id Evergreen.V204.Id.UserId
    , name : Evergreen.V204.GuildName.GuildName
    , icon : Maybe Evergreen.V204.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V204.MembersAndOwner.MembersAndOwner
            (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V204.SecretId.SecretId Evergreen.V204.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V204.Id.Id Evergreen.V204.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V204.ChannelName.ChannelName
    , description : Evergreen.V204.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V204.Message.Message Evergreen.V204.Id.ChannelMessageId (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Evergreen.V204.Thread.LastTypedAt Evergreen.V204.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V204.OneToOne.OneToOne (Evergreen.V204.Discord.Id Evergreen.V204.Discord.MessageId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) Evergreen.V204.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V204.GuildName.GuildName
    , icon : Maybe Evergreen.V204.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V204.MembersAndOwner.MembersAndOwner
            (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V204.Id.Id Evergreen.V204.Id.StickerId)
    }
