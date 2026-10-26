module Evergreen.V414.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V414.BackendMsgLog
import Evergreen.V414.Call
import Evergreen.V414.ChannelDescription
import Evergreen.V414.ChannelName
import Evergreen.V414.Discord
import Evergreen.V414.DiscordUserData
import Evergreen.V414.DmChannel
import Evergreen.V414.DmChannelId
import Evergreen.V414.Drawing
import Evergreen.V414.FileStatus
import Evergreen.V414.Game
import Evergreen.V414.GuildName
import Evergreen.V414.Id
import Evergreen.V414.IdArray
import Evergreen.V414.Log
import Evergreen.V414.MembersAndOwner
import Evergreen.V414.Message
import Evergreen.V414.MessageArray
import Evergreen.V414.NonemptyDict
import Evergreen.V414.NonemptySet
import Evergreen.V414.OneToOne
import Evergreen.V414.Pagination
import Evergreen.V414.Postmark
import Evergreen.V414.SecretId
import Evergreen.V414.SessionIdHash
import Evergreen.V414.Slack
import Evergreen.V414.TextEditor
import Evergreen.V414.Thread
import Evergreen.V414.ToBackendLog
import Evergreen.V414.User
import Evergreen.V414.UserSession
import Evergreen.V414.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V414.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V414.Discord.Id Evergreen.V414.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V414.Log.Log
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V414.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V414.Call.RemoteCallData
    , currentlyViewing : Evergreen.V414.UserSession.Viewing
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
    , archivedBy : Evergreen.V414.Id.Id Evergreen.V414.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V414.Id.Id Evergreen.V414.Id.UserId
    , name : Evergreen.V414.ChannelName.ChannelName
    , description : Evergreen.V414.ChannelDescription.ChannelDescription
    , messages : Evergreen.V414.MessageArray.MessageArray Evergreen.V414.Id.ChannelMessageId (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId) (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelId)
    , visibleMessages : Evergreen.V414.VisibleMessages.VisibleMessages Evergreen.V414.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , threads : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId) Evergreen.V414.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V414.Drawing.Drawing (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId) Evergreen.V414.Game.MatchData
    }


type alias GuildMember =
    { joinedAt : Effect.Time.Posix
    , lastPostedAt : Maybe Effect.Time.Posix
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V414.Id.Id Evergreen.V414.Id.UserId
    , name : Evergreen.V414.GuildName.GuildName
    , icon : Maybe Evergreen.V414.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelId) FrontendChannel
    , membersAndOwner : Evergreen.V414.MembersAndOwner.MembersAndOwner (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId) GuildMember
    , invites :
        SeqDict.SeqDict
            (Evergreen.V414.SecretId.SecretId Evergreen.V414.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V414.Id.Id Evergreen.V414.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId) (Evergreen.V414.Thread.LastTypedAt (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelId))
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V414.ChannelName.ChannelName
    , description : Evergreen.V414.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V414.MessageArray.MessageArray Evergreen.V414.Id.ChannelMessageId (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId)
    , visibleMessages : Evergreen.V414.VisibleMessages.VisibleMessages Evergreen.V414.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId) Evergreen.V414.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V414.Drawing.Drawing (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId))
    , permissionOverwrites : List Evergreen.V414.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V414.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V414.GuildName.GuildName
    , icon : Maybe Evergreen.V414.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V414.MembersAndOwner.MembersAndOwner
            (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V414.Discord.Id Evergreen.V414.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V414.Id.Id Evergreen.V414.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V414.Id.Id Evergreen.V414.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V414.Discord.Id Evergreen.V414.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) (Evergreen.V414.Thread.LastTypedAt (Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId))
    }


type alias SlackFrontendChannel =
    { name : Evergreen.V414.ChannelName.ChannelName
    , isPrivate : Bool
    , messages : Evergreen.V414.MessageArray.MessageArray Evergreen.V414.Id.ChannelMessageId (Evergreen.V414.Slack.Id Evergreen.V414.Slack.UserId) (Evergreen.V414.Slack.Id Evergreen.V414.Slack.ChannelId)
    , visibleMessages : Evergreen.V414.VisibleMessages.VisibleMessages Evergreen.V414.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId) Evergreen.V414.Thread.SlackFrontendThread
    }


type alias SlackFrontendWorkspace =
    { name : String
    , icon : Maybe Evergreen.V414.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V414.Slack.Id Evergreen.V414.Slack.ChannelId) SlackFrontendChannel
    , customEmojis : SeqSet.SeqSet (Evergreen.V414.Id.Id Evergreen.V414.Id.CustomEmojiId)
    }


type alias SlackFrontendDmChannel =
    { teamId : Evergreen.V414.Slack.Id Evergreen.V414.Slack.TeamId
    , members : Evergreen.V414.NonemptySet.NonemptySet (Evergreen.V414.Slack.Id Evergreen.V414.Slack.UserId)
    , messages : Evergreen.V414.MessageArray.MessageArray Evergreen.V414.Id.ChannelMessageId (Evergreen.V414.Slack.Id Evergreen.V414.Slack.UserId) (Evergreen.V414.Slack.Id Evergreen.V414.Slack.ChannelId)
    , visibleMessages : Evergreen.V414.VisibleMessages.VisibleMessages Evergreen.V414.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId) Evergreen.V414.Thread.SlackFrontendThread
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V414.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V414.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V414.Id.Id Evergreen.V414.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V414.GuildName.GuildName
    , owner : Evergreen.V414.Id.Id Evergreen.V414.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V414.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V414.Message.Message Evergreen.V414.Id.ChannelMessageId (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId))
    , permissionOverwrites : List Evergreen.V414.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V414.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V414.MembersAndOwner.MembersAndOwner
            (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V414.Discord.Id Evergreen.V414.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V414.Discord.Id Evergreen.V414.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V414.NonemptyDict.NonemptyDict
            (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V414.Message.Message Evergreen.V414.Id.ChannelMessageId (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V414.Discord.PartialUser
        , icon : Maybe Evergreen.V414.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V414.Discord.User
        , linkedTo : Evergreen.V414.Id.Id Evergreen.V414.Id.UserId
        , icon : Maybe Evergreen.V414.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V414.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V414.Discord.User
        , linkedTo : Evergreen.V414.Id.Id Evergreen.V414.Id.UserId
        , icon : Maybe Evergreen.V414.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_SlackWorkspace =
    { name : String
    , domain : String
    , channels :
        SeqDict.SeqDict
            (Evergreen.V414.Slack.Id Evergreen.V414.Slack.ChannelId)
            { name : Evergreen.V414.ChannelName.ChannelName
            , isPrivate : Bool
            , linkedMembers : SeqSet.SeqSet (Evergreen.V414.Slack.Id Evergreen.V414.Slack.UserId)
            , messageCount : Int
            , firstMessage : Maybe (Evergreen.V414.Message.Message Evergreen.V414.Id.ChannelMessageId (Evergreen.V414.Slack.Id Evergreen.V414.Slack.UserId) (Evergreen.V414.Slack.Id Evergreen.V414.Slack.ChannelId))
            }
    , linkedUsers :
        SeqDict.SeqDict
            (Evergreen.V414.Slack.Id Evergreen.V414.Slack.UserId)
            { name : String
            , linkedTo : Evergreen.V414.Id.Id Evergreen.V414.Id.UserId
            }
    , userCount : Int
    }


type alias AdminData_SlackDmChannel =
    { teamId : Evergreen.V414.Slack.Id Evergreen.V414.Slack.TeamId
    , members :
        List
            { id : Evergreen.V414.Slack.Id Evergreen.V414.Slack.UserId
            , name : String
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V414.Message.Message Evergreen.V414.Id.ChannelMessageId (Evergreen.V414.Slack.Id Evergreen.V414.Slack.UserId) (Evergreen.V414.Slack.Id Evergreen.V414.Slack.ChannelId))
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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
    { users : AdminDataStatus (Evergreen.V414.NonemptyDict.NonemptyDict (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId) Evergreen.V414.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , openRouterKey : Maybe String
    , notifyAdminsToken : Maybe String
    , notifyAdminsBotUserId : Maybe (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId)
    , postmarkKey : Evergreen.V414.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V414.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V414.Discord.Id Evergreen.V414.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId) AdminData_DiscordGuild)
    , slackWorkspaces : AdminDataStatus (SeqDict.SeqDict (Evergreen.V414.Slack.Id Evergreen.V414.Slack.TeamId) AdminData_SlackWorkspace)
    , slackDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V414.Slack.Id Evergreen.V414.Slack.DmChannelId) AdminData_SlackDmChannel)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , slackLinkingEnabled : Bool
    , slackLinkLimit : Maybe Int
    , logs : Evergreen.V414.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V414.SessionIdHash.SessionIdHash, Evergreen.V414.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V414.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V414.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , orphanedFiles : AdminDataStatus (SeqDict.SeqDict Evergreen.V414.FileStatus.FileHash Evergreen.V414.FileStatus.BackendFileData)
    , deleteOrphanedFiles : DeleteOrphanedFilesStatus
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V414.SessionIdHash.SessionIdHash Evergreen.V414.UserSession.UserSession)
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
    , guilds : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId) Evergreen.V414.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V414.Discord.Id Evergreen.V414.Discord.PrivateChannelId) Evergreen.V414.DmChannel.DiscordFrontendDmChannel
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V414.Slack.Id Evergreen.V414.Slack.TeamId) SlackFrontendWorkspace
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V414.Slack.Id Evergreen.V414.Slack.DmChannelId) SlackFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V414.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V414.SessionIdHash.SessionIdHash Evergreen.V414.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V414.TextEditor.LocalState
    , calls : Evergreen.V414.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V414.Id.Id Evergreen.V414.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V414.Id.Id Evergreen.V414.Id.UserId
    , name : Evergreen.V414.ChannelName.ChannelName
    , description : Evergreen.V414.ChannelDescription.ChannelDescription
    , messages : Evergreen.V414.IdArray.IdArray Evergreen.V414.Id.ChannelMessageId (Evergreen.V414.Message.Message Evergreen.V414.Id.ChannelMessageId (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId) (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelId))
    , status : ChannelStatus
    , threads : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId) Evergreen.V414.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V414.Drawing.Drawing (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId) Evergreen.V414.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V414.Id.Id Evergreen.V414.Id.UserId
    , name : Evergreen.V414.GuildName.GuildName
    , icon : Maybe Evergreen.V414.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelId) BackendChannel
    , membersAndOwner : Evergreen.V414.MembersAndOwner.MembersAndOwner (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId) GuildMember
    , bannedUsers : SeqSet.SeqSet (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId)
    , invites :
        SeqDict.SeqDict
            (Evergreen.V414.SecretId.SecretId Evergreen.V414.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V414.Id.Id Evergreen.V414.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId) (Evergreen.V414.Thread.LastTypedAt (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelId))
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V414.ChannelName.ChannelName
    , description : Evergreen.V414.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V414.IdArray.IdArray Evergreen.V414.Id.ChannelMessageId (Evergreen.V414.Message.Message Evergreen.V414.Id.ChannelMessageId (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId))
    , status : ChannelStatus
    , linkedMessageIds : Evergreen.V414.OneToOne.OneToOne (Evergreen.V414.Discord.Id Evergreen.V414.Discord.MessageId) (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId) Evergreen.V414.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V414.Drawing.Drawing (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId))
    , permissionOverwrites : List Evergreen.V414.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V414.GuildName.GuildName
    , icon : Maybe Evergreen.V414.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V414.MembersAndOwner.MembersAndOwner
            (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V414.Discord.Id Evergreen.V414.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V414.Id.Id Evergreen.V414.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V414.Id.Id Evergreen.V414.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V414.Discord.Id Evergreen.V414.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) (Evergreen.V414.Thread.LastTypedAt (Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId))
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId
    , messages : List Evergreen.V414.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V414.Discord.Message
    , threads : List DiscordThreadReload
    }
