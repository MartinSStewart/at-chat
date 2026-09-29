module Evergreen.V392.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V392.BackendMsgLog
import Evergreen.V392.Call
import Evergreen.V392.ChannelDescription
import Evergreen.V392.ChannelName
import Evergreen.V392.Discord
import Evergreen.V392.DiscordUserData
import Evergreen.V392.DmChannel
import Evergreen.V392.DmChannelId
import Evergreen.V392.Drawing
import Evergreen.V392.FileStatus
import Evergreen.V392.Game
import Evergreen.V392.GuildName
import Evergreen.V392.Id
import Evergreen.V392.IdArray
import Evergreen.V392.Log
import Evergreen.V392.MembersAndOwner
import Evergreen.V392.Message
import Evergreen.V392.MessageArray
import Evergreen.V392.NonemptyDict
import Evergreen.V392.OneToOne
import Evergreen.V392.Pagination
import Evergreen.V392.Postmark
import Evergreen.V392.SecretId
import Evergreen.V392.SessionIdHash
import Evergreen.V392.Slack
import Evergreen.V392.TextEditor
import Evergreen.V392.Thread
import Evergreen.V392.ToBackendLog
import Evergreen.V392.User
import Evergreen.V392.UserSession
import Evergreen.V392.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V392.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V392.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V392.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V392.Call.RemoteCallData
    , currentlyViewing : Evergreen.V392.UserSession.Viewing
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
    , archivedBy : Evergreen.V392.Id.Id Evergreen.V392.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V392.Id.Id Evergreen.V392.Id.UserId
    , name : Evergreen.V392.ChannelName.ChannelName
    , description : Evergreen.V392.ChannelDescription.ChannelDescription
    , messages : Evergreen.V392.MessageArray.MessageArray Evergreen.V392.Id.ChannelMessageId (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId)
    , visibleMessages : Evergreen.V392.VisibleMessages.VisibleMessages Evergreen.V392.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Thread.LastTypedAt Evergreen.V392.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) Evergreen.V392.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V392.Drawing.Drawing (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) Evergreen.V392.Game.MatchData
    }


type alias GuildMember =
    { joinedAt : Effect.Time.Posix
    , lastPostedAt : Maybe Effect.Time.Posix
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V392.Id.Id Evergreen.V392.Id.UserId
    , name : Evergreen.V392.GuildName.GuildName
    , icon : Maybe Evergreen.V392.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId) FrontendChannel
    , membersAndOwner : Evergreen.V392.MembersAndOwner.MembersAndOwner (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) GuildMember
    , invites :
        SeqDict.SeqDict
            (Evergreen.V392.SecretId.SecretId Evergreen.V392.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V392.Id.Id Evergreen.V392.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V392.ChannelName.ChannelName
    , description : Evergreen.V392.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V392.MessageArray.MessageArray Evergreen.V392.Id.ChannelMessageId (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId)
    , visibleMessages : Evergreen.V392.VisibleMessages.VisibleMessages Evergreen.V392.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Thread.LastTypedAt Evergreen.V392.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) Evergreen.V392.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V392.Drawing.Drawing (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId))
    , permissionOverwrites : List Evergreen.V392.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V392.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V392.GuildName.GuildName
    , icon : Maybe Evergreen.V392.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V392.MembersAndOwner.MembersAndOwner
            (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V392.Discord.Id Evergreen.V392.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V392.Id.Id Evergreen.V392.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V392.Id.Id Evergreen.V392.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V392.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V392.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V392.Id.Id Evergreen.V392.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V392.GuildName.GuildName
    , owner : Evergreen.V392.Id.Id Evergreen.V392.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V392.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V392.Message.Message Evergreen.V392.Id.ChannelMessageId (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId))
    , permissionOverwrites : List Evergreen.V392.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V392.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V392.MembersAndOwner.MembersAndOwner
            (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V392.Discord.Id Evergreen.V392.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V392.NonemptyDict.NonemptyDict
            (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V392.Message.Message Evergreen.V392.Id.ChannelMessageId (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V392.Discord.PartialUser
        , icon : Maybe Evergreen.V392.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V392.Discord.User
        , linkedTo : Evergreen.V392.Id.Id Evergreen.V392.Id.UserId
        , icon : Maybe Evergreen.V392.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V392.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V392.Discord.User
        , linkedTo : Evergreen.V392.Id.Id Evergreen.V392.Id.UserId
        , icon : Maybe Evergreen.V392.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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
    { users : AdminDataStatus (Evergreen.V392.NonemptyDict.NonemptyDict (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Evergreen.V392.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V392.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V392.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V392.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) AdminData_DiscordGuild)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V392.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V392.SessionIdHash.SessionIdHash, Evergreen.V392.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V392.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V392.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , orphanedFiles : AdminDataStatus (SeqDict.SeqDict Evergreen.V392.FileStatus.FileHash Evergreen.V392.FileStatus.BackendFileData)
    , deleteOrphanedFiles : DeleteOrphanedFilesStatus
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V392.SessionIdHash.SessionIdHash Evergreen.V392.UserSession.UserSession)
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Evergreen.V392.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId) Evergreen.V392.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V392.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V392.SessionIdHash.SessionIdHash Evergreen.V392.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V392.TextEditor.LocalState
    , calls : Evergreen.V392.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V392.Id.Id Evergreen.V392.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V392.Id.Id Evergreen.V392.Id.UserId
    , name : Evergreen.V392.ChannelName.ChannelName
    , description : Evergreen.V392.ChannelDescription.ChannelDescription
    , messages : Evergreen.V392.IdArray.IdArray Evergreen.V392.Id.ChannelMessageId (Evergreen.V392.Message.Message Evergreen.V392.Id.ChannelMessageId (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Thread.LastTypedAt Evergreen.V392.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) Evergreen.V392.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V392.Drawing.Drawing (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) Evergreen.V392.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V392.Id.Id Evergreen.V392.Id.UserId
    , name : Evergreen.V392.GuildName.GuildName
    , icon : Maybe Evergreen.V392.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId) BackendChannel
    , membersAndOwner : Evergreen.V392.MembersAndOwner.MembersAndOwner (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) GuildMember
    , bannedUsers : SeqSet.SeqSet (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId)
    , invites :
        SeqDict.SeqDict
            (Evergreen.V392.SecretId.SecretId Evergreen.V392.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V392.Id.Id Evergreen.V392.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V392.ChannelName.ChannelName
    , description : Evergreen.V392.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V392.IdArray.IdArray Evergreen.V392.Id.ChannelMessageId (Evergreen.V392.Message.Message Evergreen.V392.Id.ChannelMessageId (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Thread.LastTypedAt Evergreen.V392.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V392.OneToOne.OneToOne (Evergreen.V392.Discord.Id Evergreen.V392.Discord.MessageId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) Evergreen.V392.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V392.Drawing.Drawing (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId))
    , permissionOverwrites : List Evergreen.V392.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V392.GuildName.GuildName
    , icon : Maybe Evergreen.V392.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V392.MembersAndOwner.MembersAndOwner
            (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V392.Discord.Id Evergreen.V392.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V392.Id.Id Evergreen.V392.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V392.Id.Id Evergreen.V392.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId
    , messages : List Evergreen.V392.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V392.Discord.Message
    , threads : List DiscordThreadReload
    }
