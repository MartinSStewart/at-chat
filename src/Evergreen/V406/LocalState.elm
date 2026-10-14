module Evergreen.V406.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V406.BackendMsgLog
import Evergreen.V406.Call
import Evergreen.V406.ChannelDescription
import Evergreen.V406.ChannelName
import Evergreen.V406.Discord
import Evergreen.V406.DiscordUserData
import Evergreen.V406.DmChannel
import Evergreen.V406.DmChannelId
import Evergreen.V406.Drawing
import Evergreen.V406.FileStatus
import Evergreen.V406.Game
import Evergreen.V406.GuildName
import Evergreen.V406.Id
import Evergreen.V406.IdArray
import Evergreen.V406.Log
import Evergreen.V406.MembersAndOwner
import Evergreen.V406.Message
import Evergreen.V406.MessageArray
import Evergreen.V406.NonemptyDict
import Evergreen.V406.NonemptySet
import Evergreen.V406.OneToOne
import Evergreen.V406.Pagination
import Evergreen.V406.Postmark
import Evergreen.V406.SecretId
import Evergreen.V406.SessionIdHash
import Evergreen.V406.Slack
import Evergreen.V406.TextEditor
import Evergreen.V406.Thread
import Evergreen.V406.ToBackendLog
import Evergreen.V406.User
import Evergreen.V406.UserSession
import Evergreen.V406.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V406.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V406.Log.Log
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V406.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V406.Call.RemoteCallData
    , currentlyViewing : Evergreen.V406.UserSession.Viewing
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
    , archivedBy : Evergreen.V406.Id.Id Evergreen.V406.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V406.Id.Id Evergreen.V406.Id.UserId
    , name : Evergreen.V406.ChannelName.ChannelName
    , description : Evergreen.V406.ChannelDescription.ChannelDescription
    , messages : Evergreen.V406.MessageArray.MessageArray Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId)
    , visibleMessages : Evergreen.V406.VisibleMessages.VisibleMessages Evergreen.V406.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , threads : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) Evergreen.V406.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V406.Drawing.Drawing (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) Evergreen.V406.Game.MatchData
    }


type alias GuildMember =
    { joinedAt : Effect.Time.Posix
    , lastPostedAt : Maybe Effect.Time.Posix
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V406.Id.Id Evergreen.V406.Id.UserId
    , name : Evergreen.V406.GuildName.GuildName
    , icon : Maybe Evergreen.V406.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId) FrontendChannel
    , membersAndOwner : Evergreen.V406.MembersAndOwner.MembersAndOwner (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) GuildMember
    , invites :
        SeqDict.SeqDict
            (Evergreen.V406.SecretId.SecretId Evergreen.V406.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V406.Id.Id Evergreen.V406.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Thread.LastTypedAt (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId))
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V406.ChannelName.ChannelName
    , description : Evergreen.V406.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V406.MessageArray.MessageArray Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId)
    , visibleMessages : Evergreen.V406.VisibleMessages.VisibleMessages Evergreen.V406.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) Evergreen.V406.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V406.Drawing.Drawing (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId))
    , permissionOverwrites : List Evergreen.V406.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V406.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V406.GuildName.GuildName
    , icon : Maybe Evergreen.V406.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V406.MembersAndOwner.MembersAndOwner
            (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V406.Discord.Id Evergreen.V406.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V406.Id.Id Evergreen.V406.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V406.Id.Id Evergreen.V406.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Thread.LastTypedAt (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId))
    }


type alias SlackFrontendChannel =
    { name : Evergreen.V406.ChannelName.ChannelName
    , isPrivate : Bool
    , messages : Evergreen.V406.MessageArray.MessageArray Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId) (Evergreen.V406.Slack.Id Evergreen.V406.Slack.ChannelId)
    , visibleMessages : Evergreen.V406.VisibleMessages.VisibleMessages Evergreen.V406.Id.ChannelMessageId
    }


type alias SlackFrontendWorkspace =
    { name : String
    , channels : SeqDict.SeqDict (Evergreen.V406.Slack.Id Evergreen.V406.Slack.ChannelId) SlackFrontendChannel
    }


type alias SlackFrontendDmChannel =
    { teamId : Evergreen.V406.Slack.Id Evergreen.V406.Slack.TeamId
    , members : Evergreen.V406.NonemptySet.NonemptySet (Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId)
    , messages : Evergreen.V406.MessageArray.MessageArray Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId) (Evergreen.V406.Slack.Id Evergreen.V406.Slack.ChannelId)
    , visibleMessages : Evergreen.V406.VisibleMessages.VisibleMessages Evergreen.V406.Id.ChannelMessageId
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V406.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V406.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V406.Id.Id Evergreen.V406.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V406.GuildName.GuildName
    , owner : Evergreen.V406.Id.Id Evergreen.V406.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V406.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V406.Message.Message Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId))
    , permissionOverwrites : List Evergreen.V406.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V406.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V406.MembersAndOwner.MembersAndOwner
            (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V406.Discord.Id Evergreen.V406.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V406.NonemptyDict.NonemptyDict
            (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V406.Message.Message Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V406.Discord.PartialUser
        , icon : Maybe Evergreen.V406.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V406.Discord.User
        , linkedTo : Evergreen.V406.Id.Id Evergreen.V406.Id.UserId
        , icon : Maybe Evergreen.V406.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V406.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V406.Discord.User
        , linkedTo : Evergreen.V406.Id.Id Evergreen.V406.Id.UserId
        , icon : Maybe Evergreen.V406.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_SlackWorkspace =
    { name : String
    , domain : String
    , channels :
        SeqDict.SeqDict
            (Evergreen.V406.Slack.Id Evergreen.V406.Slack.ChannelId)
            { name : Evergreen.V406.ChannelName.ChannelName
            , isPrivate : Bool
            , linkedMembers : SeqSet.SeqSet (Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId)
            , messageCount : Int
            , firstMessage : Maybe (Evergreen.V406.Message.Message Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId) (Evergreen.V406.Slack.Id Evergreen.V406.Slack.ChannelId))
            }
    , linkedUsers :
        SeqDict.SeqDict
            (Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId)
            { name : String
            , linkedTo : Evergreen.V406.Id.Id Evergreen.V406.Id.UserId
            }
    , userCount : Int
    }


type alias AdminData_SlackDmChannel =
    { teamId : Evergreen.V406.Slack.Id Evergreen.V406.Slack.TeamId
    , members :
        List
            { id : Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId
            , name : String
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V406.Message.Message Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId) (Evergreen.V406.Slack.Id Evergreen.V406.Slack.ChannelId))
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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
    { users : AdminDataStatus (Evergreen.V406.NonemptyDict.NonemptyDict (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Evergreen.V406.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V406.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V406.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) AdminData_DiscordGuild)
    , slackWorkspaces : AdminDataStatus (SeqDict.SeqDict (Evergreen.V406.Slack.Id Evergreen.V406.Slack.TeamId) AdminData_SlackWorkspace)
    , slackDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V406.Slack.Id Evergreen.V406.Slack.DmChannelId) AdminData_SlackDmChannel)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , logs : Evergreen.V406.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V406.SessionIdHash.SessionIdHash, Evergreen.V406.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V406.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V406.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , orphanedFiles : AdminDataStatus (SeqDict.SeqDict Evergreen.V406.FileStatus.FileHash Evergreen.V406.FileStatus.BackendFileData)
    , deleteOrphanedFiles : DeleteOrphanedFilesStatus
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V406.SessionIdHash.SessionIdHash Evergreen.V406.UserSession.UserSession)
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
    , guilds : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Evergreen.V406.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId) Evergreen.V406.DmChannel.DiscordFrontendDmChannel
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V406.Slack.Id Evergreen.V406.Slack.TeamId) SlackFrontendWorkspace
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V406.Slack.Id Evergreen.V406.Slack.DmChannelId) SlackFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V406.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V406.SessionIdHash.SessionIdHash Evergreen.V406.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V406.TextEditor.LocalState
    , calls : Evergreen.V406.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V406.Id.Id Evergreen.V406.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V406.Id.Id Evergreen.V406.Id.UserId
    , name : Evergreen.V406.ChannelName.ChannelName
    , description : Evergreen.V406.ChannelDescription.ChannelDescription
    , messages : Evergreen.V406.IdArray.IdArray Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Message.Message Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId))
    , status : ChannelStatus
    , threads : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) Evergreen.V406.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V406.Drawing.Drawing (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) Evergreen.V406.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V406.Id.Id Evergreen.V406.Id.UserId
    , name : Evergreen.V406.GuildName.GuildName
    , icon : Maybe Evergreen.V406.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId) BackendChannel
    , membersAndOwner : Evergreen.V406.MembersAndOwner.MembersAndOwner (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) GuildMember
    , bannedUsers : SeqSet.SeqSet (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId)
    , invites :
        SeqDict.SeqDict
            (Evergreen.V406.SecretId.SecretId Evergreen.V406.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V406.Id.Id Evergreen.V406.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Thread.LastTypedAt (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId))
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V406.ChannelName.ChannelName
    , description : Evergreen.V406.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V406.IdArray.IdArray Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Message.Message Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId))
    , status : ChannelStatus
    , linkedMessageIds : Evergreen.V406.OneToOne.OneToOne (Evergreen.V406.Discord.Id Evergreen.V406.Discord.MessageId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) Evergreen.V406.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V406.Drawing.Drawing (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId))
    , permissionOverwrites : List Evergreen.V406.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V406.GuildName.GuildName
    , icon : Maybe Evergreen.V406.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V406.MembersAndOwner.MembersAndOwner
            (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V406.Discord.Id Evergreen.V406.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V406.Id.Id Evergreen.V406.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V406.Id.Id Evergreen.V406.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Thread.LastTypedAt (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId))
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId
    , messages : List Evergreen.V406.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V406.Discord.Message
    , threads : List DiscordThreadReload
    }
