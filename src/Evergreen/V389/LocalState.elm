module Evergreen.V389.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V389.BackendMsgLog
import Evergreen.V389.Call
import Evergreen.V389.ChannelDescription
import Evergreen.V389.ChannelName
import Evergreen.V389.Discord
import Evergreen.V389.DiscordUserData
import Evergreen.V389.DmChannel
import Evergreen.V389.DmChannelId
import Evergreen.V389.Drawing
import Evergreen.V389.FileStatus
import Evergreen.V389.Game
import Evergreen.V389.GuildName
import Evergreen.V389.Id
import Evergreen.V389.IdArray
import Evergreen.V389.Log
import Evergreen.V389.MembersAndOwner
import Evergreen.V389.Message
import Evergreen.V389.MessageArray
import Evergreen.V389.NonemptyDict
import Evergreen.V389.OneToOne
import Evergreen.V389.Pagination
import Evergreen.V389.Postmark
import Evergreen.V389.SecretId
import Evergreen.V389.SessionIdHash
import Evergreen.V389.Slack
import Evergreen.V389.TextEditor
import Evergreen.V389.Thread
import Evergreen.V389.ToBackendLog
import Evergreen.V389.User
import Evergreen.V389.UserSession
import Evergreen.V389.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V389.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V389.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V389.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V389.Call.RemoteCallData
    , currentlyViewing : Evergreen.V389.UserSession.Viewing
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
    , archivedBy : Evergreen.V389.Id.Id Evergreen.V389.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V389.Id.Id Evergreen.V389.Id.UserId
    , name : Evergreen.V389.ChannelName.ChannelName
    , description : Evergreen.V389.ChannelDescription.ChannelDescription
    , messages : Evergreen.V389.MessageArray.MessageArray Evergreen.V389.Id.ChannelMessageId (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId)
    , visibleMessages : Evergreen.V389.VisibleMessages.VisibleMessages Evergreen.V389.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Thread.LastTypedAt Evergreen.V389.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) Evergreen.V389.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V389.Drawing.Drawing (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) Evergreen.V389.Game.MatchData
    }


type alias GuildMember =
    { joinedAt : Effect.Time.Posix
    , lastPostedAt : Maybe Effect.Time.Posix
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V389.Id.Id Evergreen.V389.Id.UserId
    , name : Evergreen.V389.GuildName.GuildName
    , icon : Maybe Evergreen.V389.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId) FrontendChannel
    , membersAndOwner : Evergreen.V389.MembersAndOwner.MembersAndOwner (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) GuildMember
    , invites :
        SeqDict.SeqDict
            (Evergreen.V389.SecretId.SecretId Evergreen.V389.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V389.Id.Id Evergreen.V389.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V389.ChannelName.ChannelName
    , description : Evergreen.V389.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V389.MessageArray.MessageArray Evergreen.V389.Id.ChannelMessageId (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId)
    , visibleMessages : Evergreen.V389.VisibleMessages.VisibleMessages Evergreen.V389.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Thread.LastTypedAt Evergreen.V389.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) Evergreen.V389.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V389.Drawing.Drawing (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId))
    , permissionOverwrites : List Evergreen.V389.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V389.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V389.GuildName.GuildName
    , icon : Maybe Evergreen.V389.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V389.MembersAndOwner.MembersAndOwner
            (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V389.Discord.Id Evergreen.V389.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V389.Id.Id Evergreen.V389.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V389.Id.Id Evergreen.V389.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V389.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V389.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V389.Id.Id Evergreen.V389.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V389.GuildName.GuildName
    , owner : Evergreen.V389.Id.Id Evergreen.V389.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V389.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V389.Message.Message Evergreen.V389.Id.ChannelMessageId (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId))
    , permissionOverwrites : List Evergreen.V389.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V389.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V389.MembersAndOwner.MembersAndOwner
            (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V389.Discord.Id Evergreen.V389.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V389.NonemptyDict.NonemptyDict
            (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V389.Message.Message Evergreen.V389.Id.ChannelMessageId (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V389.Discord.PartialUser
        , icon : Maybe Evergreen.V389.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V389.Discord.User
        , linkedTo : Evergreen.V389.Id.Id Evergreen.V389.Id.UserId
        , icon : Maybe Evergreen.V389.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V389.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V389.Discord.User
        , linkedTo : Evergreen.V389.Id.Id Evergreen.V389.Id.UserId
        , icon : Maybe Evergreen.V389.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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
    { users : AdminDataStatus (Evergreen.V389.NonemptyDict.NonemptyDict (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Evergreen.V389.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V389.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V389.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V389.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) AdminData_DiscordGuild)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V389.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V389.SessionIdHash.SessionIdHash, Evergreen.V389.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V389.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V389.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , orphanedFiles : AdminDataStatus (SeqDict.SeqDict Evergreen.V389.FileStatus.FileHash Evergreen.V389.FileStatus.BackendFileData)
    , deleteOrphanedFiles : DeleteOrphanedFilesStatus
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V389.SessionIdHash.SessionIdHash Evergreen.V389.UserSession.UserSession)
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Evergreen.V389.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId) Evergreen.V389.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V389.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V389.SessionIdHash.SessionIdHash Evergreen.V389.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V389.TextEditor.LocalState
    , calls : Evergreen.V389.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V389.Id.Id Evergreen.V389.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V389.Id.Id Evergreen.V389.Id.UserId
    , name : Evergreen.V389.ChannelName.ChannelName
    , description : Evergreen.V389.ChannelDescription.ChannelDescription
    , messages : Evergreen.V389.IdArray.IdArray Evergreen.V389.Id.ChannelMessageId (Evergreen.V389.Message.Message Evergreen.V389.Id.ChannelMessageId (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Thread.LastTypedAt Evergreen.V389.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) Evergreen.V389.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V389.Drawing.Drawing (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) Evergreen.V389.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V389.Id.Id Evergreen.V389.Id.UserId
    , name : Evergreen.V389.GuildName.GuildName
    , icon : Maybe Evergreen.V389.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId) BackendChannel
    , membersAndOwner : Evergreen.V389.MembersAndOwner.MembersAndOwner (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) GuildMember
    , bannedUsers : SeqSet.SeqSet (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId)
    , invites :
        SeqDict.SeqDict
            (Evergreen.V389.SecretId.SecretId Evergreen.V389.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V389.Id.Id Evergreen.V389.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V389.ChannelName.ChannelName
    , description : Evergreen.V389.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V389.IdArray.IdArray Evergreen.V389.Id.ChannelMessageId (Evergreen.V389.Message.Message Evergreen.V389.Id.ChannelMessageId (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Thread.LastTypedAt Evergreen.V389.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V389.OneToOne.OneToOne (Evergreen.V389.Discord.Id Evergreen.V389.Discord.MessageId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) Evergreen.V389.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V389.Drawing.Drawing (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId))
    , permissionOverwrites : List Evergreen.V389.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V389.GuildName.GuildName
    , icon : Maybe Evergreen.V389.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V389.MembersAndOwner.MembersAndOwner
            (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V389.Discord.Id Evergreen.V389.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V389.Id.Id Evergreen.V389.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V389.Id.Id Evergreen.V389.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId
    , messages : List Evergreen.V389.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V389.Discord.Message
    , threads : List DiscordThreadReload
    }
