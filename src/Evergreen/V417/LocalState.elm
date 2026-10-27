module Evergreen.V417.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V417.BackendMsgLog
import Evergreen.V417.Call
import Evergreen.V417.ChannelDescription
import Evergreen.V417.ChannelName
import Evergreen.V417.Discord
import Evergreen.V417.DiscordUserData
import Evergreen.V417.DmChannel
import Evergreen.V417.DmChannelId
import Evergreen.V417.Drawing
import Evergreen.V417.FileStatus
import Evergreen.V417.Game
import Evergreen.V417.GuildName
import Evergreen.V417.Id
import Evergreen.V417.IdArray
import Evergreen.V417.Log
import Evergreen.V417.MembersAndOwner
import Evergreen.V417.Message
import Evergreen.V417.MessageArray
import Evergreen.V417.NonemptyDict
import Evergreen.V417.NonemptySet
import Evergreen.V417.OneToOne
import Evergreen.V417.Pagination
import Evergreen.V417.Postmark
import Evergreen.V417.SecretId
import Evergreen.V417.SessionIdHash
import Evergreen.V417.Slack
import Evergreen.V417.TextEditor
import Evergreen.V417.Thread
import Evergreen.V417.ToBackendLog
import Evergreen.V417.User
import Evergreen.V417.UserSession
import Evergreen.V417.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V417.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V417.Log.Log
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V417.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V417.Call.RemoteCallData
    , currentlyViewing : Evergreen.V417.UserSession.Viewing
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
    , archivedBy : Evergreen.V417.Id.Id Evergreen.V417.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V417.Id.Id Evergreen.V417.Id.UserId
    , name : Evergreen.V417.ChannelName.ChannelName
    , description : Evergreen.V417.ChannelDescription.ChannelDescription
    , messages : Evergreen.V417.MessageArray.MessageArray Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId)
    , visibleMessages : Evergreen.V417.VisibleMessages.VisibleMessages Evergreen.V417.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , threads : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V417.Drawing.Drawing (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.Game.MatchData
    }


type alias GuildMember =
    { joinedAt : Effect.Time.Posix
    , lastPostedAt : Maybe Effect.Time.Posix
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V417.Id.Id Evergreen.V417.Id.UserId
    , name : Evergreen.V417.GuildName.GuildName
    , icon : Maybe Evergreen.V417.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId) FrontendChannel
    , membersAndOwner : Evergreen.V417.MembersAndOwner.MembersAndOwner (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) GuildMember
    , invites :
        SeqDict.SeqDict
            (Evergreen.V417.SecretId.SecretId Evergreen.V417.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V417.Id.Id Evergreen.V417.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Thread.LastTypedAt (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId))
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V417.ChannelName.ChannelName
    , description : Evergreen.V417.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V417.MessageArray.MessageArray Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId)
    , visibleMessages : Evergreen.V417.VisibleMessages.VisibleMessages Evergreen.V417.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V417.Drawing.Drawing (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId))
    , permissionOverwrites : List Evergreen.V417.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V417.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V417.GuildName.GuildName
    , icon : Maybe Evergreen.V417.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V417.MembersAndOwner.MembersAndOwner
            (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V417.Discord.Id Evergreen.V417.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V417.Id.Id Evergreen.V417.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V417.Id.Id Evergreen.V417.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Thread.LastTypedAt (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId))
    }


type alias SlackFrontendChannel =
    { name : Evergreen.V417.ChannelName.ChannelName
    , isPrivate : Bool
    , messages : Evergreen.V417.MessageArray.MessageArray Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId)
    , visibleMessages : Evergreen.V417.VisibleMessages.VisibleMessages Evergreen.V417.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.Thread.SlackFrontendThread
    }


type alias SlackFrontendWorkspace =
    { name : String
    , icon : Maybe Evergreen.V417.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId) SlackFrontendChannel
    , customEmojis : SeqSet.SeqSet (Evergreen.V417.Id.Id Evergreen.V417.Id.CustomEmojiId)
    }


type alias SlackFrontendDmChannel =
    { teamId : Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId
    , members : Evergreen.V417.NonemptySet.NonemptySet (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId)
    , messages : Evergreen.V417.MessageArray.MessageArray Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId)
    , visibleMessages : Evergreen.V417.VisibleMessages.VisibleMessages Evergreen.V417.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.Thread.SlackFrontendThread
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V417.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V417.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V417.Id.Id Evergreen.V417.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V417.GuildName.GuildName
    , owner : Evergreen.V417.Id.Id Evergreen.V417.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V417.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V417.Message.Message Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId))
    , permissionOverwrites : List Evergreen.V417.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V417.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V417.MembersAndOwner.MembersAndOwner
            (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V417.Discord.Id Evergreen.V417.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V417.NonemptyDict.NonemptyDict
            (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V417.Message.Message Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V417.Discord.PartialUser
        , icon : Maybe Evergreen.V417.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V417.Discord.User
        , linkedTo : Evergreen.V417.Id.Id Evergreen.V417.Id.UserId
        , icon : Maybe Evergreen.V417.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V417.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V417.Discord.User
        , linkedTo : Evergreen.V417.Id.Id Evergreen.V417.Id.UserId
        , icon : Maybe Evergreen.V417.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_SlackWorkspace =
    { name : String
    , domain : String
    , channels :
        SeqDict.SeqDict
            (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId)
            { name : Evergreen.V417.ChannelName.ChannelName
            , isPrivate : Bool
            , linkedMembers : SeqSet.SeqSet (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId)
            , messageCount : Int
            , firstMessage : Maybe (Evergreen.V417.Message.Message Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId))
            }
    , linkedUsers :
        SeqDict.SeqDict
            (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId)
            { name : String
            , linkedTo : Evergreen.V417.Id.Id Evergreen.V417.Id.UserId
            }
    , userCount : Int
    }


type alias AdminData_SlackDmChannel =
    { teamId : Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId
    , members :
        List
            { id : Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId
            , name : String
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V417.Message.Message Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId))
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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
    { users : AdminDataStatus (Evergreen.V417.NonemptyDict.NonemptyDict (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Evergreen.V417.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , openRouterKey : Maybe String
    , notifyAdminsToken : Maybe String
    , notifyAdminsBotUserId : Maybe (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
    , postmarkKey : Evergreen.V417.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V417.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) AdminData_DiscordGuild)
    , slackWorkspaces : AdminDataStatus (SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) AdminData_SlackWorkspace)
    , slackDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.DmChannelId) AdminData_SlackDmChannel)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , slackLinkingEnabled : Bool
    , slackLinkLimit : Maybe Int
    , logs : Evergreen.V417.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V417.SessionIdHash.SessionIdHash, Evergreen.V417.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V417.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V417.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , orphanedFiles : AdminDataStatus (SeqDict.SeqDict Evergreen.V417.FileStatus.FileHash Evergreen.V417.FileStatus.BackendFileData)
    , deleteOrphanedFiles : DeleteOrphanedFilesStatus
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V417.SessionIdHash.SessionIdHash Evergreen.V417.UserSession.UserSession)
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
    , guilds : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Evergreen.V417.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId) Evergreen.V417.DmChannel.DiscordFrontendDmChannel
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) SlackFrontendWorkspace
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.DmChannelId) SlackFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V417.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V417.SessionIdHash.SessionIdHash Evergreen.V417.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V417.TextEditor.LocalState
    , calls : Evergreen.V417.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V417.Id.Id Evergreen.V417.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V417.Id.Id Evergreen.V417.Id.UserId
    , name : Evergreen.V417.ChannelName.ChannelName
    , description : Evergreen.V417.ChannelDescription.ChannelDescription
    , messages : Evergreen.V417.IdArray.IdArray Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Message.Message Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId))
    , status : ChannelStatus
    , threads : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V417.Drawing.Drawing (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V417.Id.Id Evergreen.V417.Id.UserId
    , name : Evergreen.V417.GuildName.GuildName
    , icon : Maybe Evergreen.V417.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId) BackendChannel
    , membersAndOwner : Evergreen.V417.MembersAndOwner.MembersAndOwner (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) GuildMember
    , bannedUsers : SeqSet.SeqSet (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
    , invites :
        SeqDict.SeqDict
            (Evergreen.V417.SecretId.SecretId Evergreen.V417.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V417.Id.Id Evergreen.V417.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Thread.LastTypedAt (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId))
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V417.ChannelName.ChannelName
    , description : Evergreen.V417.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V417.IdArray.IdArray Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Message.Message Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId))
    , status : ChannelStatus
    , linkedMessageIds : Evergreen.V417.OneToOne.OneToOne (Evergreen.V417.Discord.Id Evergreen.V417.Discord.MessageId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V417.Drawing.Drawing (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId))
    , permissionOverwrites : List Evergreen.V417.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V417.GuildName.GuildName
    , icon : Maybe Evergreen.V417.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V417.MembersAndOwner.MembersAndOwner
            (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V417.Discord.Id Evergreen.V417.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V417.Id.Id Evergreen.V417.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V417.Id.Id Evergreen.V417.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Thread.LastTypedAt (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId))
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId
    , messages : List Evergreen.V417.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V417.Discord.Message
    , threads : List DiscordThreadReload
    }
