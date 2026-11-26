module Evergreen.V425.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V425.BackendMsgLog
import Evergreen.V425.Call
import Evergreen.V425.ChannelDescription
import Evergreen.V425.ChannelName
import Evergreen.V425.Discord
import Evergreen.V425.DiscordUserData
import Evergreen.V425.DmChannel
import Evergreen.V425.DmChannelId
import Evergreen.V425.Drawing
import Evergreen.V425.FileStatus
import Evergreen.V425.Game
import Evergreen.V425.GuildName
import Evergreen.V425.Id
import Evergreen.V425.IdArray
import Evergreen.V425.Log
import Evergreen.V425.MembersAndOwner
import Evergreen.V425.Message
import Evergreen.V425.MessageArray
import Evergreen.V425.NonemptyDict
import Evergreen.V425.NonemptySet
import Evergreen.V425.OneToOne
import Evergreen.V425.Pagination
import Evergreen.V425.PeerToPeer
import Evergreen.V425.Postmark
import Evergreen.V425.SecretId
import Evergreen.V425.SessionIdHash
import Evergreen.V425.Slack
import Evergreen.V425.TextEditor
import Evergreen.V425.Thread
import Evergreen.V425.ToBackendLog
import Evergreen.V425.User
import Evergreen.V425.UserSession
import Evergreen.V425.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V425.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V425.Log.Log
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V425.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V425.Call.RemoteCallData
    , currentlyViewing : Evergreen.V425.UserSession.Viewing
    , peerToPeerFiles : SeqDict.SeqDict Evergreen.V425.FileStatus.PeerToPeerId Evergreen.V425.PeerToPeer.SharedFile
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
    , archivedBy : Evergreen.V425.Id.Id Evergreen.V425.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V425.Id.Id Evergreen.V425.Id.UserId
    , name : Evergreen.V425.ChannelName.ChannelName
    , description : Evergreen.V425.ChannelDescription.ChannelDescription
    , messages : Evergreen.V425.MessageArray.MessageArray Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId)
    , visibleMessages : Evergreen.V425.VisibleMessages.VisibleMessages Evergreen.V425.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , threads : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V425.Drawing.Drawing (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.Game.MatchData
    }


type alias GuildMember =
    { joinedAt : Effect.Time.Posix
    , lastPostedAt : Maybe Effect.Time.Posix
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V425.Id.Id Evergreen.V425.Id.UserId
    , name : Evergreen.V425.GuildName.GuildName
    , icon : Maybe Evergreen.V425.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId) FrontendChannel
    , membersAndOwner : Evergreen.V425.MembersAndOwner.MembersAndOwner (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) GuildMember
    , invites :
        SeqDict.SeqDict
            (Evergreen.V425.SecretId.SecretId Evergreen.V425.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V425.Id.Id Evergreen.V425.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Thread.LastTypedAt (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId))
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V425.ChannelName.ChannelName
    , description : Evergreen.V425.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V425.MessageArray.MessageArray Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId)
    , visibleMessages : Evergreen.V425.VisibleMessages.VisibleMessages Evergreen.V425.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V425.Drawing.Drawing (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId))
    , permissionOverwrites : List Evergreen.V425.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V425.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V425.GuildName.GuildName
    , icon : Maybe Evergreen.V425.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V425.MembersAndOwner.MembersAndOwner
            (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V425.Discord.Id Evergreen.V425.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V425.Id.Id Evergreen.V425.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V425.Id.Id Evergreen.V425.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Thread.LastTypedAt (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId))
    }


type alias SlackFrontendChannel =
    { name : Evergreen.V425.ChannelName.ChannelName
    , isPrivate : Bool
    , messages : Evergreen.V425.MessageArray.MessageArray Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId)
    , visibleMessages : Evergreen.V425.VisibleMessages.VisibleMessages Evergreen.V425.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.Thread.SlackFrontendThread
    }


type alias SlackFrontendWorkspace =
    { name : String
    , icon : Maybe Evergreen.V425.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId) SlackFrontendChannel
    , customEmojis : SeqSet.SeqSet (Evergreen.V425.Id.Id Evergreen.V425.Id.CustomEmojiId)
    }


type alias SlackFrontendDmChannel =
    { teamId : Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId
    , members : Evergreen.V425.NonemptySet.NonemptySet (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId)
    , messages : Evergreen.V425.MessageArray.MessageArray Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId)
    , visibleMessages : Evergreen.V425.VisibleMessages.VisibleMessages Evergreen.V425.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.Thread.SlackFrontendThread
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V425.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V425.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V425.Id.Id Evergreen.V425.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V425.GuildName.GuildName
    , owner : Evergreen.V425.Id.Id Evergreen.V425.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V425.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V425.Message.Message Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId))
    , permissionOverwrites : List Evergreen.V425.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V425.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V425.MembersAndOwner.MembersAndOwner
            (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V425.Discord.Id Evergreen.V425.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V425.NonemptyDict.NonemptyDict
            (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V425.Message.Message Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V425.Discord.PartialUser
        , icon : Maybe Evergreen.V425.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V425.Discord.User
        , linkedTo : Evergreen.V425.Id.Id Evergreen.V425.Id.UserId
        , icon : Maybe Evergreen.V425.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V425.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V425.Discord.User
        , linkedTo : Evergreen.V425.Id.Id Evergreen.V425.Id.UserId
        , icon : Maybe Evergreen.V425.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_SlackWorkspace =
    { name : String
    , domain : String
    , channels :
        SeqDict.SeqDict
            (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId)
            { name : Evergreen.V425.ChannelName.ChannelName
            , isPrivate : Bool
            , linkedMembers : SeqSet.SeqSet (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId)
            , messageCount : Int
            , firstMessage : Maybe (Evergreen.V425.Message.Message Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId))
            }
    , linkedUsers :
        SeqDict.SeqDict
            (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId)
            { name : String
            , linkedTo : Evergreen.V425.Id.Id Evergreen.V425.Id.UserId
            }
    , userCount : Int
    }


type alias AdminData_SlackDmChannel =
    { teamId : Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId
    , members :
        List
            { id : Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId
            , name : String
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V425.Message.Message Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId))
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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
    { users : AdminDataStatus (Evergreen.V425.NonemptyDict.NonemptyDict (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , openRouterKey : Maybe String
    , notifyAdminsToken : Maybe String
    , notifyAdminsBotUserId : Maybe (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)
    , postmarkKey : Evergreen.V425.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V425.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) AdminData_DiscordGuild)
    , slackWorkspaces : AdminDataStatus (SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) AdminData_SlackWorkspace)
    , slackDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.DmChannelId) AdminData_SlackDmChannel)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , slackLinkingEnabled : Bool
    , slackLinkLimit : Maybe Int
    , logs : Evergreen.V425.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V425.SessionIdHash.SessionIdHash, Evergreen.V425.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V425.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V425.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , orphanedFiles : AdminDataStatus (SeqDict.SeqDict Evergreen.V425.FileStatus.FileHash Evergreen.V425.FileStatus.BackendFileData)
    , deleteOrphanedFiles : DeleteOrphanedFilesStatus
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V425.SessionIdHash.SessionIdHash Evergreen.V425.UserSession.UserSession)
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
    , guilds : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) Evergreen.V425.DmChannel.DiscordFrontendDmChannel
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) SlackFrontendWorkspace
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.DmChannelId) SlackFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V425.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V425.SessionIdHash.SessionIdHash Evergreen.V425.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V425.TextEditor.LocalState
    , calls : Evergreen.V425.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V425.Id.Id Evergreen.V425.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V425.Id.Id Evergreen.V425.Id.UserId
    , name : Evergreen.V425.ChannelName.ChannelName
    , description : Evergreen.V425.ChannelDescription.ChannelDescription
    , messages : Evergreen.V425.IdArray.IdArray Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Message.Message Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId))
    , status : ChannelStatus
    , threads : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V425.Drawing.Drawing (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V425.Id.Id Evergreen.V425.Id.UserId
    , name : Evergreen.V425.GuildName.GuildName
    , icon : Maybe Evergreen.V425.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId) BackendChannel
    , membersAndOwner : Evergreen.V425.MembersAndOwner.MembersAndOwner (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) GuildMember
    , bannedUsers : SeqSet.SeqSet (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)
    , invites :
        SeqDict.SeqDict
            (Evergreen.V425.SecretId.SecretId Evergreen.V425.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V425.Id.Id Evergreen.V425.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Thread.LastTypedAt (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId))
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V425.ChannelName.ChannelName
    , description : Evergreen.V425.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V425.IdArray.IdArray Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Message.Message Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId))
    , status : ChannelStatus
    , linkedMessageIds : Evergreen.V425.OneToOne.OneToOne (Evergreen.V425.Discord.Id Evergreen.V425.Discord.MessageId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V425.Drawing.Drawing (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId))
    , permissionOverwrites : List Evergreen.V425.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V425.GuildName.GuildName
    , icon : Maybe Evergreen.V425.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V425.MembersAndOwner.MembersAndOwner
            (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V425.Discord.Id Evergreen.V425.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V425.Id.Id Evergreen.V425.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V425.Id.Id Evergreen.V425.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Thread.LastTypedAt (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId))
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId
    , messages : List Evergreen.V425.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V425.Discord.Message
    , threads : List DiscordThreadReload
    }
