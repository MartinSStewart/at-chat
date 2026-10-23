module Evergreen.V409.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V409.BackendMsgLog
import Evergreen.V409.Call
import Evergreen.V409.ChannelDescription
import Evergreen.V409.ChannelName
import Evergreen.V409.Discord
import Evergreen.V409.DiscordUserData
import Evergreen.V409.DmChannel
import Evergreen.V409.DmChannelId
import Evergreen.V409.Drawing
import Evergreen.V409.FileStatus
import Evergreen.V409.Game
import Evergreen.V409.GuildName
import Evergreen.V409.Id
import Evergreen.V409.IdArray
import Evergreen.V409.Log
import Evergreen.V409.MembersAndOwner
import Evergreen.V409.Message
import Evergreen.V409.MessageArray
import Evergreen.V409.NonemptyDict
import Evergreen.V409.NonemptySet
import Evergreen.V409.OneToOne
import Evergreen.V409.Pagination
import Evergreen.V409.Postmark
import Evergreen.V409.SecretId
import Evergreen.V409.SessionIdHash
import Evergreen.V409.Slack
import Evergreen.V409.TextEditor
import Evergreen.V409.Thread
import Evergreen.V409.ToBackendLog
import Evergreen.V409.User
import Evergreen.V409.UserSession
import Evergreen.V409.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V409.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V409.Log.Log
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V409.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V409.Call.RemoteCallData
    , currentlyViewing : Evergreen.V409.UserSession.Viewing
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
    , archivedBy : Evergreen.V409.Id.Id Evergreen.V409.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V409.Id.Id Evergreen.V409.Id.UserId
    , name : Evergreen.V409.ChannelName.ChannelName
    , description : Evergreen.V409.ChannelDescription.ChannelDescription
    , messages : Evergreen.V409.MessageArray.MessageArray Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId)
    , visibleMessages : Evergreen.V409.VisibleMessages.VisibleMessages Evergreen.V409.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , threads : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V409.Drawing.Drawing (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.Game.MatchData
    }


type alias GuildMember =
    { joinedAt : Effect.Time.Posix
    , lastPostedAt : Maybe Effect.Time.Posix
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V409.Id.Id Evergreen.V409.Id.UserId
    , name : Evergreen.V409.GuildName.GuildName
    , icon : Maybe Evergreen.V409.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId) FrontendChannel
    , membersAndOwner : Evergreen.V409.MembersAndOwner.MembersAndOwner (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) GuildMember
    , invites :
        SeqDict.SeqDict
            (Evergreen.V409.SecretId.SecretId Evergreen.V409.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V409.Id.Id Evergreen.V409.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Thread.LastTypedAt (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId))
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V409.ChannelName.ChannelName
    , description : Evergreen.V409.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V409.MessageArray.MessageArray Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId)
    , visibleMessages : Evergreen.V409.VisibleMessages.VisibleMessages Evergreen.V409.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V409.Drawing.Drawing (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId))
    , permissionOverwrites : List Evergreen.V409.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V409.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V409.GuildName.GuildName
    , icon : Maybe Evergreen.V409.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V409.MembersAndOwner.MembersAndOwner
            (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V409.Discord.Id Evergreen.V409.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V409.Id.Id Evergreen.V409.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V409.Id.Id Evergreen.V409.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Thread.LastTypedAt (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId))
    }


type alias SlackFrontendChannel =
    { name : Evergreen.V409.ChannelName.ChannelName
    , isPrivate : Bool
    , messages : Evergreen.V409.MessageArray.MessageArray Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId)
    , visibleMessages : Evergreen.V409.VisibleMessages.VisibleMessages Evergreen.V409.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.Thread.SlackFrontendThread
    }


type alias SlackFrontendWorkspace =
    { name : String
    , icon : Maybe Evergreen.V409.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId) SlackFrontendChannel
    , customEmojis : SeqSet.SeqSet (Evergreen.V409.Id.Id Evergreen.V409.Id.CustomEmojiId)
    }


type alias SlackFrontendDmChannel =
    { teamId : Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId
    , members : Evergreen.V409.NonemptySet.NonemptySet (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId)
    , messages : Evergreen.V409.MessageArray.MessageArray Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId)
    , visibleMessages : Evergreen.V409.VisibleMessages.VisibleMessages Evergreen.V409.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.Thread.SlackFrontendThread
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V409.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V409.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V409.Id.Id Evergreen.V409.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V409.GuildName.GuildName
    , owner : Evergreen.V409.Id.Id Evergreen.V409.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V409.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V409.Message.Message Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId))
    , permissionOverwrites : List Evergreen.V409.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V409.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V409.MembersAndOwner.MembersAndOwner
            (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V409.Discord.Id Evergreen.V409.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V409.NonemptyDict.NonemptyDict
            (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V409.Message.Message Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V409.Discord.PartialUser
        , icon : Maybe Evergreen.V409.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V409.Discord.User
        , linkedTo : Evergreen.V409.Id.Id Evergreen.V409.Id.UserId
        , icon : Maybe Evergreen.V409.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V409.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V409.Discord.User
        , linkedTo : Evergreen.V409.Id.Id Evergreen.V409.Id.UserId
        , icon : Maybe Evergreen.V409.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_SlackWorkspace =
    { name : String
    , domain : String
    , channels :
        SeqDict.SeqDict
            (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId)
            { name : Evergreen.V409.ChannelName.ChannelName
            , isPrivate : Bool
            , linkedMembers : SeqSet.SeqSet (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId)
            , messageCount : Int
            , firstMessage : Maybe (Evergreen.V409.Message.Message Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId))
            }
    , linkedUsers :
        SeqDict.SeqDict
            (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId)
            { name : String
            , linkedTo : Evergreen.V409.Id.Id Evergreen.V409.Id.UserId
            }
    , userCount : Int
    }


type alias AdminData_SlackDmChannel =
    { teamId : Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId
    , members :
        List
            { id : Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId
            , name : String
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V409.Message.Message Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId))
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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
    { users : AdminDataStatus (Evergreen.V409.NonemptyDict.NonemptyDict (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Evergreen.V409.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V409.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V409.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) AdminData_DiscordGuild)
    , slackWorkspaces : AdminDataStatus (SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) AdminData_SlackWorkspace)
    , slackDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.DmChannelId) AdminData_SlackDmChannel)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , slackLinkingEnabled : Bool
    , slackLinkLimit : Maybe Int
    , logs : Evergreen.V409.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V409.SessionIdHash.SessionIdHash, Evergreen.V409.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V409.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V409.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , orphanedFiles : AdminDataStatus (SeqDict.SeqDict Evergreen.V409.FileStatus.FileHash Evergreen.V409.FileStatus.BackendFileData)
    , deleteOrphanedFiles : DeleteOrphanedFilesStatus
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V409.SessionIdHash.SessionIdHash Evergreen.V409.UserSession.UserSession)
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
    , guilds : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Evergreen.V409.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId) Evergreen.V409.DmChannel.DiscordFrontendDmChannel
    , slackWorkspaces : SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) SlackFrontendWorkspace
    , slackDmChannels : SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.DmChannelId) SlackFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V409.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V409.SessionIdHash.SessionIdHash Evergreen.V409.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V409.TextEditor.LocalState
    , calls : Evergreen.V409.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V409.Id.Id Evergreen.V409.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V409.Id.Id Evergreen.V409.Id.UserId
    , name : Evergreen.V409.ChannelName.ChannelName
    , description : Evergreen.V409.ChannelDescription.ChannelDescription
    , messages : Evergreen.V409.IdArray.IdArray Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Message.Message Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId))
    , status : ChannelStatus
    , threads : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V409.Drawing.Drawing (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V409.Id.Id Evergreen.V409.Id.UserId
    , name : Evergreen.V409.GuildName.GuildName
    , icon : Maybe Evergreen.V409.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId) BackendChannel
    , membersAndOwner : Evergreen.V409.MembersAndOwner.MembersAndOwner (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) GuildMember
    , bannedUsers : SeqSet.SeqSet (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId)
    , invites :
        SeqDict.SeqDict
            (Evergreen.V409.SecretId.SecretId Evergreen.V409.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V409.Id.Id Evergreen.V409.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Thread.LastTypedAt (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId))
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V409.ChannelName.ChannelName
    , description : Evergreen.V409.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V409.IdArray.IdArray Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Message.Message Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId))
    , status : ChannelStatus
    , linkedMessageIds : Evergreen.V409.OneToOne.OneToOne (Evergreen.V409.Discord.Id Evergreen.V409.Discord.MessageId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V409.Drawing.Drawing (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId))
    , permissionOverwrites : List Evergreen.V409.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V409.GuildName.GuildName
    , icon : Maybe Evergreen.V409.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V409.MembersAndOwner.MembersAndOwner
            (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V409.Discord.Id Evergreen.V409.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V409.Id.Id Evergreen.V409.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V409.Id.Id Evergreen.V409.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Thread.LastTypedAt (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId))
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId
    , messages : List Evergreen.V409.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V409.Discord.Message
    , threads : List DiscordThreadReload
    }
