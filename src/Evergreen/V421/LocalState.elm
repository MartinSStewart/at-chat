module Evergreen.V421.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V421.BackendMsgLog
import Evergreen.V421.Call
import Evergreen.V421.ChannelDescription
import Evergreen.V421.ChannelName
import Evergreen.V421.Discord
import Evergreen.V421.DiscordUserData
import Evergreen.V421.DmChannel
import Evergreen.V421.DmChannelId
import Evergreen.V421.Drawing
import Evergreen.V421.FileStatus
import Evergreen.V421.Game
import Evergreen.V421.GuildName
import Evergreen.V421.Id
import Evergreen.V421.IdArray
import Evergreen.V421.Log
import Evergreen.V421.MembersAndOwner
import Evergreen.V421.Message
import Evergreen.V421.MessageArray
import Evergreen.V421.NonemptyDict
import Evergreen.V421.NonemptySet
import Evergreen.V421.OneToOne
import Evergreen.V421.Pagination
import Evergreen.V421.PeerToPeer
import Evergreen.V421.Postmark
import Evergreen.V421.SecretId
import Evergreen.V421.SessionIdHash
import Evergreen.V421.Slack
import Evergreen.V421.TextEditor
import Evergreen.V421.Thread
import Evergreen.V421.ToBackendLog
import Evergreen.V421.User
import Evergreen.V421.UserSession
import Evergreen.V421.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V421.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V421.Log.Log
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V421.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V421.Call.RemoteCallData
    , currentlyViewing : Evergreen.V421.UserSession.Viewing
    , peerToPeerFiles : SeqDict.SeqDict Evergreen.V421.FileStatus.PeerToPeerId Evergreen.V421.PeerToPeer.SharedFile
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
    , archivedBy : Evergreen.V421.Id.Id Evergreen.V421.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V421.Id.Id Evergreen.V421.Id.UserId
    , name : Evergreen.V421.ChannelName.ChannelName
    , description : Evergreen.V421.ChannelDescription.ChannelDescription
    , messages : Evergreen.V421.MessageArray.MessageArray Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId)
    , visibleMessages : Evergreen.V421.VisibleMessages.VisibleMessages Evergreen.V421.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , threads : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V421.Drawing.Drawing (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.Game.MatchData
    }


type alias GuildMember =
    { joinedAt : Effect.Time.Posix
    , lastPostedAt : Maybe Effect.Time.Posix
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V421.Id.Id Evergreen.V421.Id.UserId
    , name : Evergreen.V421.GuildName.GuildName
    , icon : Maybe Evergreen.V421.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId) FrontendChannel
    , membersAndOwner : Evergreen.V421.MembersAndOwner.MembersAndOwner (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) GuildMember
    , invites :
        SeqDict.SeqDict
            (Evergreen.V421.SecretId.SecretId Evergreen.V421.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V421.Id.Id Evergreen.V421.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Thread.LastTypedAt (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId))
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V421.ChannelName.ChannelName
    , description : Evergreen.V421.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V421.MessageArray.MessageArray Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId)
    , visibleMessages : Evergreen.V421.VisibleMessages.VisibleMessages Evergreen.V421.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V421.Drawing.Drawing (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId))
    , permissionOverwrites : List Evergreen.V421.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V421.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V421.GuildName.GuildName
    , icon : Maybe Evergreen.V421.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V421.MembersAndOwner.MembersAndOwner
            (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V421.Discord.Id Evergreen.V421.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V421.Id.Id Evergreen.V421.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V421.Id.Id Evergreen.V421.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Thread.LastTypedAt (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId))
    }


type alias SlackFrontendChannel =
    { name : Evergreen.V421.ChannelName.ChannelName
    , isPrivate : Bool
    , messages : Evergreen.V421.MessageArray.MessageArray Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId)
    , visibleMessages : Evergreen.V421.VisibleMessages.VisibleMessages Evergreen.V421.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.Thread.SlackFrontendThread
    }


type alias SlackFrontendWorkspace =
    { name : String
    , icon : Maybe Evergreen.V421.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId) SlackFrontendChannel
    , customEmojis : SeqSet.SeqSet (Evergreen.V421.Id.Id Evergreen.V421.Id.CustomEmojiId)
    }


type alias SlackFrontendDmChannel =
    { teamId : Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId
    , members : Evergreen.V421.NonemptySet.NonemptySet (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId)
    , messages : Evergreen.V421.MessageArray.MessageArray Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId)
    , visibleMessages : Evergreen.V421.VisibleMessages.VisibleMessages Evergreen.V421.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.Thread.SlackFrontendThread
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V421.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V421.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V421.Id.Id Evergreen.V421.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V421.GuildName.GuildName
    , owner : Evergreen.V421.Id.Id Evergreen.V421.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V421.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V421.Message.Message Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId))
    , permissionOverwrites : List Evergreen.V421.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V421.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V421.MembersAndOwner.MembersAndOwner
            (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V421.Discord.Id Evergreen.V421.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V421.NonemptyDict.NonemptyDict
            (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V421.Message.Message Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V421.Discord.PartialUser
        , icon : Maybe Evergreen.V421.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V421.Discord.User
        , linkedTo : Evergreen.V421.Id.Id Evergreen.V421.Id.UserId
        , icon : Maybe Evergreen.V421.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V421.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V421.Discord.User
        , linkedTo : Evergreen.V421.Id.Id Evergreen.V421.Id.UserId
        , icon : Maybe Evergreen.V421.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_SlackWorkspace =
    { name : String
    , domain : String
    , channels :
        SeqDict.SeqDict
            (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId)
            { name : Evergreen.V421.ChannelName.ChannelName
            , isPrivate : Bool
            , linkedMembers : SeqSet.SeqSet (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId)
            , messageCount : Int
            , firstMessage : Maybe (Evergreen.V421.Message.Message Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId))
            }
    , linkedUsers :
        SeqDict.SeqDict
            (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId)
            { name : String
            , linkedTo : Evergreen.V421.Id.Id Evergreen.V421.Id.UserId
            }
    , userCount : Int
    }


type alias AdminData_SlackDmChannel =
    { teamId : Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId
    , members :
        List
            { id : Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId
            , name : String
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V421.Message.Message Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId))
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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
    { users : AdminDataStatus (Evergreen.V421.NonemptyDict.NonemptyDict (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , openRouterKey : Maybe String
    , notifyAdminsToken : Maybe String
    , notifyAdminsBotUserId : Maybe (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)
    , postmarkKey : Evergreen.V421.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V421.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) AdminData_DiscordGuild)
    , slackWorkspaces : AdminDataStatus (SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) AdminData_SlackWorkspace)
    , slackDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.DmChannelId) AdminData_SlackDmChannel)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , slackLinkingEnabled : Bool
    , slackLinkLimit : Maybe Int
    , logs : Evergreen.V421.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V421.SessionIdHash.SessionIdHash, Evergreen.V421.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V421.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V421.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , orphanedFiles : AdminDataStatus (SeqDict.SeqDict Evergreen.V421.FileStatus.FileHash Evergreen.V421.FileStatus.BackendFileData)
    , deleteOrphanedFiles : DeleteOrphanedFilesStatus
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V421.SessionIdHash.SessionIdHash Evergreen.V421.UserSession.UserSession)
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
    , guilds : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId) Evergreen.V421.DmChannel.DiscordFrontendDmChannel
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) SlackFrontendWorkspace
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.DmChannelId) SlackFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V421.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V421.SessionIdHash.SessionIdHash Evergreen.V421.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V421.TextEditor.LocalState
    , calls : Evergreen.V421.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V421.Id.Id Evergreen.V421.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V421.Id.Id Evergreen.V421.Id.UserId
    , name : Evergreen.V421.ChannelName.ChannelName
    , description : Evergreen.V421.ChannelDescription.ChannelDescription
    , messages : Evergreen.V421.IdArray.IdArray Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Message.Message Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId))
    , status : ChannelStatus
    , threads : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V421.Drawing.Drawing (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V421.Id.Id Evergreen.V421.Id.UserId
    , name : Evergreen.V421.GuildName.GuildName
    , icon : Maybe Evergreen.V421.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId) BackendChannel
    , membersAndOwner : Evergreen.V421.MembersAndOwner.MembersAndOwner (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) GuildMember
    , bannedUsers : SeqSet.SeqSet (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)
    , invites :
        SeqDict.SeqDict
            (Evergreen.V421.SecretId.SecretId Evergreen.V421.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V421.Id.Id Evergreen.V421.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Thread.LastTypedAt (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId))
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V421.ChannelName.ChannelName
    , description : Evergreen.V421.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V421.IdArray.IdArray Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Message.Message Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId))
    , status : ChannelStatus
    , linkedMessageIds : Evergreen.V421.OneToOne.OneToOne (Evergreen.V421.Discord.Id Evergreen.V421.Discord.MessageId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V421.Drawing.Drawing (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId))
    , permissionOverwrites : List Evergreen.V421.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V421.GuildName.GuildName
    , icon : Maybe Evergreen.V421.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V421.MembersAndOwner.MembersAndOwner
            (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V421.Discord.Id Evergreen.V421.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V421.Id.Id Evergreen.V421.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V421.Id.Id Evergreen.V421.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Thread.LastTypedAt (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId))
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId
    , messages : List Evergreen.V421.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V421.Discord.Message
    , threads : List DiscordThreadReload
    }
