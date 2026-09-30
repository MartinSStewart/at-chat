module Evergreen.V395.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V395.BackendMsgLog
import Evergreen.V395.Call
import Evergreen.V395.ChannelDescription
import Evergreen.V395.ChannelName
import Evergreen.V395.Discord
import Evergreen.V395.DiscordUserData
import Evergreen.V395.DmChannel
import Evergreen.V395.DmChannelId
import Evergreen.V395.Drawing
import Evergreen.V395.FileStatus
import Evergreen.V395.Game
import Evergreen.V395.GuildName
import Evergreen.V395.Id
import Evergreen.V395.IdArray
import Evergreen.V395.Log
import Evergreen.V395.MembersAndOwner
import Evergreen.V395.Message
import Evergreen.V395.MessageArray
import Evergreen.V395.NonemptyDict
import Evergreen.V395.OneToOne
import Evergreen.V395.Pagination
import Evergreen.V395.Postmark
import Evergreen.V395.SecretId
import Evergreen.V395.SessionIdHash
import Evergreen.V395.Slack
import Evergreen.V395.TextEditor
import Evergreen.V395.Thread
import Evergreen.V395.ToBackendLog
import Evergreen.V395.User
import Evergreen.V395.UserSession
import Evergreen.V395.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V395.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V395.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V395.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V395.Call.RemoteCallData
    , currentlyViewing : Evergreen.V395.UserSession.Viewing
    }


type BackupContents
    = FullBackup
    | SubsetBackup


type alias LastBackup =
    { createdAt : Effect.Time.Posix
    , contents : BackupContents
    }


type AdminData_InvalidChannelNameGuild
    = InvalidChannelName_Guild Evergreen.V395.GuildName.GuildName
    | InvalidChannelName_DeletedGuild Evergreen.V395.GuildName.GuildName
    | InvalidChannelName_DiscordGuild Evergreen.V395.GuildName.GuildName


type alias AdminData_InvalidChannelName =
    { guild : AdminData_InvalidChannelNameGuild
    , channelName : Evergreen.V395.ChannelName.ChannelName
    , error : String
    }


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V395.Id.Id Evergreen.V395.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V395.Id.Id Evergreen.V395.Id.UserId
    , name : Evergreen.V395.ChannelName.ChannelName
    , description : Evergreen.V395.ChannelDescription.ChannelDescription
    , messages : Evergreen.V395.MessageArray.MessageArray Evergreen.V395.Id.ChannelMessageId (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId)
    , visibleMessages : Evergreen.V395.VisibleMessages.VisibleMessages Evergreen.V395.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Thread.LastTypedAt Evergreen.V395.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) Evergreen.V395.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V395.Drawing.Drawing (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) Evergreen.V395.Game.MatchData
    }


type alias GuildMember =
    { joinedAt : Effect.Time.Posix
    , lastPostedAt : Maybe Effect.Time.Posix
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V395.Id.Id Evergreen.V395.Id.UserId
    , name : Evergreen.V395.GuildName.GuildName
    , icon : Maybe Evergreen.V395.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId) FrontendChannel
    , membersAndOwner : Evergreen.V395.MembersAndOwner.MembersAndOwner (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) GuildMember
    , invites :
        SeqDict.SeqDict
            (Evergreen.V395.SecretId.SecretId Evergreen.V395.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V395.Id.Id Evergreen.V395.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V395.ChannelName.ChannelName
    , description : Evergreen.V395.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V395.MessageArray.MessageArray Evergreen.V395.Id.ChannelMessageId (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId)
    , visibleMessages : Evergreen.V395.VisibleMessages.VisibleMessages Evergreen.V395.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Thread.LastTypedAt Evergreen.V395.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) Evergreen.V395.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V395.Drawing.Drawing (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId))
    , permissionOverwrites : List Evergreen.V395.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V395.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V395.GuildName.GuildName
    , icon : Maybe Evergreen.V395.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V395.MembersAndOwner.MembersAndOwner
            (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V395.Discord.Id Evergreen.V395.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V395.Id.Id Evergreen.V395.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V395.Id.Id Evergreen.V395.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V395.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V395.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V395.Id.Id Evergreen.V395.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V395.GuildName.GuildName
    , owner : Evergreen.V395.Id.Id Evergreen.V395.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V395.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V395.Message.Message Evergreen.V395.Id.ChannelMessageId (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId))
    , permissionOverwrites : List Evergreen.V395.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V395.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V395.MembersAndOwner.MembersAndOwner
            (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V395.Discord.Id Evergreen.V395.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V395.NonemptyDict.NonemptyDict
            (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V395.Message.Message Evergreen.V395.Id.ChannelMessageId (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V395.Discord.PartialUser
        , icon : Maybe Evergreen.V395.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V395.Discord.User
        , linkedTo : Evergreen.V395.Id.Id Evergreen.V395.Id.UserId
        , icon : Maybe Evergreen.V395.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V395.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V395.Discord.User
        , linkedTo : Evergreen.V395.Id.Id Evergreen.V395.Id.UserId
        , icon : Maybe Evergreen.V395.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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
    { users : AdminDataStatus (Evergreen.V395.NonemptyDict.NonemptyDict (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Evergreen.V395.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V395.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V395.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V395.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) AdminData_DiscordGuild)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , logs : Evergreen.V395.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V395.SessionIdHash.SessionIdHash, Evergreen.V395.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V395.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V395.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , invalidChannelNames : List AdminData_InvalidChannelName
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , orphanedFiles : AdminDataStatus (SeqDict.SeqDict Evergreen.V395.FileStatus.FileHash Evergreen.V395.FileStatus.BackendFileData)
    , deleteOrphanedFiles : DeleteOrphanedFilesStatus
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V395.SessionIdHash.SessionIdHash Evergreen.V395.UserSession.UserSession)
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Evergreen.V395.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId) Evergreen.V395.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V395.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V395.SessionIdHash.SessionIdHash Evergreen.V395.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V395.TextEditor.LocalState
    , calls : Evergreen.V395.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V395.Id.Id Evergreen.V395.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V395.Id.Id Evergreen.V395.Id.UserId
    , name : Evergreen.V395.ChannelName.ChannelName
    , description : Evergreen.V395.ChannelDescription.ChannelDescription
    , messages : Evergreen.V395.IdArray.IdArray Evergreen.V395.Id.ChannelMessageId (Evergreen.V395.Message.Message Evergreen.V395.Id.ChannelMessageId (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Thread.LastTypedAt Evergreen.V395.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) Evergreen.V395.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V395.Drawing.Drawing (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) Evergreen.V395.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V395.Id.Id Evergreen.V395.Id.UserId
    , name : Evergreen.V395.GuildName.GuildName
    , icon : Maybe Evergreen.V395.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId) BackendChannel
    , membersAndOwner : Evergreen.V395.MembersAndOwner.MembersAndOwner (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) GuildMember
    , bannedUsers : SeqSet.SeqSet (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId)
    , invites :
        SeqDict.SeqDict
            (Evergreen.V395.SecretId.SecretId Evergreen.V395.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V395.Id.Id Evergreen.V395.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V395.ChannelName.ChannelName
    , description : Evergreen.V395.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V395.IdArray.IdArray Evergreen.V395.Id.ChannelMessageId (Evergreen.V395.Message.Message Evergreen.V395.Id.ChannelMessageId (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Thread.LastTypedAt Evergreen.V395.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V395.OneToOne.OneToOne (Evergreen.V395.Discord.Id Evergreen.V395.Discord.MessageId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) Evergreen.V395.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V395.Drawing.Drawing (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId))
    , permissionOverwrites : List Evergreen.V395.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V395.GuildName.GuildName
    , icon : Maybe Evergreen.V395.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V395.MembersAndOwner.MembersAndOwner
            (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V395.Discord.Id Evergreen.V395.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V395.Id.Id Evergreen.V395.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V395.Id.Id Evergreen.V395.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId
    , messages : List Evergreen.V395.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V395.Discord.Message
    , threads : List DiscordThreadReload
    }
