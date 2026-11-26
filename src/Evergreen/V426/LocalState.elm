module Evergreen.V426.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V426.BackendMsgLog
import Evergreen.V426.Call
import Evergreen.V426.ChannelDescription
import Evergreen.V426.ChannelName
import Evergreen.V426.Discord
import Evergreen.V426.DiscordUserData
import Evergreen.V426.DmChannel
import Evergreen.V426.DmChannelId
import Evergreen.V426.Drawing
import Evergreen.V426.FileStatus
import Evergreen.V426.Game
import Evergreen.V426.GuildName
import Evergreen.V426.Id
import Evergreen.V426.IdArray
import Evergreen.V426.Log
import Evergreen.V426.MembersAndOwner
import Evergreen.V426.Message
import Evergreen.V426.MessageArray
import Evergreen.V426.NonemptyDict
import Evergreen.V426.NonemptySet
import Evergreen.V426.OneToOne
import Evergreen.V426.Pagination
import Evergreen.V426.PeerToPeer
import Evergreen.V426.Postmark
import Evergreen.V426.SecretId
import Evergreen.V426.SessionIdHash
import Evergreen.V426.Slack
import Evergreen.V426.TextEditor
import Evergreen.V426.Thread
import Evergreen.V426.ToBackendLog
import Evergreen.V426.User
import Evergreen.V426.UserSession
import Evergreen.V426.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V426.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V426.Log.Log
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V426.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V426.Call.RemoteCallData
    , currentlyViewing : Evergreen.V426.UserSession.Viewing
    , peerToPeerFiles : SeqDict.SeqDict Evergreen.V426.FileStatus.PeerToPeerId Evergreen.V426.PeerToPeer.SharedFile
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
    , archivedBy : Evergreen.V426.Id.Id Evergreen.V426.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V426.Id.Id Evergreen.V426.Id.UserId
    , name : Evergreen.V426.ChannelName.ChannelName
    , description : Evergreen.V426.ChannelDescription.ChannelDescription
    , messages : Evergreen.V426.MessageArray.MessageArray Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId)
    , visibleMessages : Evergreen.V426.VisibleMessages.VisibleMessages Evergreen.V426.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , threads : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V426.Drawing.Drawing (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.Game.MatchData
    }


type alias GuildMember =
    { joinedAt : Effect.Time.Posix
    , lastPostedAt : Maybe Effect.Time.Posix
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V426.Id.Id Evergreen.V426.Id.UserId
    , name : Evergreen.V426.GuildName.GuildName
    , icon : Maybe Evergreen.V426.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId) FrontendChannel
    , membersAndOwner : Evergreen.V426.MembersAndOwner.MembersAndOwner (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) GuildMember
    , invites :
        SeqDict.SeqDict
            (Evergreen.V426.SecretId.SecretId Evergreen.V426.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V426.Id.Id Evergreen.V426.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Thread.LastTypedAt (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId))
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V426.ChannelName.ChannelName
    , description : Evergreen.V426.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V426.MessageArray.MessageArray Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId)
    , visibleMessages : Evergreen.V426.VisibleMessages.VisibleMessages Evergreen.V426.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V426.Drawing.Drawing (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId))
    , permissionOverwrites : List Evergreen.V426.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V426.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V426.GuildName.GuildName
    , icon : Maybe Evergreen.V426.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V426.MembersAndOwner.MembersAndOwner
            (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V426.Discord.Id Evergreen.V426.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V426.Id.Id Evergreen.V426.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V426.Id.Id Evergreen.V426.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Thread.LastTypedAt (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId))
    }


type alias SlackFrontendChannel =
    { name : Evergreen.V426.ChannelName.ChannelName
    , isPrivate : Bool
    , messages : Evergreen.V426.MessageArray.MessageArray Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId)
    , visibleMessages : Evergreen.V426.VisibleMessages.VisibleMessages Evergreen.V426.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.Thread.SlackFrontendThread
    }


type alias SlackFrontendWorkspace =
    { name : String
    , icon : Maybe Evergreen.V426.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId) SlackFrontendChannel
    , customEmojis : SeqSet.SeqSet (Evergreen.V426.Id.Id Evergreen.V426.Id.CustomEmojiId)
    }


type alias SlackFrontendDmChannel =
    { teamId : Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId
    , members : Evergreen.V426.NonemptySet.NonemptySet (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId)
    , messages : Evergreen.V426.MessageArray.MessageArray Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId)
    , visibleMessages : Evergreen.V426.VisibleMessages.VisibleMessages Evergreen.V426.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.Thread.SlackFrontendThread
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V426.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V426.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V426.Id.Id Evergreen.V426.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V426.GuildName.GuildName
    , owner : Evergreen.V426.Id.Id Evergreen.V426.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V426.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V426.Message.Message Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId))
    , permissionOverwrites : List Evergreen.V426.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V426.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V426.MembersAndOwner.MembersAndOwner
            (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V426.Discord.Id Evergreen.V426.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V426.NonemptyDict.NonemptyDict
            (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V426.Message.Message Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V426.Discord.PartialUser
        , icon : Maybe Evergreen.V426.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V426.Discord.User
        , linkedTo : Evergreen.V426.Id.Id Evergreen.V426.Id.UserId
        , icon : Maybe Evergreen.V426.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V426.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V426.Discord.User
        , linkedTo : Evergreen.V426.Id.Id Evergreen.V426.Id.UserId
        , icon : Maybe Evergreen.V426.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_SlackWorkspace =
    { name : String
    , domain : String
    , channels :
        SeqDict.SeqDict
            (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId)
            { name : Evergreen.V426.ChannelName.ChannelName
            , isPrivate : Bool
            , linkedMembers : SeqSet.SeqSet (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId)
            , messageCount : Int
            , firstMessage : Maybe (Evergreen.V426.Message.Message Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId))
            }
    , linkedUsers :
        SeqDict.SeqDict
            (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId)
            { name : String
            , linkedTo : Evergreen.V426.Id.Id Evergreen.V426.Id.UserId
            }
    , userCount : Int
    }


type alias AdminData_SlackDmChannel =
    { teamId : Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId
    , members :
        List
            { id : Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId
            , name : String
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V426.Message.Message Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId))
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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
    { users : AdminDataStatus (Evergreen.V426.NonemptyDict.NonemptyDict (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , openRouterKey : Maybe String
    , notifyAdminsToken : Maybe String
    , notifyAdminsBotUserId : Maybe (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)
    , postmarkKey : Evergreen.V426.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V426.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) AdminData_DiscordGuild)
    , slackWorkspaces : AdminDataStatus (SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) AdminData_SlackWorkspace)
    , slackDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.DmChannelId) AdminData_SlackDmChannel)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , slackLinkingEnabled : Bool
    , slackLinkLimit : Maybe Int
    , logs : Evergreen.V426.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V426.SessionIdHash.SessionIdHash, Evergreen.V426.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V426.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V426.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , orphanedFiles : AdminDataStatus (SeqDict.SeqDict Evergreen.V426.FileStatus.FileHash Evergreen.V426.FileStatus.BackendFileData)
    , deleteOrphanedFiles : DeleteOrphanedFilesStatus
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V426.SessionIdHash.SessionIdHash Evergreen.V426.UserSession.UserSession)
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
    , guilds : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) Evergreen.V426.DmChannel.DiscordFrontendDmChannel
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) SlackFrontendWorkspace
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.DmChannelId) SlackFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V426.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V426.SessionIdHash.SessionIdHash Evergreen.V426.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V426.TextEditor.LocalState
    , calls : Evergreen.V426.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V426.Id.Id Evergreen.V426.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V426.Id.Id Evergreen.V426.Id.UserId
    , name : Evergreen.V426.ChannelName.ChannelName
    , description : Evergreen.V426.ChannelDescription.ChannelDescription
    , messages : Evergreen.V426.IdArray.IdArray Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Message.Message Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId))
    , status : ChannelStatus
    , threads : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V426.Drawing.Drawing (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V426.Id.Id Evergreen.V426.Id.UserId
    , name : Evergreen.V426.GuildName.GuildName
    , icon : Maybe Evergreen.V426.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId) BackendChannel
    , membersAndOwner : Evergreen.V426.MembersAndOwner.MembersAndOwner (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) GuildMember
    , bannedUsers : SeqSet.SeqSet (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)
    , invites :
        SeqDict.SeqDict
            (Evergreen.V426.SecretId.SecretId Evergreen.V426.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V426.Id.Id Evergreen.V426.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Thread.LastTypedAt (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId))
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V426.ChannelName.ChannelName
    , description : Evergreen.V426.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V426.IdArray.IdArray Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Message.Message Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId))
    , status : ChannelStatus
    , linkedMessageIds : Evergreen.V426.OneToOne.OneToOne (Evergreen.V426.Discord.Id Evergreen.V426.Discord.MessageId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V426.Drawing.Drawing (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId))
    , permissionOverwrites : List Evergreen.V426.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V426.GuildName.GuildName
    , icon : Maybe Evergreen.V426.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V426.MembersAndOwner.MembersAndOwner
            (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V426.Discord.Id Evergreen.V426.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V426.Id.Id Evergreen.V426.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V426.Id.Id Evergreen.V426.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Thread.LastTypedAt (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId))
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId
    , messages : List Evergreen.V426.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V426.Discord.Message
    , threads : List DiscordThreadReload
    }
