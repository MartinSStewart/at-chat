module Evergreen.V407.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V407.BackendMsgLog
import Evergreen.V407.Call
import Evergreen.V407.ChannelDescription
import Evergreen.V407.ChannelName
import Evergreen.V407.Discord
import Evergreen.V407.DiscordUserData
import Evergreen.V407.DmChannel
import Evergreen.V407.DmChannelId
import Evergreen.V407.Drawing
import Evergreen.V407.FileStatus
import Evergreen.V407.Game
import Evergreen.V407.GuildName
import Evergreen.V407.Id
import Evergreen.V407.IdArray
import Evergreen.V407.Log
import Evergreen.V407.MembersAndOwner
import Evergreen.V407.Message
import Evergreen.V407.MessageArray
import Evergreen.V407.NonemptyDict
import Evergreen.V407.NonemptySet
import Evergreen.V407.OneToOne
import Evergreen.V407.Pagination
import Evergreen.V407.Postmark
import Evergreen.V407.SecretId
import Evergreen.V407.SessionIdHash
import Evergreen.V407.Slack
import Evergreen.V407.TextEditor
import Evergreen.V407.Thread
import Evergreen.V407.ToBackendLog
import Evergreen.V407.User
import Evergreen.V407.UserSession
import Evergreen.V407.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V407.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V407.Log.Log
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V407.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V407.Call.RemoteCallData
    , currentlyViewing : Evergreen.V407.UserSession.Viewing
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
    , archivedBy : Evergreen.V407.Id.Id Evergreen.V407.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V407.Id.Id Evergreen.V407.Id.UserId
    , name : Evergreen.V407.ChannelName.ChannelName
    , description : Evergreen.V407.ChannelDescription.ChannelDescription
    , messages : Evergreen.V407.MessageArray.MessageArray Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId)
    , visibleMessages : Evergreen.V407.VisibleMessages.VisibleMessages Evergreen.V407.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , threads : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V407.Drawing.Drawing (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.Game.MatchData
    }


type alias GuildMember =
    { joinedAt : Effect.Time.Posix
    , lastPostedAt : Maybe Effect.Time.Posix
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V407.Id.Id Evergreen.V407.Id.UserId
    , name : Evergreen.V407.GuildName.GuildName
    , icon : Maybe Evergreen.V407.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId) FrontendChannel
    , membersAndOwner : Evergreen.V407.MembersAndOwner.MembersAndOwner (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) GuildMember
    , invites :
        SeqDict.SeqDict
            (Evergreen.V407.SecretId.SecretId Evergreen.V407.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V407.Id.Id Evergreen.V407.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Thread.LastTypedAt (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId))
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V407.ChannelName.ChannelName
    , description : Evergreen.V407.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V407.MessageArray.MessageArray Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId)
    , visibleMessages : Evergreen.V407.VisibleMessages.VisibleMessages Evergreen.V407.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V407.Drawing.Drawing (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId))
    , permissionOverwrites : List Evergreen.V407.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V407.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V407.GuildName.GuildName
    , icon : Maybe Evergreen.V407.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V407.MembersAndOwner.MembersAndOwner
            (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V407.Discord.Id Evergreen.V407.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V407.Id.Id Evergreen.V407.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V407.Id.Id Evergreen.V407.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Thread.LastTypedAt (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId))
    }


type alias SlackFrontendChannel =
    { name : Evergreen.V407.ChannelName.ChannelName
    , isPrivate : Bool
    , messages : Evergreen.V407.MessageArray.MessageArray Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) (Evergreen.V407.Slack.Id Evergreen.V407.Slack.ChannelId)
    , visibleMessages : Evergreen.V407.VisibleMessages.VisibleMessages Evergreen.V407.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.Thread.SlackFrontendThread
    }


type alias SlackFrontendWorkspace =
    { name : String
    , icon : Maybe Evergreen.V407.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V407.Slack.Id Evergreen.V407.Slack.ChannelId) SlackFrontendChannel
    }


type alias SlackFrontendDmChannel =
    { teamId : Evergreen.V407.Slack.Id Evergreen.V407.Slack.TeamId
    , members : Evergreen.V407.NonemptySet.NonemptySet (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId)
    , messages : Evergreen.V407.MessageArray.MessageArray Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) (Evergreen.V407.Slack.Id Evergreen.V407.Slack.ChannelId)
    , visibleMessages : Evergreen.V407.VisibleMessages.VisibleMessages Evergreen.V407.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.Thread.SlackFrontendThread
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V407.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V407.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V407.Id.Id Evergreen.V407.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V407.GuildName.GuildName
    , owner : Evergreen.V407.Id.Id Evergreen.V407.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V407.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V407.Message.Message Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId))
    , permissionOverwrites : List Evergreen.V407.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V407.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V407.MembersAndOwner.MembersAndOwner
            (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V407.Discord.Id Evergreen.V407.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V407.NonemptyDict.NonemptyDict
            (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V407.Message.Message Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V407.Discord.PartialUser
        , icon : Maybe Evergreen.V407.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V407.Discord.User
        , linkedTo : Evergreen.V407.Id.Id Evergreen.V407.Id.UserId
        , icon : Maybe Evergreen.V407.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V407.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V407.Discord.User
        , linkedTo : Evergreen.V407.Id.Id Evergreen.V407.Id.UserId
        , icon : Maybe Evergreen.V407.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_SlackWorkspace =
    { name : String
    , domain : String
    , channels :
        SeqDict.SeqDict
            (Evergreen.V407.Slack.Id Evergreen.V407.Slack.ChannelId)
            { name : Evergreen.V407.ChannelName.ChannelName
            , isPrivate : Bool
            , linkedMembers : SeqSet.SeqSet (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId)
            , messageCount : Int
            , firstMessage : Maybe (Evergreen.V407.Message.Message Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) (Evergreen.V407.Slack.Id Evergreen.V407.Slack.ChannelId))
            }
    , linkedUsers :
        SeqDict.SeqDict
            (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId)
            { name : String
            , linkedTo : Evergreen.V407.Id.Id Evergreen.V407.Id.UserId
            }
    , userCount : Int
    }


type alias AdminData_SlackDmChannel =
    { teamId : Evergreen.V407.Slack.Id Evergreen.V407.Slack.TeamId
    , members :
        List
            { id : Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId
            , name : String
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V407.Message.Message Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) (Evergreen.V407.Slack.Id Evergreen.V407.Slack.ChannelId))
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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
    { users : AdminDataStatus (Evergreen.V407.NonemptyDict.NonemptyDict (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Evergreen.V407.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V407.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V407.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) AdminData_DiscordGuild)
    , slackWorkspaces : AdminDataStatus (SeqDict.SeqDict (Evergreen.V407.Slack.Id Evergreen.V407.Slack.TeamId) AdminData_SlackWorkspace)
    , slackDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V407.Slack.Id Evergreen.V407.Slack.DmChannelId) AdminData_SlackDmChannel)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , logs : Evergreen.V407.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V407.SessionIdHash.SessionIdHash, Evergreen.V407.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V407.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V407.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , orphanedFiles : AdminDataStatus (SeqDict.SeqDict Evergreen.V407.FileStatus.FileHash Evergreen.V407.FileStatus.BackendFileData)
    , deleteOrphanedFiles : DeleteOrphanedFilesStatus
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V407.SessionIdHash.SessionIdHash Evergreen.V407.UserSession.UserSession)
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    , seqDictWorks : List ( String, Int )
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Evergreen.V407.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId) Evergreen.V407.DmChannel.DiscordFrontendDmChannel
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V407.Slack.Id Evergreen.V407.Slack.TeamId) SlackFrontendWorkspace
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V407.Slack.Id Evergreen.V407.Slack.DmChannelId) SlackFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V407.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V407.SessionIdHash.SessionIdHash Evergreen.V407.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V407.TextEditor.LocalState
    , calls : Evergreen.V407.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V407.Id.Id Evergreen.V407.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V407.Id.Id Evergreen.V407.Id.UserId
    , name : Evergreen.V407.ChannelName.ChannelName
    , description : Evergreen.V407.ChannelDescription.ChannelDescription
    , messages : Evergreen.V407.IdArray.IdArray Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Message.Message Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId))
    , status : ChannelStatus
    , threads : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V407.Drawing.Drawing (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V407.Id.Id Evergreen.V407.Id.UserId
    , name : Evergreen.V407.GuildName.GuildName
    , icon : Maybe Evergreen.V407.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId) BackendChannel
    , membersAndOwner : Evergreen.V407.MembersAndOwner.MembersAndOwner (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) GuildMember
    , bannedUsers : SeqSet.SeqSet (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId)
    , invites :
        SeqDict.SeqDict
            (Evergreen.V407.SecretId.SecretId Evergreen.V407.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V407.Id.Id Evergreen.V407.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Thread.LastTypedAt (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId))
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V407.ChannelName.ChannelName
    , description : Evergreen.V407.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V407.IdArray.IdArray Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Message.Message Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId))
    , status : ChannelStatus
    , linkedMessageIds : Evergreen.V407.OneToOne.OneToOne (Evergreen.V407.Discord.Id Evergreen.V407.Discord.MessageId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V407.Drawing.Drawing (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId))
    , permissionOverwrites : List Evergreen.V407.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V407.GuildName.GuildName
    , icon : Maybe Evergreen.V407.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V407.MembersAndOwner.MembersAndOwner
            (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V407.Discord.Id Evergreen.V407.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V407.Id.Id Evergreen.V407.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V407.Id.Id Evergreen.V407.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Thread.LastTypedAt (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId))
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId
    , messages : List Evergreen.V407.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V407.Discord.Message
    , threads : List DiscordThreadReload
    }
