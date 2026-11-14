module Evergreen.V422.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V422.BackendMsgLog
import Evergreen.V422.Call
import Evergreen.V422.ChannelDescription
import Evergreen.V422.ChannelName
import Evergreen.V422.Discord
import Evergreen.V422.DiscordUserData
import Evergreen.V422.DmChannel
import Evergreen.V422.DmChannelId
import Evergreen.V422.Drawing
import Evergreen.V422.FileStatus
import Evergreen.V422.Game
import Evergreen.V422.GuildName
import Evergreen.V422.Id
import Evergreen.V422.IdArray
import Evergreen.V422.Log
import Evergreen.V422.MembersAndOwner
import Evergreen.V422.Message
import Evergreen.V422.MessageArray
import Evergreen.V422.NonemptyDict
import Evergreen.V422.NonemptySet
import Evergreen.V422.OneToOne
import Evergreen.V422.Pagination
import Evergreen.V422.PeerToPeer
import Evergreen.V422.Postmark
import Evergreen.V422.SecretId
import Evergreen.V422.SessionIdHash
import Evergreen.V422.Slack
import Evergreen.V422.TextEditor
import Evergreen.V422.Thread
import Evergreen.V422.ToBackendLog
import Evergreen.V422.User
import Evergreen.V422.UserSession
import Evergreen.V422.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V422.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V422.Log.Log
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V422.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V422.Call.RemoteCallData
    , currentlyViewing : Evergreen.V422.UserSession.Viewing
    , peerToPeerFiles : SeqDict.SeqDict Evergreen.V422.FileStatus.PeerToPeerId Evergreen.V422.PeerToPeer.SharedFile
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
    , archivedBy : Evergreen.V422.Id.Id Evergreen.V422.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V422.Id.Id Evergreen.V422.Id.UserId
    , name : Evergreen.V422.ChannelName.ChannelName
    , description : Evergreen.V422.ChannelDescription.ChannelDescription
    , messages : Evergreen.V422.MessageArray.MessageArray Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId)
    , visibleMessages : Evergreen.V422.VisibleMessages.VisibleMessages Evergreen.V422.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , threads : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V422.Drawing.Drawing (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.Game.MatchData
    }


type alias GuildMember =
    { joinedAt : Effect.Time.Posix
    , lastPostedAt : Maybe Effect.Time.Posix
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V422.Id.Id Evergreen.V422.Id.UserId
    , name : Evergreen.V422.GuildName.GuildName
    , icon : Maybe Evergreen.V422.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId) FrontendChannel
    , membersAndOwner : Evergreen.V422.MembersAndOwner.MembersAndOwner (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) GuildMember
    , invites :
        SeqDict.SeqDict
            (Evergreen.V422.SecretId.SecretId Evergreen.V422.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V422.Id.Id Evergreen.V422.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Thread.LastTypedAt (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId))
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V422.ChannelName.ChannelName
    , description : Evergreen.V422.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V422.MessageArray.MessageArray Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId)
    , visibleMessages : Evergreen.V422.VisibleMessages.VisibleMessages Evergreen.V422.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V422.Drawing.Drawing (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId))
    , permissionOverwrites : List Evergreen.V422.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V422.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V422.GuildName.GuildName
    , icon : Maybe Evergreen.V422.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V422.MembersAndOwner.MembersAndOwner
            (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V422.Discord.Id Evergreen.V422.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V422.Id.Id Evergreen.V422.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V422.Id.Id Evergreen.V422.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Thread.LastTypedAt (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId))
    }


type alias SlackFrontendChannel =
    { name : Evergreen.V422.ChannelName.ChannelName
    , isPrivate : Bool
    , messages : Evergreen.V422.MessageArray.MessageArray Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId)
    , visibleMessages : Evergreen.V422.VisibleMessages.VisibleMessages Evergreen.V422.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.Thread.SlackFrontendThread
    }


type alias SlackFrontendWorkspace =
    { name : String
    , icon : Maybe Evergreen.V422.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId) SlackFrontendChannel
    , customEmojis : SeqSet.SeqSet (Evergreen.V422.Id.Id Evergreen.V422.Id.CustomEmojiId)
    }


type alias SlackFrontendDmChannel =
    { teamId : Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId
    , members : Evergreen.V422.NonemptySet.NonemptySet (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId)
    , messages : Evergreen.V422.MessageArray.MessageArray Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId)
    , visibleMessages : Evergreen.V422.VisibleMessages.VisibleMessages Evergreen.V422.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.Thread.SlackFrontendThread
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V422.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V422.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V422.Id.Id Evergreen.V422.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V422.GuildName.GuildName
    , owner : Evergreen.V422.Id.Id Evergreen.V422.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V422.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V422.Message.Message Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId))
    , permissionOverwrites : List Evergreen.V422.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V422.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V422.MembersAndOwner.MembersAndOwner
            (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V422.Discord.Id Evergreen.V422.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V422.NonemptyDict.NonemptyDict
            (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V422.Message.Message Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V422.Discord.PartialUser
        , icon : Maybe Evergreen.V422.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V422.Discord.User
        , linkedTo : Evergreen.V422.Id.Id Evergreen.V422.Id.UserId
        , icon : Maybe Evergreen.V422.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V422.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V422.Discord.User
        , linkedTo : Evergreen.V422.Id.Id Evergreen.V422.Id.UserId
        , icon : Maybe Evergreen.V422.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_SlackWorkspace =
    { name : String
    , domain : String
    , channels :
        SeqDict.SeqDict
            (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId)
            { name : Evergreen.V422.ChannelName.ChannelName
            , isPrivate : Bool
            , linkedMembers : SeqSet.SeqSet (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId)
            , messageCount : Int
            , firstMessage : Maybe (Evergreen.V422.Message.Message Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId))
            }
    , linkedUsers :
        SeqDict.SeqDict
            (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId)
            { name : String
            , linkedTo : Evergreen.V422.Id.Id Evergreen.V422.Id.UserId
            }
    , userCount : Int
    }


type alias AdminData_SlackDmChannel =
    { teamId : Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId
    , members :
        List
            { id : Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId
            , name : String
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V422.Message.Message Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId))
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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
    { users : AdminDataStatus (Evergreen.V422.NonemptyDict.NonemptyDict (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , openRouterKey : Maybe String
    , notifyAdminsToken : Maybe String
    , notifyAdminsBotUserId : Maybe (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)
    , postmarkKey : Evergreen.V422.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V422.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) AdminData_DiscordGuild)
    , slackWorkspaces : AdminDataStatus (SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) AdminData_SlackWorkspace)
    , slackDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.DmChannelId) AdminData_SlackDmChannel)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , slackLinkingEnabled : Bool
    , slackLinkLimit : Maybe Int
    , logs : Evergreen.V422.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V422.SessionIdHash.SessionIdHash, Evergreen.V422.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V422.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V422.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , orphanedFiles : AdminDataStatus (SeqDict.SeqDict Evergreen.V422.FileStatus.FileHash Evergreen.V422.FileStatus.BackendFileData)
    , deleteOrphanedFiles : DeleteOrphanedFilesStatus
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V422.SessionIdHash.SessionIdHash Evergreen.V422.UserSession.UserSession)
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
    , guilds : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) Evergreen.V422.DmChannel.DiscordFrontendDmChannel
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) SlackFrontendWorkspace
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.DmChannelId) SlackFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V422.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V422.SessionIdHash.SessionIdHash Evergreen.V422.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V422.TextEditor.LocalState
    , calls : Evergreen.V422.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V422.Id.Id Evergreen.V422.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V422.Id.Id Evergreen.V422.Id.UserId
    , name : Evergreen.V422.ChannelName.ChannelName
    , description : Evergreen.V422.ChannelDescription.ChannelDescription
    , messages : Evergreen.V422.IdArray.IdArray Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Message.Message Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId))
    , status : ChannelStatus
    , threads : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V422.Drawing.Drawing (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V422.Id.Id Evergreen.V422.Id.UserId
    , name : Evergreen.V422.GuildName.GuildName
    , icon : Maybe Evergreen.V422.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId) BackendChannel
    , membersAndOwner : Evergreen.V422.MembersAndOwner.MembersAndOwner (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) GuildMember
    , bannedUsers : SeqSet.SeqSet (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)
    , invites :
        SeqDict.SeqDict
            (Evergreen.V422.SecretId.SecretId Evergreen.V422.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V422.Id.Id Evergreen.V422.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Thread.LastTypedAt (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId))
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V422.ChannelName.ChannelName
    , description : Evergreen.V422.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V422.IdArray.IdArray Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Message.Message Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId))
    , status : ChannelStatus
    , linkedMessageIds : Evergreen.V422.OneToOne.OneToOne (Evergreen.V422.Discord.Id Evergreen.V422.Discord.MessageId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V422.Drawing.Drawing (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId))
    , permissionOverwrites : List Evergreen.V422.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V422.GuildName.GuildName
    , icon : Maybe Evergreen.V422.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V422.MembersAndOwner.MembersAndOwner
            (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V422.Discord.Id Evergreen.V422.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V422.Id.Id Evergreen.V422.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V422.Id.Id Evergreen.V422.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Thread.LastTypedAt (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId))
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId
    , messages : List Evergreen.V422.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V422.Discord.Message
    , threads : List DiscordThreadReload
    }
