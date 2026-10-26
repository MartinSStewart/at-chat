module Evergreen.V412.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V412.BackendMsgLog
import Evergreen.V412.Call
import Evergreen.V412.ChannelDescription
import Evergreen.V412.ChannelName
import Evergreen.V412.Discord
import Evergreen.V412.DiscordUserData
import Evergreen.V412.DmChannel
import Evergreen.V412.DmChannelId
import Evergreen.V412.Drawing
import Evergreen.V412.FileStatus
import Evergreen.V412.Game
import Evergreen.V412.GuildName
import Evergreen.V412.Id
import Evergreen.V412.IdArray
import Evergreen.V412.Log
import Evergreen.V412.MembersAndOwner
import Evergreen.V412.Message
import Evergreen.V412.MessageArray
import Evergreen.V412.NonemptyDict
import Evergreen.V412.NonemptySet
import Evergreen.V412.OneToOne
import Evergreen.V412.Pagination
import Evergreen.V412.Postmark
import Evergreen.V412.SecretId
import Evergreen.V412.SessionIdHash
import Evergreen.V412.Slack
import Evergreen.V412.TextEditor
import Evergreen.V412.Thread
import Evergreen.V412.ToBackendLog
import Evergreen.V412.User
import Evergreen.V412.UserSession
import Evergreen.V412.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V412.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V412.Log.Log
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V412.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V412.Call.RemoteCallData
    , currentlyViewing : Evergreen.V412.UserSession.Viewing
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
    , archivedBy : Evergreen.V412.Id.Id Evergreen.V412.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V412.Id.Id Evergreen.V412.Id.UserId
    , name : Evergreen.V412.ChannelName.ChannelName
    , description : Evergreen.V412.ChannelDescription.ChannelDescription
    , messages : Evergreen.V412.MessageArray.MessageArray Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId)
    , visibleMessages : Evergreen.V412.VisibleMessages.VisibleMessages Evergreen.V412.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , threads : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V412.Drawing.Drawing (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.Game.MatchData
    }


type alias GuildMember =
    { joinedAt : Effect.Time.Posix
    , lastPostedAt : Maybe Effect.Time.Posix
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V412.Id.Id Evergreen.V412.Id.UserId
    , name : Evergreen.V412.GuildName.GuildName
    , icon : Maybe Evergreen.V412.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId) FrontendChannel
    , membersAndOwner : Evergreen.V412.MembersAndOwner.MembersAndOwner (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) GuildMember
    , invites :
        SeqDict.SeqDict
            (Evergreen.V412.SecretId.SecretId Evergreen.V412.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V412.Id.Id Evergreen.V412.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Thread.LastTypedAt (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId))
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V412.ChannelName.ChannelName
    , description : Evergreen.V412.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V412.MessageArray.MessageArray Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId)
    , visibleMessages : Evergreen.V412.VisibleMessages.VisibleMessages Evergreen.V412.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V412.Drawing.Drawing (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId))
    , permissionOverwrites : List Evergreen.V412.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V412.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V412.GuildName.GuildName
    , icon : Maybe Evergreen.V412.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V412.MembersAndOwner.MembersAndOwner
            (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V412.Discord.Id Evergreen.V412.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V412.Id.Id Evergreen.V412.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V412.Id.Id Evergreen.V412.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Thread.LastTypedAt (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId))
    }


type alias SlackFrontendChannel =
    { name : Evergreen.V412.ChannelName.ChannelName
    , isPrivate : Bool
    , messages : Evergreen.V412.MessageArray.MessageArray Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId)
    , visibleMessages : Evergreen.V412.VisibleMessages.VisibleMessages Evergreen.V412.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.Thread.SlackFrontendThread
    }


type alias SlackFrontendWorkspace =
    { name : String
    , icon : Maybe Evergreen.V412.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId) SlackFrontendChannel
    , customEmojis : SeqSet.SeqSet (Evergreen.V412.Id.Id Evergreen.V412.Id.CustomEmojiId)
    }


type alias SlackFrontendDmChannel =
    { teamId : Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId
    , members : Evergreen.V412.NonemptySet.NonemptySet (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId)
    , messages : Evergreen.V412.MessageArray.MessageArray Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId)
    , visibleMessages : Evergreen.V412.VisibleMessages.VisibleMessages Evergreen.V412.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.Thread.SlackFrontendThread
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V412.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V412.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V412.Id.Id Evergreen.V412.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V412.GuildName.GuildName
    , owner : Evergreen.V412.Id.Id Evergreen.V412.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V412.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V412.Message.Message Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId))
    , permissionOverwrites : List Evergreen.V412.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V412.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V412.MembersAndOwner.MembersAndOwner
            (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V412.Discord.Id Evergreen.V412.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V412.NonemptyDict.NonemptyDict
            (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V412.Message.Message Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V412.Discord.PartialUser
        , icon : Maybe Evergreen.V412.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V412.Discord.User
        , linkedTo : Evergreen.V412.Id.Id Evergreen.V412.Id.UserId
        , icon : Maybe Evergreen.V412.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V412.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V412.Discord.User
        , linkedTo : Evergreen.V412.Id.Id Evergreen.V412.Id.UserId
        , icon : Maybe Evergreen.V412.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_SlackWorkspace =
    { name : String
    , domain : String
    , channels :
        SeqDict.SeqDict
            (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId)
            { name : Evergreen.V412.ChannelName.ChannelName
            , isPrivate : Bool
            , linkedMembers : SeqSet.SeqSet (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId)
            , messageCount : Int
            , firstMessage : Maybe (Evergreen.V412.Message.Message Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId))
            }
    , linkedUsers :
        SeqDict.SeqDict
            (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId)
            { name : String
            , linkedTo : Evergreen.V412.Id.Id Evergreen.V412.Id.UserId
            }
    , userCount : Int
    }


type alias AdminData_SlackDmChannel =
    { teamId : Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId
    , members :
        List
            { id : Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId
            , name : String
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V412.Message.Message Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId))
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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
    { users : AdminDataStatus (Evergreen.V412.NonemptyDict.NonemptyDict (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Evergreen.V412.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , openRouterKey : Maybe String
    , notifyAdminsToken : Maybe String
    , notifyAdminsBotUserId : Maybe (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId)
    , postmarkKey : Evergreen.V412.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V412.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) AdminData_DiscordGuild)
    , slackWorkspaces : AdminDataStatus (SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) AdminData_SlackWorkspace)
    , slackDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.DmChannelId) AdminData_SlackDmChannel)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , slackLinkingEnabled : Bool
    , slackLinkLimit : Maybe Int
    , logs : Evergreen.V412.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V412.SessionIdHash.SessionIdHash, Evergreen.V412.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V412.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V412.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , orphanedFiles : AdminDataStatus (SeqDict.SeqDict Evergreen.V412.FileStatus.FileHash Evergreen.V412.FileStatus.BackendFileData)
    , deleteOrphanedFiles : DeleteOrphanedFilesStatus
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V412.SessionIdHash.SessionIdHash Evergreen.V412.UserSession.UserSession)
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
    , guilds : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Evergreen.V412.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId) Evergreen.V412.DmChannel.DiscordFrontendDmChannel
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) SlackFrontendWorkspace
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.DmChannelId) SlackFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V412.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V412.SessionIdHash.SessionIdHash Evergreen.V412.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V412.TextEditor.LocalState
    , calls : Evergreen.V412.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V412.Id.Id Evergreen.V412.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V412.Id.Id Evergreen.V412.Id.UserId
    , name : Evergreen.V412.ChannelName.ChannelName
    , description : Evergreen.V412.ChannelDescription.ChannelDescription
    , messages : Evergreen.V412.IdArray.IdArray Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Message.Message Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId))
    , status : ChannelStatus
    , threads : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V412.Drawing.Drawing (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V412.Id.Id Evergreen.V412.Id.UserId
    , name : Evergreen.V412.GuildName.GuildName
    , icon : Maybe Evergreen.V412.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId) BackendChannel
    , membersAndOwner : Evergreen.V412.MembersAndOwner.MembersAndOwner (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) GuildMember
    , bannedUsers : SeqSet.SeqSet (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId)
    , invites :
        SeqDict.SeqDict
            (Evergreen.V412.SecretId.SecretId Evergreen.V412.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V412.Id.Id Evergreen.V412.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Thread.LastTypedAt (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId))
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V412.ChannelName.ChannelName
    , description : Evergreen.V412.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V412.IdArray.IdArray Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Message.Message Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId))
    , status : ChannelStatus
    , linkedMessageIds : Evergreen.V412.OneToOne.OneToOne (Evergreen.V412.Discord.Id Evergreen.V412.Discord.MessageId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V412.Drawing.Drawing (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId))
    , permissionOverwrites : List Evergreen.V412.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V412.GuildName.GuildName
    , icon : Maybe Evergreen.V412.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V412.MembersAndOwner.MembersAndOwner
            (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V412.Discord.Id Evergreen.V412.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V412.Id.Id Evergreen.V412.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V412.Id.Id Evergreen.V412.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Thread.LastTypedAt (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId))
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId
    , messages : List Evergreen.V412.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V412.Discord.Message
    , threads : List DiscordThreadReload
    }
