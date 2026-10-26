module Evergreen.V413.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V413.BackendMsgLog
import Evergreen.V413.Call
import Evergreen.V413.ChannelDescription
import Evergreen.V413.ChannelName
import Evergreen.V413.Discord
import Evergreen.V413.DiscordUserData
import Evergreen.V413.DmChannel
import Evergreen.V413.DmChannelId
import Evergreen.V413.Drawing
import Evergreen.V413.FileStatus
import Evergreen.V413.Game
import Evergreen.V413.GuildName
import Evergreen.V413.Id
import Evergreen.V413.IdArray
import Evergreen.V413.Log
import Evergreen.V413.MembersAndOwner
import Evergreen.V413.Message
import Evergreen.V413.MessageArray
import Evergreen.V413.NonemptyDict
import Evergreen.V413.NonemptySet
import Evergreen.V413.OneToOne
import Evergreen.V413.Pagination
import Evergreen.V413.Postmark
import Evergreen.V413.SecretId
import Evergreen.V413.SessionIdHash
import Evergreen.V413.Slack
import Evergreen.V413.TextEditor
import Evergreen.V413.Thread
import Evergreen.V413.ToBackendLog
import Evergreen.V413.User
import Evergreen.V413.UserSession
import Evergreen.V413.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V413.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V413.Log.Log
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V413.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V413.Call.RemoteCallData
    , currentlyViewing : Evergreen.V413.UserSession.Viewing
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
    , archivedBy : Evergreen.V413.Id.Id Evergreen.V413.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V413.Id.Id Evergreen.V413.Id.UserId
    , name : Evergreen.V413.ChannelName.ChannelName
    , description : Evergreen.V413.ChannelDescription.ChannelDescription
    , messages : Evergreen.V413.MessageArray.MessageArray Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId)
    , visibleMessages : Evergreen.V413.VisibleMessages.VisibleMessages Evergreen.V413.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , threads : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V413.Drawing.Drawing (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.Game.MatchData
    }


type alias GuildMember =
    { joinedAt : Effect.Time.Posix
    , lastPostedAt : Maybe Effect.Time.Posix
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V413.Id.Id Evergreen.V413.Id.UserId
    , name : Evergreen.V413.GuildName.GuildName
    , icon : Maybe Evergreen.V413.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId) FrontendChannel
    , membersAndOwner : Evergreen.V413.MembersAndOwner.MembersAndOwner (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) GuildMember
    , invites :
        SeqDict.SeqDict
            (Evergreen.V413.SecretId.SecretId Evergreen.V413.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V413.Id.Id Evergreen.V413.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Thread.LastTypedAt (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId))
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V413.ChannelName.ChannelName
    , description : Evergreen.V413.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V413.MessageArray.MessageArray Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId)
    , visibleMessages : Evergreen.V413.VisibleMessages.VisibleMessages Evergreen.V413.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V413.Drawing.Drawing (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId))
    , permissionOverwrites : List Evergreen.V413.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V413.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V413.GuildName.GuildName
    , icon : Maybe Evergreen.V413.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V413.MembersAndOwner.MembersAndOwner
            (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V413.Discord.Id Evergreen.V413.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V413.Id.Id Evergreen.V413.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V413.Id.Id Evergreen.V413.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Thread.LastTypedAt (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId))
    }


type alias SlackFrontendChannel =
    { name : Evergreen.V413.ChannelName.ChannelName
    , isPrivate : Bool
    , messages : Evergreen.V413.MessageArray.MessageArray Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId)
    , visibleMessages : Evergreen.V413.VisibleMessages.VisibleMessages Evergreen.V413.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.Thread.SlackFrontendThread
    }


type alias SlackFrontendWorkspace =
    { name : String
    , icon : Maybe Evergreen.V413.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId) SlackFrontendChannel
    , customEmojis : SeqSet.SeqSet (Evergreen.V413.Id.Id Evergreen.V413.Id.CustomEmojiId)
    }


type alias SlackFrontendDmChannel =
    { teamId : Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId
    , members : Evergreen.V413.NonemptySet.NonemptySet (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId)
    , messages : Evergreen.V413.MessageArray.MessageArray Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId)
    , visibleMessages : Evergreen.V413.VisibleMessages.VisibleMessages Evergreen.V413.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.Thread.SlackFrontendThread
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V413.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V413.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V413.Id.Id Evergreen.V413.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V413.GuildName.GuildName
    , owner : Evergreen.V413.Id.Id Evergreen.V413.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V413.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V413.Message.Message Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId))
    , permissionOverwrites : List Evergreen.V413.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V413.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V413.MembersAndOwner.MembersAndOwner
            (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V413.Discord.Id Evergreen.V413.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V413.NonemptyDict.NonemptyDict
            (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V413.Message.Message Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V413.Discord.PartialUser
        , icon : Maybe Evergreen.V413.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V413.Discord.User
        , linkedTo : Evergreen.V413.Id.Id Evergreen.V413.Id.UserId
        , icon : Maybe Evergreen.V413.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V413.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V413.Discord.User
        , linkedTo : Evergreen.V413.Id.Id Evergreen.V413.Id.UserId
        , icon : Maybe Evergreen.V413.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_SlackWorkspace =
    { name : String
    , domain : String
    , channels :
        SeqDict.SeqDict
            (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId)
            { name : Evergreen.V413.ChannelName.ChannelName
            , isPrivate : Bool
            , linkedMembers : SeqSet.SeqSet (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId)
            , messageCount : Int
            , firstMessage : Maybe (Evergreen.V413.Message.Message Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId))
            }
    , linkedUsers :
        SeqDict.SeqDict
            (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId)
            { name : String
            , linkedTo : Evergreen.V413.Id.Id Evergreen.V413.Id.UserId
            }
    , userCount : Int
    }


type alias AdminData_SlackDmChannel =
    { teamId : Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId
    , members :
        List
            { id : Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId
            , name : String
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V413.Message.Message Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId))
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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
    { users : AdminDataStatus (Evergreen.V413.NonemptyDict.NonemptyDict (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Evergreen.V413.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , openRouterKey : Maybe String
    , notifyAdminsToken : Maybe String
    , notifyAdminsBotUserId : Maybe (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId)
    , postmarkKey : Evergreen.V413.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V413.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) AdminData_DiscordGuild)
    , slackWorkspaces : AdminDataStatus (SeqDict.SeqDict (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId) AdminData_SlackWorkspace)
    , slackDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V413.Slack.Id Evergreen.V413.Slack.DmChannelId) AdminData_SlackDmChannel)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , slackLinkingEnabled : Bool
    , slackLinkLimit : Maybe Int
    , logs : Evergreen.V413.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V413.SessionIdHash.SessionIdHash, Evergreen.V413.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V413.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V413.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , orphanedFiles : AdminDataStatus (SeqDict.SeqDict Evergreen.V413.FileStatus.FileHash Evergreen.V413.FileStatus.BackendFileData)
    , deleteOrphanedFiles : DeleteOrphanedFilesStatus
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V413.SessionIdHash.SessionIdHash Evergreen.V413.UserSession.UserSession)
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
    , guilds : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Evergreen.V413.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId) Evergreen.V413.DmChannel.DiscordFrontendDmChannel
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId) SlackFrontendWorkspace
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V413.Slack.Id Evergreen.V413.Slack.DmChannelId) SlackFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V413.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V413.SessionIdHash.SessionIdHash Evergreen.V413.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V413.TextEditor.LocalState
    , calls : Evergreen.V413.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V413.Id.Id Evergreen.V413.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V413.Id.Id Evergreen.V413.Id.UserId
    , name : Evergreen.V413.ChannelName.ChannelName
    , description : Evergreen.V413.ChannelDescription.ChannelDescription
    , messages : Evergreen.V413.IdArray.IdArray Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Message.Message Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId))
    , status : ChannelStatus
    , threads : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V413.Drawing.Drawing (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V413.Id.Id Evergreen.V413.Id.UserId
    , name : Evergreen.V413.GuildName.GuildName
    , icon : Maybe Evergreen.V413.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId) BackendChannel
    , membersAndOwner : Evergreen.V413.MembersAndOwner.MembersAndOwner (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) GuildMember
    , bannedUsers : SeqSet.SeqSet (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId)
    , invites :
        SeqDict.SeqDict
            (Evergreen.V413.SecretId.SecretId Evergreen.V413.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V413.Id.Id Evergreen.V413.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Thread.LastTypedAt (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId))
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V413.ChannelName.ChannelName
    , description : Evergreen.V413.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V413.IdArray.IdArray Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Message.Message Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId))
    , status : ChannelStatus
    , linkedMessageIds : Evergreen.V413.OneToOne.OneToOne (Evergreen.V413.Discord.Id Evergreen.V413.Discord.MessageId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V413.Drawing.Drawing (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId))
    , permissionOverwrites : List Evergreen.V413.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V413.GuildName.GuildName
    , icon : Maybe Evergreen.V413.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V413.MembersAndOwner.MembersAndOwner
            (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V413.Discord.Id Evergreen.V413.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V413.Id.Id Evergreen.V413.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V413.Id.Id Evergreen.V413.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Thread.LastTypedAt (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId))
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId
    , messages : List Evergreen.V413.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V413.Discord.Message
    , threads : List DiscordThreadReload
    }
