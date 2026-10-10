module Evergreen.V402.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V402.BackendMsgLog
import Evergreen.V402.Call
import Evergreen.V402.ChannelDescription
import Evergreen.V402.ChannelName
import Evergreen.V402.Discord
import Evergreen.V402.DiscordUserData
import Evergreen.V402.DmChannel
import Evergreen.V402.DmChannelId
import Evergreen.V402.Drawing
import Evergreen.V402.FileStatus
import Evergreen.V402.Game
import Evergreen.V402.GuildName
import Evergreen.V402.Id
import Evergreen.V402.IdArray
import Evergreen.V402.Log
import Evergreen.V402.MembersAndOwner
import Evergreen.V402.Message
import Evergreen.V402.MessageArray
import Evergreen.V402.NonemptyDict
import Evergreen.V402.OneToOne
import Evergreen.V402.Pagination
import Evergreen.V402.Postmark
import Evergreen.V402.SecretId
import Evergreen.V402.SessionIdHash
import Evergreen.V402.Slack
import Evergreen.V402.TextEditor
import Evergreen.V402.Thread
import Evergreen.V402.ToBackendLog
import Evergreen.V402.User
import Evergreen.V402.UserSession
import Evergreen.V402.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V402.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V402.Log.Log
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V402.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V402.Call.RemoteCallData
    , currentlyViewing : Evergreen.V402.UserSession.Viewing
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
    , archivedBy : Evergreen.V402.Id.Id Evergreen.V402.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V402.Id.Id Evergreen.V402.Id.UserId
    , name : Evergreen.V402.ChannelName.ChannelName
    , description : Evergreen.V402.ChannelDescription.ChannelDescription
    , messages : Evergreen.V402.MessageArray.MessageArray Evergreen.V402.Id.ChannelMessageId (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId)
    , visibleMessages : Evergreen.V402.VisibleMessages.VisibleMessages Evergreen.V402.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , threads : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) Evergreen.V402.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V402.Drawing.Drawing (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) Evergreen.V402.Game.MatchData
    }


type alias GuildMember =
    { joinedAt : Effect.Time.Posix
    , lastPostedAt : Maybe Effect.Time.Posix
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V402.Id.Id Evergreen.V402.Id.UserId
    , name : Evergreen.V402.GuildName.GuildName
    , icon : Maybe Evergreen.V402.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId) FrontendChannel
    , membersAndOwner : Evergreen.V402.MembersAndOwner.MembersAndOwner (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) GuildMember
    , invites :
        SeqDict.SeqDict
            (Evergreen.V402.SecretId.SecretId Evergreen.V402.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V402.Id.Id Evergreen.V402.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Thread.LastTypedAt (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId))
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V402.ChannelName.ChannelName
    , description : Evergreen.V402.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V402.MessageArray.MessageArray Evergreen.V402.Id.ChannelMessageId (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId)
    , visibleMessages : Evergreen.V402.VisibleMessages.VisibleMessages Evergreen.V402.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) Evergreen.V402.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V402.Drawing.Drawing (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId))
    , permissionOverwrites : List Evergreen.V402.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V402.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V402.GuildName.GuildName
    , icon : Maybe Evergreen.V402.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V402.MembersAndOwner.MembersAndOwner
            (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V402.Discord.Id Evergreen.V402.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V402.Id.Id Evergreen.V402.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V402.Id.Id Evergreen.V402.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Thread.LastTypedAt (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId))
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V402.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V402.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V402.Id.Id Evergreen.V402.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V402.GuildName.GuildName
    , owner : Evergreen.V402.Id.Id Evergreen.V402.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V402.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V402.Message.Message Evergreen.V402.Id.ChannelMessageId (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId))
    , permissionOverwrites : List Evergreen.V402.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V402.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V402.MembersAndOwner.MembersAndOwner
            (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V402.Discord.Id Evergreen.V402.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V402.NonemptyDict.NonemptyDict
            (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V402.Message.Message Evergreen.V402.Id.ChannelMessageId (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V402.Discord.PartialUser
        , icon : Maybe Evergreen.V402.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V402.Discord.User
        , linkedTo : Evergreen.V402.Id.Id Evergreen.V402.Id.UserId
        , icon : Maybe Evergreen.V402.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V402.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V402.Discord.User
        , linkedTo : Evergreen.V402.Id.Id Evergreen.V402.Id.UserId
        , icon : Maybe Evergreen.V402.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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
    { users : AdminDataStatus (Evergreen.V402.NonemptyDict.NonemptyDict (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Evergreen.V402.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V402.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V402.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V402.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) AdminData_DiscordGuild)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , logs : Evergreen.V402.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V402.SessionIdHash.SessionIdHash, Evergreen.V402.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V402.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V402.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , orphanedFiles : AdminDataStatus (SeqDict.SeqDict Evergreen.V402.FileStatus.FileHash Evergreen.V402.FileStatus.BackendFileData)
    , deleteOrphanedFiles : DeleteOrphanedFilesStatus
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V402.SessionIdHash.SessionIdHash Evergreen.V402.UserSession.UserSession)
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Evergreen.V402.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId) Evergreen.V402.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V402.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V402.SessionIdHash.SessionIdHash Evergreen.V402.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V402.TextEditor.LocalState
    , calls : Evergreen.V402.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V402.Id.Id Evergreen.V402.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V402.Id.Id Evergreen.V402.Id.UserId
    , name : Evergreen.V402.ChannelName.ChannelName
    , description : Evergreen.V402.ChannelDescription.ChannelDescription
    , messages : Evergreen.V402.IdArray.IdArray Evergreen.V402.Id.ChannelMessageId (Evergreen.V402.Message.Message Evergreen.V402.Id.ChannelMessageId (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId))
    , status : ChannelStatus
    , threads : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) Evergreen.V402.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V402.Drawing.Drawing (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) Evergreen.V402.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V402.Id.Id Evergreen.V402.Id.UserId
    , name : Evergreen.V402.GuildName.GuildName
    , icon : Maybe Evergreen.V402.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId) BackendChannel
    , membersAndOwner : Evergreen.V402.MembersAndOwner.MembersAndOwner (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) GuildMember
    , bannedUsers : SeqSet.SeqSet (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId)
    , invites :
        SeqDict.SeqDict
            (Evergreen.V402.SecretId.SecretId Evergreen.V402.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V402.Id.Id Evergreen.V402.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Thread.LastTypedAt (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId))
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V402.ChannelName.ChannelName
    , description : Evergreen.V402.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V402.IdArray.IdArray Evergreen.V402.Id.ChannelMessageId (Evergreen.V402.Message.Message Evergreen.V402.Id.ChannelMessageId (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId))
    , status : ChannelStatus
    , linkedMessageIds : Evergreen.V402.OneToOne.OneToOne (Evergreen.V402.Discord.Id Evergreen.V402.Discord.MessageId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) Evergreen.V402.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V402.Drawing.Drawing (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId))
    , permissionOverwrites : List Evergreen.V402.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V402.GuildName.GuildName
    , icon : Maybe Evergreen.V402.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V402.MembersAndOwner.MembersAndOwner
            (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V402.Discord.Id Evergreen.V402.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V402.Id.Id Evergreen.V402.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V402.Id.Id Evergreen.V402.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Thread.LastTypedAt (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId))
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId
    , messages : List Evergreen.V402.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V402.Discord.Message
    , threads : List DiscordThreadReload
    }
