module Evergreen.V396.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V396.BackendMsgLog
import Evergreen.V396.Call
import Evergreen.V396.ChannelDescription
import Evergreen.V396.ChannelName
import Evergreen.V396.Discord
import Evergreen.V396.DiscordUserData
import Evergreen.V396.DmChannel
import Evergreen.V396.DmChannelId
import Evergreen.V396.Drawing
import Evergreen.V396.FileStatus
import Evergreen.V396.Game
import Evergreen.V396.GuildName
import Evergreen.V396.Id
import Evergreen.V396.IdArray
import Evergreen.V396.Log
import Evergreen.V396.MembersAndOwner
import Evergreen.V396.Message
import Evergreen.V396.MessageArray
import Evergreen.V396.NonemptyDict
import Evergreen.V396.OneToOne
import Evergreen.V396.Pagination
import Evergreen.V396.Postmark
import Evergreen.V396.SecretId
import Evergreen.V396.SessionIdHash
import Evergreen.V396.Slack
import Evergreen.V396.TextEditor
import Evergreen.V396.Thread
import Evergreen.V396.ToBackendLog
import Evergreen.V396.User
import Evergreen.V396.UserSession
import Evergreen.V396.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V396.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V396.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V396.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V396.Call.RemoteCallData
    , currentlyViewing : Evergreen.V396.UserSession.Viewing
    }


type BackupContents
    = FullBackup
    | SubsetBackup


type alias LastBackup =
    { createdAt : Effect.Time.Posix
    , contents : BackupContents
    }


type AdminData_InvalidChannelNameGuild
    = InvalidChannelName_Guild Evergreen.V396.GuildName.GuildName
    | InvalidChannelName_DeletedGuild Evergreen.V396.GuildName.GuildName
    | InvalidChannelName_DiscordGuild Evergreen.V396.GuildName.GuildName


type alias AdminData_InvalidChannelName =
    { guild : AdminData_InvalidChannelNameGuild
    , channelName : Evergreen.V396.ChannelName.ChannelName
    , error : String
    }


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V396.Id.Id Evergreen.V396.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V396.Id.Id Evergreen.V396.Id.UserId
    , name : Evergreen.V396.ChannelName.ChannelName
    , description : Evergreen.V396.ChannelDescription.ChannelDescription
    , messages : Evergreen.V396.MessageArray.MessageArray Evergreen.V396.Id.ChannelMessageId (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId)
    , visibleMessages : Evergreen.V396.VisibleMessages.VisibleMessages Evergreen.V396.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Thread.LastTypedAt Evergreen.V396.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) Evergreen.V396.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V396.Drawing.Drawing (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) Evergreen.V396.Game.MatchData
    }


type alias GuildMember =
    { joinedAt : Effect.Time.Posix
    , lastPostedAt : Maybe Effect.Time.Posix
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V396.Id.Id Evergreen.V396.Id.UserId
    , name : Evergreen.V396.GuildName.GuildName
    , icon : Maybe Evergreen.V396.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId) FrontendChannel
    , membersAndOwner : Evergreen.V396.MembersAndOwner.MembersAndOwner (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) GuildMember
    , invites :
        SeqDict.SeqDict
            (Evergreen.V396.SecretId.SecretId Evergreen.V396.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V396.Id.Id Evergreen.V396.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V396.ChannelName.ChannelName
    , description : Evergreen.V396.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V396.MessageArray.MessageArray Evergreen.V396.Id.ChannelMessageId (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId)
    , visibleMessages : Evergreen.V396.VisibleMessages.VisibleMessages Evergreen.V396.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Thread.LastTypedAt Evergreen.V396.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) Evergreen.V396.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V396.Drawing.Drawing (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId))
    , permissionOverwrites : List Evergreen.V396.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V396.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V396.GuildName.GuildName
    , icon : Maybe Evergreen.V396.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V396.MembersAndOwner.MembersAndOwner
            (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V396.Discord.Id Evergreen.V396.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V396.Id.Id Evergreen.V396.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V396.Id.Id Evergreen.V396.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V396.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V396.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V396.Id.Id Evergreen.V396.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V396.GuildName.GuildName
    , owner : Evergreen.V396.Id.Id Evergreen.V396.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V396.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V396.Message.Message Evergreen.V396.Id.ChannelMessageId (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId))
    , permissionOverwrites : List Evergreen.V396.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V396.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V396.MembersAndOwner.MembersAndOwner
            (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V396.Discord.Id Evergreen.V396.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V396.NonemptyDict.NonemptyDict
            (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V396.Message.Message Evergreen.V396.Id.ChannelMessageId (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V396.Discord.PartialUser
        , icon : Maybe Evergreen.V396.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V396.Discord.User
        , linkedTo : Evergreen.V396.Id.Id Evergreen.V396.Id.UserId
        , icon : Maybe Evergreen.V396.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V396.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V396.Discord.User
        , linkedTo : Evergreen.V396.Id.Id Evergreen.V396.Id.UserId
        , icon : Maybe Evergreen.V396.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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
    { users : AdminDataStatus (Evergreen.V396.NonemptyDict.NonemptyDict (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Evergreen.V396.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V396.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V396.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V396.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) AdminData_DiscordGuild)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , logs : Evergreen.V396.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V396.SessionIdHash.SessionIdHash, Evergreen.V396.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V396.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V396.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , invalidChannelNames : List AdminData_InvalidChannelName
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , orphanedFiles : AdminDataStatus (SeqDict.SeqDict Evergreen.V396.FileStatus.FileHash Evergreen.V396.FileStatus.BackendFileData)
    , deleteOrphanedFiles : DeleteOrphanedFilesStatus
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V396.SessionIdHash.SessionIdHash Evergreen.V396.UserSession.UserSession)
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Evergreen.V396.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId) Evergreen.V396.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V396.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V396.SessionIdHash.SessionIdHash Evergreen.V396.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V396.TextEditor.LocalState
    , calls : Evergreen.V396.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V396.Id.Id Evergreen.V396.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V396.Id.Id Evergreen.V396.Id.UserId
    , name : Evergreen.V396.ChannelName.ChannelName
    , description : Evergreen.V396.ChannelDescription.ChannelDescription
    , messages : Evergreen.V396.IdArray.IdArray Evergreen.V396.Id.ChannelMessageId (Evergreen.V396.Message.Message Evergreen.V396.Id.ChannelMessageId (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Thread.LastTypedAt Evergreen.V396.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) Evergreen.V396.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V396.Drawing.Drawing (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) Evergreen.V396.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V396.Id.Id Evergreen.V396.Id.UserId
    , name : Evergreen.V396.GuildName.GuildName
    , icon : Maybe Evergreen.V396.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId) BackendChannel
    , membersAndOwner : Evergreen.V396.MembersAndOwner.MembersAndOwner (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) GuildMember
    , bannedUsers : SeqSet.SeqSet (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId)
    , invites :
        SeqDict.SeqDict
            (Evergreen.V396.SecretId.SecretId Evergreen.V396.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V396.Id.Id Evergreen.V396.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V396.ChannelName.ChannelName
    , description : Evergreen.V396.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V396.IdArray.IdArray Evergreen.V396.Id.ChannelMessageId (Evergreen.V396.Message.Message Evergreen.V396.Id.ChannelMessageId (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Thread.LastTypedAt Evergreen.V396.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V396.OneToOne.OneToOne (Evergreen.V396.Discord.Id Evergreen.V396.Discord.MessageId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) Evergreen.V396.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V396.Drawing.Drawing (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId))
    , permissionOverwrites : List Evergreen.V396.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V396.GuildName.GuildName
    , icon : Maybe Evergreen.V396.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V396.MembersAndOwner.MembersAndOwner
            (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V396.Discord.Id Evergreen.V396.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V396.Id.Id Evergreen.V396.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V396.Id.Id Evergreen.V396.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId
    , messages : List Evergreen.V396.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V396.Discord.Message
    , threads : List DiscordThreadReload
    }
