module Evergreen.V400.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V400.BackendMsgLog
import Evergreen.V400.Call
import Evergreen.V400.ChannelDescription
import Evergreen.V400.ChannelName
import Evergreen.V400.Discord
import Evergreen.V400.DiscordUserData
import Evergreen.V400.DmChannel
import Evergreen.V400.DmChannelId
import Evergreen.V400.Drawing
import Evergreen.V400.FileStatus
import Evergreen.V400.Game
import Evergreen.V400.GuildName
import Evergreen.V400.Id
import Evergreen.V400.IdArray
import Evergreen.V400.Log
import Evergreen.V400.MembersAndOwner
import Evergreen.V400.Message
import Evergreen.V400.MessageArray
import Evergreen.V400.NonemptyDict
import Evergreen.V400.OneToOne
import Evergreen.V400.Pagination
import Evergreen.V400.Postmark
import Evergreen.V400.SecretId
import Evergreen.V400.SessionIdHash
import Evergreen.V400.Slack
import Evergreen.V400.TextEditor
import Evergreen.V400.Thread
import Evergreen.V400.ToBackendLog
import Evergreen.V400.User
import Evergreen.V400.UserSession
import Evergreen.V400.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V400.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V400.Discord.Id Evergreen.V400.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V400.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V400.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V400.Call.RemoteCallData
    , currentlyViewing : Evergreen.V400.UserSession.Viewing
    }


type BackupContents
    = FullBackup
    | SubsetBackup


type alias LastBackup =
    { createdAt : Effect.Time.Posix
    , contents : BackupContents
    }


type AdminData_InvalidChannelNameGuild
    = InvalidChannelName_Guild Evergreen.V400.GuildName.GuildName
    | InvalidChannelName_DeletedGuild Evergreen.V400.GuildName.GuildName
    | InvalidChannelName_DiscordGuild Evergreen.V400.GuildName.GuildName


type alias AdminData_InvalidChannelName =
    { guild : AdminData_InvalidChannelNameGuild
    , channelName : Evergreen.V400.ChannelName.ChannelName
    , error : String
    }


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V400.Id.Id Evergreen.V400.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V400.Id.Id Evergreen.V400.Id.UserId
    , name : Evergreen.V400.ChannelName.ChannelName
    , description : Evergreen.V400.ChannelDescription.ChannelDescription
    , messages : Evergreen.V400.MessageArray.MessageArray Evergreen.V400.Id.ChannelMessageId (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelId)
    , visibleMessages : Evergreen.V400.VisibleMessages.VisibleMessages Evergreen.V400.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , threads : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId) Evergreen.V400.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V400.Drawing.Drawing (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId) Evergreen.V400.Game.MatchData
    }


type alias GuildMember =
    { joinedAt : Effect.Time.Posix
    , lastPostedAt : Maybe Effect.Time.Posix
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V400.Id.Id Evergreen.V400.Id.UserId
    , name : Evergreen.V400.GuildName.GuildName
    , icon : Maybe Evergreen.V400.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelId) FrontendChannel
    , membersAndOwner : Evergreen.V400.MembersAndOwner.MembersAndOwner (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) GuildMember
    , invites :
        SeqDict.SeqDict
            (Evergreen.V400.SecretId.SecretId Evergreen.V400.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V400.Id.Id Evergreen.V400.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) (Evergreen.V400.Thread.LastTypedAt (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelId))
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V400.ChannelName.ChannelName
    , description : Evergreen.V400.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V400.MessageArray.MessageArray Evergreen.V400.Id.ChannelMessageId (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId)
    , visibleMessages : Evergreen.V400.VisibleMessages.VisibleMessages Evergreen.V400.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId) Evergreen.V400.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V400.Drawing.Drawing (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId))
    , permissionOverwrites : List Evergreen.V400.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V400.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V400.GuildName.GuildName
    , icon : Maybe Evergreen.V400.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V400.MembersAndOwner.MembersAndOwner
            (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V400.Discord.Id Evergreen.V400.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V400.Id.Id Evergreen.V400.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V400.Id.Id Evergreen.V400.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V400.Discord.Id Evergreen.V400.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) (Evergreen.V400.Thread.LastTypedAt (Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId))
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V400.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V400.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V400.Id.Id Evergreen.V400.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V400.GuildName.GuildName
    , owner : Evergreen.V400.Id.Id Evergreen.V400.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V400.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V400.Message.Message Evergreen.V400.Id.ChannelMessageId (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId))
    , permissionOverwrites : List Evergreen.V400.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V400.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V400.MembersAndOwner.MembersAndOwner
            (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V400.Discord.Id Evergreen.V400.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V400.Discord.Id Evergreen.V400.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V400.NonemptyDict.NonemptyDict
            (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V400.Message.Message Evergreen.V400.Id.ChannelMessageId (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V400.Discord.PartialUser
        , icon : Maybe Evergreen.V400.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V400.Discord.User
        , linkedTo : Evergreen.V400.Id.Id Evergreen.V400.Id.UserId
        , icon : Maybe Evergreen.V400.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V400.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V400.Discord.User
        , linkedTo : Evergreen.V400.Id.Id Evergreen.V400.Id.UserId
        , icon : Maybe Evergreen.V400.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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
    { users : AdminDataStatus (Evergreen.V400.NonemptyDict.NonemptyDict (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) Evergreen.V400.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V400.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V400.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V400.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V400.Discord.Id Evergreen.V400.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId) AdminData_DiscordGuild)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , logs : Evergreen.V400.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V400.SessionIdHash.SessionIdHash, Evergreen.V400.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V400.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V400.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , invalidChannelNames : List AdminData_InvalidChannelName
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , orphanedFiles : AdminDataStatus (SeqDict.SeqDict Evergreen.V400.FileStatus.FileHash Evergreen.V400.FileStatus.BackendFileData)
    , deleteOrphanedFiles : DeleteOrphanedFilesStatus
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V400.SessionIdHash.SessionIdHash Evergreen.V400.UserSession.UserSession)
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) Evergreen.V400.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V400.Discord.Id Evergreen.V400.Discord.PrivateChannelId) Evergreen.V400.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V400.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V400.SessionIdHash.SessionIdHash Evergreen.V400.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V400.TextEditor.LocalState
    , calls : Evergreen.V400.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V400.Id.Id Evergreen.V400.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V400.Id.Id Evergreen.V400.Id.UserId
    , name : Evergreen.V400.ChannelName.ChannelName
    , description : Evergreen.V400.ChannelDescription.ChannelDescription
    , messages : Evergreen.V400.IdArray.IdArray Evergreen.V400.Id.ChannelMessageId (Evergreen.V400.Message.Message Evergreen.V400.Id.ChannelMessageId (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelId))
    , status : ChannelStatus
    , threads : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId) Evergreen.V400.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V400.Drawing.Drawing (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId) Evergreen.V400.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V400.Id.Id Evergreen.V400.Id.UserId
    , name : Evergreen.V400.GuildName.GuildName
    , icon : Maybe Evergreen.V400.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelId) BackendChannel
    , membersAndOwner : Evergreen.V400.MembersAndOwner.MembersAndOwner (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) GuildMember
    , bannedUsers : SeqSet.SeqSet (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId)
    , invites :
        SeqDict.SeqDict
            (Evergreen.V400.SecretId.SecretId Evergreen.V400.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V400.Id.Id Evergreen.V400.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) (Evergreen.V400.Thread.LastTypedAt (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelId))
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V400.ChannelName.ChannelName
    , description : Evergreen.V400.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V400.IdArray.IdArray Evergreen.V400.Id.ChannelMessageId (Evergreen.V400.Message.Message Evergreen.V400.Id.ChannelMessageId (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId))
    , status : ChannelStatus
    , linkedMessageIds : Evergreen.V400.OneToOne.OneToOne (Evergreen.V400.Discord.Id Evergreen.V400.Discord.MessageId) (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId) Evergreen.V400.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V400.Drawing.Drawing (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId))
    , permissionOverwrites : List Evergreen.V400.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V400.GuildName.GuildName
    , icon : Maybe Evergreen.V400.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V400.MembersAndOwner.MembersAndOwner
            (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V400.Discord.Id Evergreen.V400.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V400.Id.Id Evergreen.V400.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V400.Id.Id Evergreen.V400.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V400.Discord.Id Evergreen.V400.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) (Evergreen.V400.Thread.LastTypedAt (Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId))
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId
    , messages : List Evergreen.V400.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V400.Discord.Message
    , threads : List DiscordThreadReload
    }
