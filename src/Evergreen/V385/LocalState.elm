module Evergreen.V385.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V385.BackendMsgLog
import Evergreen.V385.Call
import Evergreen.V385.ChannelDescription
import Evergreen.V385.ChannelName
import Evergreen.V385.Discord
import Evergreen.V385.DiscordUserData
import Evergreen.V385.DmChannel
import Evergreen.V385.DmChannelId
import Evergreen.V385.Drawing
import Evergreen.V385.FileStatus
import Evergreen.V385.Game
import Evergreen.V385.GuildName
import Evergreen.V385.Id
import Evergreen.V385.IdArray
import Evergreen.V385.Log
import Evergreen.V385.MembersAndOwner
import Evergreen.V385.Message
import Evergreen.V385.MessageArray
import Evergreen.V385.NonemptyDict
import Evergreen.V385.OneToOne
import Evergreen.V385.Pagination
import Evergreen.V385.Postmark
import Evergreen.V385.SecretId
import Evergreen.V385.SessionIdHash
import Evergreen.V385.Slack
import Evergreen.V385.TextEditor
import Evergreen.V385.Thread
import Evergreen.V385.ToBackendLog
import Evergreen.V385.User
import Evergreen.V385.UserSession
import Evergreen.V385.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V385.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V385.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V385.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V385.Call.RemoteCallData
    , currentlyViewing : Evergreen.V385.UserSession.Viewing
    }


type BackupContents
    = FullBackup
    | SubsetBackup


type alias LastBackup =
    { createdAt : Effect.Time.Posix
    , contents : BackupContents
    }


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V385.Id.Id Evergreen.V385.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V385.Id.Id Evergreen.V385.Id.UserId
    , name : Evergreen.V385.ChannelName.ChannelName
    , description : Evergreen.V385.ChannelDescription.ChannelDescription
    , messages : Evergreen.V385.MessageArray.MessageArray Evergreen.V385.Id.ChannelMessageId (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)
    , visibleMessages : Evergreen.V385.VisibleMessages.VisibleMessages Evergreen.V385.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) (Evergreen.V385.Thread.LastTypedAt Evergreen.V385.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) Evergreen.V385.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V385.Drawing.Drawing (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) Evergreen.V385.Game.MatchData
    }


type alias GuildMember =
    { joinedAt : Effect.Time.Posix
    , lastPostedAt : Maybe Effect.Time.Posix
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V385.Id.Id Evergreen.V385.Id.UserId
    , name : Evergreen.V385.GuildName.GuildName
    , icon : Maybe Evergreen.V385.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId) FrontendChannel
    , membersAndOwner : Evergreen.V385.MembersAndOwner.MembersAndOwner (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) GuildMember
    , invites :
        SeqDict.SeqDict
            (Evergreen.V385.SecretId.SecretId Evergreen.V385.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V385.Id.Id Evergreen.V385.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V385.ChannelName.ChannelName
    , description : Evergreen.V385.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V385.MessageArray.MessageArray Evergreen.V385.Id.ChannelMessageId (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId)
    , visibleMessages : Evergreen.V385.VisibleMessages.VisibleMessages Evergreen.V385.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Thread.LastTypedAt Evergreen.V385.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) Evergreen.V385.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V385.Drawing.Drawing (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId))
    , permissionOverwrites : List Evergreen.V385.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V385.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V385.GuildName.GuildName
    , icon : Maybe Evergreen.V385.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V385.MembersAndOwner.MembersAndOwner
            (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V385.Discord.Id Evergreen.V385.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V385.Id.Id Evergreen.V385.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V385.Id.Id Evergreen.V385.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V385.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V385.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V385.Id.Id Evergreen.V385.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V385.GuildName.GuildName
    , owner : Evergreen.V385.Id.Id Evergreen.V385.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V385.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V385.Message.Message Evergreen.V385.Id.ChannelMessageId (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId))
    , permissionOverwrites : List Evergreen.V385.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V385.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V385.MembersAndOwner.MembersAndOwner
            (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V385.Discord.Id Evergreen.V385.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V385.NonemptyDict.NonemptyDict
            (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V385.Message.Message Evergreen.V385.Id.ChannelMessageId (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V385.Discord.PartialUser
        , icon : Maybe Evergreen.V385.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V385.Discord.User
        , linkedTo : Evergreen.V385.Id.Id Evergreen.V385.Id.UserId
        , icon : Maybe Evergreen.V385.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V385.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V385.Discord.User
        , linkedTo : Evergreen.V385.Id.Id Evergreen.V385.Id.UserId
        , icon : Maybe Evergreen.V385.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid
    | YouAreBanned


type AdminDataStatus a
    = AdminDataNotLoaded
    | AdminDataLoading
    | AdminDataLoaded a


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : AdminDataStatus (Evergreen.V385.NonemptyDict.NonemptyDict (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Evergreen.V385.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V385.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V385.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V385.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) AdminData_DiscordGuild)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V385.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V385.SessionIdHash.SessionIdHash, Evergreen.V385.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V385.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V385.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V385.SessionIdHash.SessionIdHash Evergreen.V385.UserSession.UserSession)
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Evergreen.V385.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId) Evergreen.V385.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V385.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V385.SessionIdHash.SessionIdHash Evergreen.V385.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V385.TextEditor.LocalState
    , calls : Evergreen.V385.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V385.Id.Id Evergreen.V385.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V385.Id.Id Evergreen.V385.Id.UserId
    , name : Evergreen.V385.ChannelName.ChannelName
    , description : Evergreen.V385.ChannelDescription.ChannelDescription
    , messages : Evergreen.V385.IdArray.IdArray Evergreen.V385.Id.ChannelMessageId (Evergreen.V385.Message.Message Evergreen.V385.Id.ChannelMessageId (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) (Evergreen.V385.Thread.LastTypedAt Evergreen.V385.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) Evergreen.V385.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V385.Drawing.Drawing (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) Evergreen.V385.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V385.Id.Id Evergreen.V385.Id.UserId
    , name : Evergreen.V385.GuildName.GuildName
    , icon : Maybe Evergreen.V385.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId) BackendChannel
    , membersAndOwner : Evergreen.V385.MembersAndOwner.MembersAndOwner (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) GuildMember
    , bannedUsers : SeqSet.SeqSet (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)
    , invites :
        SeqDict.SeqDict
            (Evergreen.V385.SecretId.SecretId Evergreen.V385.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V385.Id.Id Evergreen.V385.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V385.ChannelName.ChannelName
    , description : Evergreen.V385.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V385.IdArray.IdArray Evergreen.V385.Id.ChannelMessageId (Evergreen.V385.Message.Message Evergreen.V385.Id.ChannelMessageId (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Thread.LastTypedAt Evergreen.V385.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V385.OneToOne.OneToOne (Evergreen.V385.Discord.Id Evergreen.V385.Discord.MessageId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) Evergreen.V385.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V385.Drawing.Drawing (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId))
    , permissionOverwrites : List Evergreen.V385.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V385.GuildName.GuildName
    , icon : Maybe Evergreen.V385.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V385.MembersAndOwner.MembersAndOwner
            (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V385.Discord.Id Evergreen.V385.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V385.Id.Id Evergreen.V385.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V385.Id.Id Evergreen.V385.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId
    , messages : List Evergreen.V385.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V385.Discord.Message
    , threads : List DiscordThreadReload
    }
