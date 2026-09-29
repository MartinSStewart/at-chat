module Evergreen.V394.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V394.BackendMsgLog
import Evergreen.V394.Call
import Evergreen.V394.ChannelDescription
import Evergreen.V394.ChannelName
import Evergreen.V394.Discord
import Evergreen.V394.DiscordUserData
import Evergreen.V394.DmChannel
import Evergreen.V394.DmChannelId
import Evergreen.V394.Drawing
import Evergreen.V394.FileStatus
import Evergreen.V394.Game
import Evergreen.V394.GuildName
import Evergreen.V394.Id
import Evergreen.V394.IdArray
import Evergreen.V394.Log
import Evergreen.V394.MembersAndOwner
import Evergreen.V394.Message
import Evergreen.V394.MessageArray
import Evergreen.V394.NonemptyDict
import Evergreen.V394.OneToOne
import Evergreen.V394.Pagination
import Evergreen.V394.Postmark
import Evergreen.V394.SecretId
import Evergreen.V394.SessionIdHash
import Evergreen.V394.Slack
import Evergreen.V394.TextEditor
import Evergreen.V394.Thread
import Evergreen.V394.ToBackendLog
import Evergreen.V394.User
import Evergreen.V394.UserSession
import Evergreen.V394.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V394.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V394.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V394.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V394.Call.RemoteCallData
    , currentlyViewing : Evergreen.V394.UserSession.Viewing
    }


type BackupContents
    = FullBackup
    | SubsetBackup


type alias LastBackup =
    { createdAt : Effect.Time.Posix
    , contents : BackupContents
    }


type AdminData_InvalidChannelNameGuild
    = InvalidChannelName_Guild Evergreen.V394.GuildName.GuildName
    | InvalidChannelName_DeletedGuild Evergreen.V394.GuildName.GuildName
    | InvalidChannelName_DiscordGuild Evergreen.V394.GuildName.GuildName


type alias AdminData_InvalidChannelName =
    { guild : AdminData_InvalidChannelNameGuild
    , channelName : Evergreen.V394.ChannelName.ChannelName
    , error : String
    }


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V394.Id.Id Evergreen.V394.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V394.Id.Id Evergreen.V394.Id.UserId
    , name : Evergreen.V394.ChannelName.ChannelName
    , description : Evergreen.V394.ChannelDescription.ChannelDescription
    , messages : Evergreen.V394.MessageArray.MessageArray Evergreen.V394.Id.ChannelMessageId (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId)
    , visibleMessages : Evergreen.V394.VisibleMessages.VisibleMessages Evergreen.V394.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Thread.LastTypedAt Evergreen.V394.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) Evergreen.V394.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V394.Drawing.Drawing (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) Evergreen.V394.Game.MatchData
    }


type alias GuildMember =
    { joinedAt : Effect.Time.Posix
    , lastPostedAt : Maybe Effect.Time.Posix
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V394.Id.Id Evergreen.V394.Id.UserId
    , name : Evergreen.V394.GuildName.GuildName
    , icon : Maybe Evergreen.V394.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId) FrontendChannel
    , membersAndOwner : Evergreen.V394.MembersAndOwner.MembersAndOwner (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) GuildMember
    , invites :
        SeqDict.SeqDict
            (Evergreen.V394.SecretId.SecretId Evergreen.V394.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V394.Id.Id Evergreen.V394.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V394.ChannelName.ChannelName
    , description : Evergreen.V394.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V394.MessageArray.MessageArray Evergreen.V394.Id.ChannelMessageId (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId)
    , visibleMessages : Evergreen.V394.VisibleMessages.VisibleMessages Evergreen.V394.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Thread.LastTypedAt Evergreen.V394.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) Evergreen.V394.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V394.Drawing.Drawing (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId))
    , permissionOverwrites : List Evergreen.V394.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V394.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V394.GuildName.GuildName
    , icon : Maybe Evergreen.V394.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V394.MembersAndOwner.MembersAndOwner
            (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V394.Discord.Id Evergreen.V394.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V394.Id.Id Evergreen.V394.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V394.Id.Id Evergreen.V394.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V394.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V394.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V394.Id.Id Evergreen.V394.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V394.GuildName.GuildName
    , owner : Evergreen.V394.Id.Id Evergreen.V394.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V394.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V394.Message.Message Evergreen.V394.Id.ChannelMessageId (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId))
    , permissionOverwrites : List Evergreen.V394.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V394.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V394.MembersAndOwner.MembersAndOwner
            (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V394.Discord.Id Evergreen.V394.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V394.NonemptyDict.NonemptyDict
            (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V394.Message.Message Evergreen.V394.Id.ChannelMessageId (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V394.Discord.PartialUser
        , icon : Maybe Evergreen.V394.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V394.Discord.User
        , linkedTo : Evergreen.V394.Id.Id Evergreen.V394.Id.UserId
        , icon : Maybe Evergreen.V394.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V394.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V394.Discord.User
        , linkedTo : Evergreen.V394.Id.Id Evergreen.V394.Id.UserId
        , icon : Maybe Evergreen.V394.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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
    { users : AdminDataStatus (Evergreen.V394.NonemptyDict.NonemptyDict (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Evergreen.V394.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V394.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V394.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V394.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) AdminData_DiscordGuild)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V394.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V394.SessionIdHash.SessionIdHash, Evergreen.V394.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V394.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V394.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , invalidChannelNames : List AdminData_InvalidChannelName
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , orphanedFiles : AdminDataStatus (SeqDict.SeqDict Evergreen.V394.FileStatus.FileHash Evergreen.V394.FileStatus.BackendFileData)
    , deleteOrphanedFiles : DeleteOrphanedFilesStatus
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V394.SessionIdHash.SessionIdHash Evergreen.V394.UserSession.UserSession)
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Evergreen.V394.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId) Evergreen.V394.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V394.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V394.SessionIdHash.SessionIdHash Evergreen.V394.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V394.TextEditor.LocalState
    , calls : Evergreen.V394.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V394.Id.Id Evergreen.V394.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V394.Id.Id Evergreen.V394.Id.UserId
    , name : Evergreen.V394.ChannelName.ChannelName
    , description : Evergreen.V394.ChannelDescription.ChannelDescription
    , messages : Evergreen.V394.IdArray.IdArray Evergreen.V394.Id.ChannelMessageId (Evergreen.V394.Message.Message Evergreen.V394.Id.ChannelMessageId (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Thread.LastTypedAt Evergreen.V394.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) Evergreen.V394.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V394.Drawing.Drawing (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) Evergreen.V394.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V394.Id.Id Evergreen.V394.Id.UserId
    , name : Evergreen.V394.GuildName.GuildName
    , icon : Maybe Evergreen.V394.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId) BackendChannel
    , membersAndOwner : Evergreen.V394.MembersAndOwner.MembersAndOwner (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) GuildMember
    , bannedUsers : SeqSet.SeqSet (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId)
    , invites :
        SeqDict.SeqDict
            (Evergreen.V394.SecretId.SecretId Evergreen.V394.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V394.Id.Id Evergreen.V394.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V394.ChannelName.ChannelName
    , description : Evergreen.V394.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V394.IdArray.IdArray Evergreen.V394.Id.ChannelMessageId (Evergreen.V394.Message.Message Evergreen.V394.Id.ChannelMessageId (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Thread.LastTypedAt Evergreen.V394.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V394.OneToOne.OneToOne (Evergreen.V394.Discord.Id Evergreen.V394.Discord.MessageId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) Evergreen.V394.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V394.Drawing.Drawing (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId))
    , permissionOverwrites : List Evergreen.V394.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V394.GuildName.GuildName
    , icon : Maybe Evergreen.V394.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V394.MembersAndOwner.MembersAndOwner
            (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V394.Discord.Id Evergreen.V394.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V394.Id.Id Evergreen.V394.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V394.Id.Id Evergreen.V394.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId
    , messages : List Evergreen.V394.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V394.Discord.Message
    , threads : List DiscordThreadReload
    }
