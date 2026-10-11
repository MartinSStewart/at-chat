module Evergreen.V403.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V403.BackendMsgLog
import Evergreen.V403.Call
import Evergreen.V403.ChannelDescription
import Evergreen.V403.ChannelName
import Evergreen.V403.Discord
import Evergreen.V403.DiscordUserData
import Evergreen.V403.DmChannel
import Evergreen.V403.DmChannelId
import Evergreen.V403.Drawing
import Evergreen.V403.FileStatus
import Evergreen.V403.Game
import Evergreen.V403.GuildName
import Evergreen.V403.Id
import Evergreen.V403.IdArray
import Evergreen.V403.Log
import Evergreen.V403.MembersAndOwner
import Evergreen.V403.Message
import Evergreen.V403.MessageArray
import Evergreen.V403.NonemptyDict
import Evergreen.V403.OneToOne
import Evergreen.V403.Pagination
import Evergreen.V403.Postmark
import Evergreen.V403.SecretId
import Evergreen.V403.SessionIdHash
import Evergreen.V403.Slack
import Evergreen.V403.TextEditor
import Evergreen.V403.Thread
import Evergreen.V403.ToBackendLog
import Evergreen.V403.User
import Evergreen.V403.UserSession
import Evergreen.V403.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V403.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V403.Log.Log
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V403.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V403.Call.RemoteCallData
    , currentlyViewing : Evergreen.V403.UserSession.Viewing
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
    , archivedBy : Evergreen.V403.Id.Id Evergreen.V403.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V403.Id.Id Evergreen.V403.Id.UserId
    , name : Evergreen.V403.ChannelName.ChannelName
    , description : Evergreen.V403.ChannelDescription.ChannelDescription
    , messages : Evergreen.V403.MessageArray.MessageArray Evergreen.V403.Id.ChannelMessageId (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId)
    , visibleMessages : Evergreen.V403.VisibleMessages.VisibleMessages Evergreen.V403.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , threads : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) Evergreen.V403.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V403.Drawing.Drawing (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) Evergreen.V403.Game.MatchData
    }


type alias GuildMember =
    { joinedAt : Effect.Time.Posix
    , lastPostedAt : Maybe Effect.Time.Posix
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V403.Id.Id Evergreen.V403.Id.UserId
    , name : Evergreen.V403.GuildName.GuildName
    , icon : Maybe Evergreen.V403.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId) FrontendChannel
    , membersAndOwner : Evergreen.V403.MembersAndOwner.MembersAndOwner (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) GuildMember
    , invites :
        SeqDict.SeqDict
            (Evergreen.V403.SecretId.SecretId Evergreen.V403.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V403.Id.Id Evergreen.V403.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Thread.LastTypedAt (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId))
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V403.ChannelName.ChannelName
    , description : Evergreen.V403.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V403.MessageArray.MessageArray Evergreen.V403.Id.ChannelMessageId (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId)
    , visibleMessages : Evergreen.V403.VisibleMessages.VisibleMessages Evergreen.V403.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) Evergreen.V403.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V403.Drawing.Drawing (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId))
    , permissionOverwrites : List Evergreen.V403.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V403.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V403.GuildName.GuildName
    , icon : Maybe Evergreen.V403.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V403.MembersAndOwner.MembersAndOwner
            (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V403.Discord.Id Evergreen.V403.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V403.Id.Id Evergreen.V403.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V403.Id.Id Evergreen.V403.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Thread.LastTypedAt (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId))
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V403.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V403.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V403.Id.Id Evergreen.V403.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V403.GuildName.GuildName
    , owner : Evergreen.V403.Id.Id Evergreen.V403.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V403.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V403.Message.Message Evergreen.V403.Id.ChannelMessageId (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId))
    , permissionOverwrites : List Evergreen.V403.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V403.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V403.MembersAndOwner.MembersAndOwner
            (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V403.Discord.Id Evergreen.V403.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V403.NonemptyDict.NonemptyDict
            (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V403.Message.Message Evergreen.V403.Id.ChannelMessageId (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V403.Discord.PartialUser
        , icon : Maybe Evergreen.V403.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V403.Discord.User
        , linkedTo : Evergreen.V403.Id.Id Evergreen.V403.Id.UserId
        , icon : Maybe Evergreen.V403.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V403.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V403.Discord.User
        , linkedTo : Evergreen.V403.Id.Id Evergreen.V403.Id.UserId
        , icon : Maybe Evergreen.V403.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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
    { users : AdminDataStatus (Evergreen.V403.NonemptyDict.NonemptyDict (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Evergreen.V403.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V403.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V403.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V403.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) AdminData_DiscordGuild)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , logs : Evergreen.V403.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V403.SessionIdHash.SessionIdHash, Evergreen.V403.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V403.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V403.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , orphanedFiles : AdminDataStatus (SeqDict.SeqDict Evergreen.V403.FileStatus.FileHash Evergreen.V403.FileStatus.BackendFileData)
    , deleteOrphanedFiles : DeleteOrphanedFilesStatus
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V403.SessionIdHash.SessionIdHash Evergreen.V403.UserSession.UserSession)
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Evergreen.V403.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId) Evergreen.V403.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V403.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V403.SessionIdHash.SessionIdHash Evergreen.V403.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V403.TextEditor.LocalState
    , calls : Evergreen.V403.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V403.Id.Id Evergreen.V403.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V403.Id.Id Evergreen.V403.Id.UserId
    , name : Evergreen.V403.ChannelName.ChannelName
    , description : Evergreen.V403.ChannelDescription.ChannelDescription
    , messages : Evergreen.V403.IdArray.IdArray Evergreen.V403.Id.ChannelMessageId (Evergreen.V403.Message.Message Evergreen.V403.Id.ChannelMessageId (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId))
    , status : ChannelStatus
    , threads : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) Evergreen.V403.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V403.Drawing.Drawing (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) Evergreen.V403.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V403.Id.Id Evergreen.V403.Id.UserId
    , name : Evergreen.V403.GuildName.GuildName
    , icon : Maybe Evergreen.V403.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId) BackendChannel
    , membersAndOwner : Evergreen.V403.MembersAndOwner.MembersAndOwner (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) GuildMember
    , bannedUsers : SeqSet.SeqSet (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId)
    , invites :
        SeqDict.SeqDict
            (Evergreen.V403.SecretId.SecretId Evergreen.V403.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V403.Id.Id Evergreen.V403.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Thread.LastTypedAt (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId))
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V403.ChannelName.ChannelName
    , description : Evergreen.V403.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V403.IdArray.IdArray Evergreen.V403.Id.ChannelMessageId (Evergreen.V403.Message.Message Evergreen.V403.Id.ChannelMessageId (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId))
    , status : ChannelStatus
    , linkedMessageIds : Evergreen.V403.OneToOne.OneToOne (Evergreen.V403.Discord.Id Evergreen.V403.Discord.MessageId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) Evergreen.V403.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V403.Drawing.Drawing (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId))
    , permissionOverwrites : List Evergreen.V403.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V403.GuildName.GuildName
    , icon : Maybe Evergreen.V403.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V403.MembersAndOwner.MembersAndOwner
            (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V403.Discord.Id Evergreen.V403.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V403.Id.Id Evergreen.V403.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V403.Id.Id Evergreen.V403.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Thread.LastTypedAt (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId))
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId
    , messages : List Evergreen.V403.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V403.Discord.Message
    , threads : List DiscordThreadReload
    }
