module Evergreen.V419.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V419.BackendMsgLog
import Evergreen.V419.Call
import Evergreen.V419.ChannelDescription
import Evergreen.V419.ChannelName
import Evergreen.V419.Discord
import Evergreen.V419.DiscordUserData
import Evergreen.V419.DmChannel
import Evergreen.V419.DmChannelId
import Evergreen.V419.Drawing
import Evergreen.V419.FileStatus
import Evergreen.V419.Game
import Evergreen.V419.GuildName
import Evergreen.V419.Id
import Evergreen.V419.IdArray
import Evergreen.V419.Log
import Evergreen.V419.MembersAndOwner
import Evergreen.V419.Message
import Evergreen.V419.MessageArray
import Evergreen.V419.NonemptyDict
import Evergreen.V419.NonemptySet
import Evergreen.V419.OneToOne
import Evergreen.V419.Pagination
import Evergreen.V419.Postmark
import Evergreen.V419.SecretId
import Evergreen.V419.SessionIdHash
import Evergreen.V419.Slack
import Evergreen.V419.TextEditor
import Evergreen.V419.Thread
import Evergreen.V419.ToBackendLog
import Evergreen.V419.User
import Evergreen.V419.UserSession
import Evergreen.V419.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V419.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V419.Log.Log
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V419.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V419.Call.RemoteCallData
    , currentlyViewing : Evergreen.V419.UserSession.Viewing
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
    , archivedBy : Evergreen.V419.Id.Id Evergreen.V419.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V419.Id.Id Evergreen.V419.Id.UserId
    , name : Evergreen.V419.ChannelName.ChannelName
    , description : Evergreen.V419.ChannelDescription.ChannelDescription
    , messages : Evergreen.V419.MessageArray.MessageArray Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId)
    , visibleMessages : Evergreen.V419.VisibleMessages.VisibleMessages Evergreen.V419.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , threads : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V419.Drawing.Drawing (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.Game.MatchData
    }


type alias GuildMember =
    { joinedAt : Effect.Time.Posix
    , lastPostedAt : Maybe Effect.Time.Posix
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V419.Id.Id Evergreen.V419.Id.UserId
    , name : Evergreen.V419.GuildName.GuildName
    , icon : Maybe Evergreen.V419.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId) FrontendChannel
    , membersAndOwner : Evergreen.V419.MembersAndOwner.MembersAndOwner (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) GuildMember
    , invites :
        SeqDict.SeqDict
            (Evergreen.V419.SecretId.SecretId Evergreen.V419.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V419.Id.Id Evergreen.V419.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Thread.LastTypedAt (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId))
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V419.ChannelName.ChannelName
    , description : Evergreen.V419.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V419.MessageArray.MessageArray Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId)
    , visibleMessages : Evergreen.V419.VisibleMessages.VisibleMessages Evergreen.V419.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V419.Drawing.Drawing (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId))
    , permissionOverwrites : List Evergreen.V419.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V419.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V419.GuildName.GuildName
    , icon : Maybe Evergreen.V419.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V419.MembersAndOwner.MembersAndOwner
            (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V419.Discord.Id Evergreen.V419.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V419.Id.Id Evergreen.V419.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V419.Id.Id Evergreen.V419.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Thread.LastTypedAt (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId))
    }


type alias SlackFrontendChannel =
    { name : Evergreen.V419.ChannelName.ChannelName
    , isPrivate : Bool
    , messages : Evergreen.V419.MessageArray.MessageArray Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId)
    , visibleMessages : Evergreen.V419.VisibleMessages.VisibleMessages Evergreen.V419.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.Thread.SlackFrontendThread
    }


type alias SlackFrontendWorkspace =
    { name : String
    , icon : Maybe Evergreen.V419.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId) SlackFrontendChannel
    , customEmojis : SeqSet.SeqSet (Evergreen.V419.Id.Id Evergreen.V419.Id.CustomEmojiId)
    }


type alias SlackFrontendDmChannel =
    { teamId : Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId
    , members : Evergreen.V419.NonemptySet.NonemptySet (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId)
    , messages : Evergreen.V419.MessageArray.MessageArray Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId)
    , visibleMessages : Evergreen.V419.VisibleMessages.VisibleMessages Evergreen.V419.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.Thread.SlackFrontendThread
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V419.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V419.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V419.Id.Id Evergreen.V419.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V419.GuildName.GuildName
    , owner : Evergreen.V419.Id.Id Evergreen.V419.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V419.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V419.Message.Message Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId))
    , permissionOverwrites : List Evergreen.V419.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V419.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V419.MembersAndOwner.MembersAndOwner
            (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V419.Discord.Id Evergreen.V419.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V419.NonemptyDict.NonemptyDict
            (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V419.Message.Message Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V419.Discord.PartialUser
        , icon : Maybe Evergreen.V419.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V419.Discord.User
        , linkedTo : Evergreen.V419.Id.Id Evergreen.V419.Id.UserId
        , icon : Maybe Evergreen.V419.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V419.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V419.Discord.User
        , linkedTo : Evergreen.V419.Id.Id Evergreen.V419.Id.UserId
        , icon : Maybe Evergreen.V419.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_SlackWorkspace =
    { name : String
    , domain : String
    , channels :
        SeqDict.SeqDict
            (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId)
            { name : Evergreen.V419.ChannelName.ChannelName
            , isPrivate : Bool
            , linkedMembers : SeqSet.SeqSet (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId)
            , messageCount : Int
            , firstMessage : Maybe (Evergreen.V419.Message.Message Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId))
            }
    , linkedUsers :
        SeqDict.SeqDict
            (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId)
            { name : String
            , linkedTo : Evergreen.V419.Id.Id Evergreen.V419.Id.UserId
            }
    , userCount : Int
    }


type alias AdminData_SlackDmChannel =
    { teamId : Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId
    , members :
        List
            { id : Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId
            , name : String
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V419.Message.Message Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId))
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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
    { users : AdminDataStatus (Evergreen.V419.NonemptyDict.NonemptyDict (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Evergreen.V419.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , openRouterKey : Maybe String
    , notifyAdminsToken : Maybe String
    , notifyAdminsBotUserId : Maybe (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId)
    , postmarkKey : Evergreen.V419.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V419.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) AdminData_DiscordGuild)
    , slackWorkspaces : AdminDataStatus (SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) AdminData_SlackWorkspace)
    , slackDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.DmChannelId) AdminData_SlackDmChannel)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , slackLinkingEnabled : Bool
    , slackLinkLimit : Maybe Int
    , logs : Evergreen.V419.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V419.SessionIdHash.SessionIdHash, Evergreen.V419.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V419.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V419.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , orphanedFiles : AdminDataStatus (SeqDict.SeqDict Evergreen.V419.FileStatus.FileHash Evergreen.V419.FileStatus.BackendFileData)
    , deleteOrphanedFiles : DeleteOrphanedFilesStatus
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V419.SessionIdHash.SessionIdHash Evergreen.V419.UserSession.UserSession)
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
    , guilds : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Evergreen.V419.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId) Evergreen.V419.DmChannel.DiscordFrontendDmChannel
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) SlackFrontendWorkspace
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.DmChannelId) SlackFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V419.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V419.SessionIdHash.SessionIdHash Evergreen.V419.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V419.TextEditor.LocalState
    , calls : Evergreen.V419.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V419.Id.Id Evergreen.V419.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V419.Id.Id Evergreen.V419.Id.UserId
    , name : Evergreen.V419.ChannelName.ChannelName
    , description : Evergreen.V419.ChannelDescription.ChannelDescription
    , messages : Evergreen.V419.IdArray.IdArray Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Message.Message Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId))
    , status : ChannelStatus
    , threads : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V419.Drawing.Drawing (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V419.Id.Id Evergreen.V419.Id.UserId
    , name : Evergreen.V419.GuildName.GuildName
    , icon : Maybe Evergreen.V419.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId) BackendChannel
    , membersAndOwner : Evergreen.V419.MembersAndOwner.MembersAndOwner (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) GuildMember
    , bannedUsers : SeqSet.SeqSet (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId)
    , invites :
        SeqDict.SeqDict
            (Evergreen.V419.SecretId.SecretId Evergreen.V419.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V419.Id.Id Evergreen.V419.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Thread.LastTypedAt (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId))
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V419.ChannelName.ChannelName
    , description : Evergreen.V419.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V419.IdArray.IdArray Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Message.Message Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId))
    , status : ChannelStatus
    , linkedMessageIds : Evergreen.V419.OneToOne.OneToOne (Evergreen.V419.Discord.Id Evergreen.V419.Discord.MessageId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V419.Drawing.Drawing (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId))
    , permissionOverwrites : List Evergreen.V419.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V419.GuildName.GuildName
    , icon : Maybe Evergreen.V419.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V419.MembersAndOwner.MembersAndOwner
            (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V419.Discord.Id Evergreen.V419.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V419.Id.Id Evergreen.V419.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V419.Id.Id Evergreen.V419.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Thread.LastTypedAt (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId))
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId
    , messages : List Evergreen.V419.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V419.Discord.Message
    , threads : List DiscordThreadReload
    }
