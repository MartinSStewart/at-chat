module Evergreen.V405.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V405.BackendMsgLog
import Evergreen.V405.Call
import Evergreen.V405.ChannelDescription
import Evergreen.V405.ChannelName
import Evergreen.V405.Discord
import Evergreen.V405.DiscordUserData
import Evergreen.V405.DmChannel
import Evergreen.V405.DmChannelId
import Evergreen.V405.Drawing
import Evergreen.V405.FileStatus
import Evergreen.V405.Game
import Evergreen.V405.GuildName
import Evergreen.V405.Id
import Evergreen.V405.IdArray
import Evergreen.V405.Log
import Evergreen.V405.MembersAndOwner
import Evergreen.V405.Message
import Evergreen.V405.MessageArray
import Evergreen.V405.NonemptyDict
import Evergreen.V405.NonemptySet
import Evergreen.V405.OneToOne
import Evergreen.V405.Pagination
import Evergreen.V405.Postmark
import Evergreen.V405.SecretId
import Evergreen.V405.SessionIdHash
import Evergreen.V405.Slack
import Evergreen.V405.TextEditor
import Evergreen.V405.Thread
import Evergreen.V405.ToBackendLog
import Evergreen.V405.User
import Evergreen.V405.UserSession
import Evergreen.V405.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V405.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V405.Log.Log
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V405.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V405.Call.RemoteCallData
    , currentlyViewing : Evergreen.V405.UserSession.Viewing
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
    , archivedBy : Evergreen.V405.Id.Id Evergreen.V405.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V405.Id.Id Evergreen.V405.Id.UserId
    , name : Evergreen.V405.ChannelName.ChannelName
    , description : Evergreen.V405.ChannelDescription.ChannelDescription
    , messages : Evergreen.V405.MessageArray.MessageArray Evergreen.V405.Id.ChannelMessageId (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId)
    , visibleMessages : Evergreen.V405.VisibleMessages.VisibleMessages Evergreen.V405.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , threads : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) Evergreen.V405.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V405.Drawing.Drawing (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) Evergreen.V405.Game.MatchData
    }


type alias GuildMember =
    { joinedAt : Effect.Time.Posix
    , lastPostedAt : Maybe Effect.Time.Posix
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V405.Id.Id Evergreen.V405.Id.UserId
    , name : Evergreen.V405.GuildName.GuildName
    , icon : Maybe Evergreen.V405.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId) FrontendChannel
    , membersAndOwner : Evergreen.V405.MembersAndOwner.MembersAndOwner (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) GuildMember
    , invites :
        SeqDict.SeqDict
            (Evergreen.V405.SecretId.SecretId Evergreen.V405.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V405.Id.Id Evergreen.V405.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Thread.LastTypedAt (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId))
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V405.ChannelName.ChannelName
    , description : Evergreen.V405.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V405.MessageArray.MessageArray Evergreen.V405.Id.ChannelMessageId (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId)
    , visibleMessages : Evergreen.V405.VisibleMessages.VisibleMessages Evergreen.V405.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) Evergreen.V405.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V405.Drawing.Drawing (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId))
    , permissionOverwrites : List Evergreen.V405.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V405.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V405.GuildName.GuildName
    , icon : Maybe Evergreen.V405.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V405.MembersAndOwner.MembersAndOwner
            (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V405.Discord.Id Evergreen.V405.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V405.Id.Id Evergreen.V405.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V405.Id.Id Evergreen.V405.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Thread.LastTypedAt (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId))
    }


type alias SlackFrontendChannel =
    { name : Evergreen.V405.ChannelName.ChannelName
    , isPrivate : Bool
    , messages : Evergreen.V405.MessageArray.MessageArray Evergreen.V405.Id.ChannelMessageId (Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId) (Evergreen.V405.Slack.Id Evergreen.V405.Slack.ChannelId)
    , visibleMessages : Evergreen.V405.VisibleMessages.VisibleMessages Evergreen.V405.Id.ChannelMessageId
    }


type alias SlackFrontendWorkspace =
    { name : String
    , channels : SeqDict.SeqDict (Evergreen.V405.Slack.Id Evergreen.V405.Slack.ChannelId) SlackFrontendChannel
    }


type alias SlackFrontendDmChannel =
    { teamId : Evergreen.V405.Slack.Id Evergreen.V405.Slack.TeamId
    , members : Evergreen.V405.NonemptySet.NonemptySet (Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId)
    , messages : Evergreen.V405.MessageArray.MessageArray Evergreen.V405.Id.ChannelMessageId (Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId) (Evergreen.V405.Slack.Id Evergreen.V405.Slack.ChannelId)
    , visibleMessages : Evergreen.V405.VisibleMessages.VisibleMessages Evergreen.V405.Id.ChannelMessageId
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V405.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V405.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V405.Id.Id Evergreen.V405.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V405.GuildName.GuildName
    , owner : Evergreen.V405.Id.Id Evergreen.V405.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V405.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V405.Message.Message Evergreen.V405.Id.ChannelMessageId (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId))
    , permissionOverwrites : List Evergreen.V405.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V405.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V405.MembersAndOwner.MembersAndOwner
            (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V405.Discord.Id Evergreen.V405.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V405.NonemptyDict.NonemptyDict
            (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V405.Message.Message Evergreen.V405.Id.ChannelMessageId (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V405.Discord.PartialUser
        , icon : Maybe Evergreen.V405.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V405.Discord.User
        , linkedTo : Evergreen.V405.Id.Id Evergreen.V405.Id.UserId
        , icon : Maybe Evergreen.V405.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V405.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V405.Discord.User
        , linkedTo : Evergreen.V405.Id.Id Evergreen.V405.Id.UserId
        , icon : Maybe Evergreen.V405.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_SlackWorkspace =
    { name : String
    , domain : String
    , channels :
        SeqDict.SeqDict
            (Evergreen.V405.Slack.Id Evergreen.V405.Slack.ChannelId)
            { name : Evergreen.V405.ChannelName.ChannelName
            , isPrivate : Bool
            , linkedMembers : SeqSet.SeqSet (Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId)
            , messageCount : Int
            , firstMessage : Maybe (Evergreen.V405.Message.Message Evergreen.V405.Id.ChannelMessageId (Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId) (Evergreen.V405.Slack.Id Evergreen.V405.Slack.ChannelId))
            }
    , linkedUsers :
        SeqDict.SeqDict
            (Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId)
            { name : String
            , linkedTo : Evergreen.V405.Id.Id Evergreen.V405.Id.UserId
            }
    , userCount : Int
    }


type alias AdminData_SlackDmChannel =
    { teamId : Evergreen.V405.Slack.Id Evergreen.V405.Slack.TeamId
    , members :
        List
            { id : Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId
            , name : String
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V405.Message.Message Evergreen.V405.Id.ChannelMessageId (Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId) (Evergreen.V405.Slack.Id Evergreen.V405.Slack.ChannelId))
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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
    { users : AdminDataStatus (Evergreen.V405.NonemptyDict.NonemptyDict (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Evergreen.V405.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V405.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V405.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) AdminData_DiscordGuild)
    , slackWorkspaces : AdminDataStatus (SeqDict.SeqDict (Evergreen.V405.Slack.Id Evergreen.V405.Slack.TeamId) AdminData_SlackWorkspace)
    , slackDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V405.Slack.Id Evergreen.V405.Slack.DmChannelId) AdminData_SlackDmChannel)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , logs : Evergreen.V405.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V405.SessionIdHash.SessionIdHash, Evergreen.V405.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V405.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V405.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , orphanedFiles : AdminDataStatus (SeqDict.SeqDict Evergreen.V405.FileStatus.FileHash Evergreen.V405.FileStatus.BackendFileData)
    , deleteOrphanedFiles : DeleteOrphanedFilesStatus
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V405.SessionIdHash.SessionIdHash Evergreen.V405.UserSession.UserSession)
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Evergreen.V405.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId) Evergreen.V405.DmChannel.DiscordFrontendDmChannel
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V405.Slack.Id Evergreen.V405.Slack.TeamId) SlackFrontendWorkspace
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V405.Slack.Id Evergreen.V405.Slack.DmChannelId) SlackFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V405.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V405.SessionIdHash.SessionIdHash Evergreen.V405.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V405.TextEditor.LocalState
    , calls : Evergreen.V405.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V405.Id.Id Evergreen.V405.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V405.Id.Id Evergreen.V405.Id.UserId
    , name : Evergreen.V405.ChannelName.ChannelName
    , description : Evergreen.V405.ChannelDescription.ChannelDescription
    , messages : Evergreen.V405.IdArray.IdArray Evergreen.V405.Id.ChannelMessageId (Evergreen.V405.Message.Message Evergreen.V405.Id.ChannelMessageId (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId))
    , status : ChannelStatus
    , threads : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) Evergreen.V405.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V405.Drawing.Drawing (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) Evergreen.V405.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V405.Id.Id Evergreen.V405.Id.UserId
    , name : Evergreen.V405.GuildName.GuildName
    , icon : Maybe Evergreen.V405.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId) BackendChannel
    , membersAndOwner : Evergreen.V405.MembersAndOwner.MembersAndOwner (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) GuildMember
    , bannedUsers : SeqSet.SeqSet (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId)
    , invites :
        SeqDict.SeqDict
            (Evergreen.V405.SecretId.SecretId Evergreen.V405.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V405.Id.Id Evergreen.V405.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Thread.LastTypedAt (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId))
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V405.ChannelName.ChannelName
    , description : Evergreen.V405.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V405.IdArray.IdArray Evergreen.V405.Id.ChannelMessageId (Evergreen.V405.Message.Message Evergreen.V405.Id.ChannelMessageId (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId))
    , status : ChannelStatus
    , linkedMessageIds : Evergreen.V405.OneToOne.OneToOne (Evergreen.V405.Discord.Id Evergreen.V405.Discord.MessageId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) Evergreen.V405.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V405.Drawing.Drawing (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId))
    , permissionOverwrites : List Evergreen.V405.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V405.GuildName.GuildName
    , icon : Maybe Evergreen.V405.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V405.MembersAndOwner.MembersAndOwner
            (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V405.Discord.Id Evergreen.V405.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V405.Id.Id Evergreen.V405.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V405.Id.Id Evergreen.V405.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Thread.LastTypedAt (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId))
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId
    , messages : List Evergreen.V405.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V405.Discord.Message
    , threads : List DiscordThreadReload
    }
