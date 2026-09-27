module Evergreen.V387.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V387.BackendMsgLog
import Evergreen.V387.Call
import Evergreen.V387.ChannelDescription
import Evergreen.V387.ChannelName
import Evergreen.V387.Discord
import Evergreen.V387.DiscordUserData
import Evergreen.V387.DmChannel
import Evergreen.V387.DmChannelId
import Evergreen.V387.Drawing
import Evergreen.V387.FileStatus
import Evergreen.V387.Game
import Evergreen.V387.GuildName
import Evergreen.V387.Id
import Evergreen.V387.IdArray
import Evergreen.V387.Log
import Evergreen.V387.MembersAndOwner
import Evergreen.V387.Message
import Evergreen.V387.MessageArray
import Evergreen.V387.NonemptyDict
import Evergreen.V387.OneToOne
import Evergreen.V387.Pagination
import Evergreen.V387.Postmark
import Evergreen.V387.SecretId
import Evergreen.V387.SessionIdHash
import Evergreen.V387.Slack
import Evergreen.V387.TextEditor
import Evergreen.V387.Thread
import Evergreen.V387.ToBackendLog
import Evergreen.V387.User
import Evergreen.V387.UserSession
import Evergreen.V387.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V387.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V387.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V387.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V387.Call.RemoteCallData
    , currentlyViewing : Evergreen.V387.UserSession.Viewing
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
    , archivedBy : Evergreen.V387.Id.Id Evergreen.V387.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V387.Id.Id Evergreen.V387.Id.UserId
    , name : Evergreen.V387.ChannelName.ChannelName
    , description : Evergreen.V387.ChannelDescription.ChannelDescription
    , messages : Evergreen.V387.MessageArray.MessageArray Evergreen.V387.Id.ChannelMessageId (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId)
    , visibleMessages : Evergreen.V387.VisibleMessages.VisibleMessages Evergreen.V387.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Thread.LastTypedAt Evergreen.V387.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) Evergreen.V387.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V387.Drawing.Drawing (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) Evergreen.V387.Game.MatchData
    }


type alias GuildMember =
    { joinedAt : Effect.Time.Posix
    , lastPostedAt : Maybe Effect.Time.Posix
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V387.Id.Id Evergreen.V387.Id.UserId
    , name : Evergreen.V387.GuildName.GuildName
    , icon : Maybe Evergreen.V387.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId) FrontendChannel
    , membersAndOwner : Evergreen.V387.MembersAndOwner.MembersAndOwner (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) GuildMember
    , invites :
        SeqDict.SeqDict
            (Evergreen.V387.SecretId.SecretId Evergreen.V387.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V387.Id.Id Evergreen.V387.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V387.ChannelName.ChannelName
    , description : Evergreen.V387.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V387.MessageArray.MessageArray Evergreen.V387.Id.ChannelMessageId (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId)
    , visibleMessages : Evergreen.V387.VisibleMessages.VisibleMessages Evergreen.V387.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Thread.LastTypedAt Evergreen.V387.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) Evergreen.V387.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V387.Drawing.Drawing (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId))
    , permissionOverwrites : List Evergreen.V387.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V387.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V387.GuildName.GuildName
    , icon : Maybe Evergreen.V387.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V387.MembersAndOwner.MembersAndOwner
            (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V387.Discord.Id Evergreen.V387.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V387.Id.Id Evergreen.V387.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V387.Id.Id Evergreen.V387.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V387.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V387.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V387.Id.Id Evergreen.V387.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V387.GuildName.GuildName
    , owner : Evergreen.V387.Id.Id Evergreen.V387.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V387.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V387.Message.Message Evergreen.V387.Id.ChannelMessageId (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId))
    , permissionOverwrites : List Evergreen.V387.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V387.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V387.MembersAndOwner.MembersAndOwner
            (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V387.Discord.Id Evergreen.V387.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V387.NonemptyDict.NonemptyDict
            (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V387.Message.Message Evergreen.V387.Id.ChannelMessageId (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V387.Discord.PartialUser
        , icon : Maybe Evergreen.V387.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V387.Discord.User
        , linkedTo : Evergreen.V387.Id.Id Evergreen.V387.Id.UserId
        , icon : Maybe Evergreen.V387.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V387.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V387.Discord.User
        , linkedTo : Evergreen.V387.Id.Id Evergreen.V387.Id.UserId
        , icon : Maybe Evergreen.V387.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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


type DeleteOrphanedFilesStatus
    = NotDeletingOrphanedFiles
    | DeletingOrphanedFiles
    | DeletingOrphanedFilesFailed Effect.Http.Error


type alias AdminData =
    { users : AdminDataStatus (Evergreen.V387.NonemptyDict.NonemptyDict (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Evergreen.V387.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V387.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V387.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V387.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) AdminData_DiscordGuild)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V387.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V387.SessionIdHash.SessionIdHash, Evergreen.V387.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V387.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V387.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , orphanedFiles : AdminDataStatus (SeqDict.SeqDict Evergreen.V387.FileStatus.FileHash Evergreen.V387.FileStatus.BackendFileData)
    , deleteOrphanedFiles : DeleteOrphanedFilesStatus
    , bucketFileCount : AdminDataStatus (Result Effect.Http.Error Int)
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V387.SessionIdHash.SessionIdHash Evergreen.V387.UserSession.UserSession)
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Evergreen.V387.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId) Evergreen.V387.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V387.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V387.SessionIdHash.SessionIdHash Evergreen.V387.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V387.TextEditor.LocalState
    , calls : Evergreen.V387.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V387.Id.Id Evergreen.V387.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V387.Id.Id Evergreen.V387.Id.UserId
    , name : Evergreen.V387.ChannelName.ChannelName
    , description : Evergreen.V387.ChannelDescription.ChannelDescription
    , messages : Evergreen.V387.IdArray.IdArray Evergreen.V387.Id.ChannelMessageId (Evergreen.V387.Message.Message Evergreen.V387.Id.ChannelMessageId (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Thread.LastTypedAt Evergreen.V387.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) Evergreen.V387.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V387.Drawing.Drawing (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) Evergreen.V387.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V387.Id.Id Evergreen.V387.Id.UserId
    , name : Evergreen.V387.GuildName.GuildName
    , icon : Maybe Evergreen.V387.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId) BackendChannel
    , membersAndOwner : Evergreen.V387.MembersAndOwner.MembersAndOwner (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) GuildMember
    , bannedUsers : SeqSet.SeqSet (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId)
    , invites :
        SeqDict.SeqDict
            (Evergreen.V387.SecretId.SecretId Evergreen.V387.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V387.Id.Id Evergreen.V387.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V387.ChannelName.ChannelName
    , description : Evergreen.V387.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V387.IdArray.IdArray Evergreen.V387.Id.ChannelMessageId (Evergreen.V387.Message.Message Evergreen.V387.Id.ChannelMessageId (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Thread.LastTypedAt Evergreen.V387.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V387.OneToOne.OneToOne (Evergreen.V387.Discord.Id Evergreen.V387.Discord.MessageId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) Evergreen.V387.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V387.Drawing.Drawing (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId))
    , permissionOverwrites : List Evergreen.V387.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V387.GuildName.GuildName
    , icon : Maybe Evergreen.V387.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V387.MembersAndOwner.MembersAndOwner
            (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V387.Discord.Id Evergreen.V387.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V387.Id.Id Evergreen.V387.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V387.Id.Id Evergreen.V387.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId
    , messages : List Evergreen.V387.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V387.Discord.Message
    , threads : List DiscordThreadReload
    }
