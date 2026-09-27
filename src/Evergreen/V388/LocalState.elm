module Evergreen.V388.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V388.BackendMsgLog
import Evergreen.V388.Call
import Evergreen.V388.ChannelDescription
import Evergreen.V388.ChannelName
import Evergreen.V388.Discord
import Evergreen.V388.DiscordUserData
import Evergreen.V388.DmChannel
import Evergreen.V388.DmChannelId
import Evergreen.V388.Drawing
import Evergreen.V388.FileStatus
import Evergreen.V388.Game
import Evergreen.V388.GuildName
import Evergreen.V388.Id
import Evergreen.V388.IdArray
import Evergreen.V388.Log
import Evergreen.V388.MembersAndOwner
import Evergreen.V388.Message
import Evergreen.V388.MessageArray
import Evergreen.V388.NonemptyDict
import Evergreen.V388.OneToOne
import Evergreen.V388.Pagination
import Evergreen.V388.Postmark
import Evergreen.V388.SecretId
import Evergreen.V388.SessionIdHash
import Evergreen.V388.Slack
import Evergreen.V388.TextEditor
import Evergreen.V388.Thread
import Evergreen.V388.ToBackendLog
import Evergreen.V388.User
import Evergreen.V388.UserSession
import Evergreen.V388.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V388.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V388.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V388.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V388.Call.RemoteCallData
    , currentlyViewing : Evergreen.V388.UserSession.Viewing
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
    , archivedBy : Evergreen.V388.Id.Id Evergreen.V388.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V388.Id.Id Evergreen.V388.Id.UserId
    , name : Evergreen.V388.ChannelName.ChannelName
    , description : Evergreen.V388.ChannelDescription.ChannelDescription
    , messages : Evergreen.V388.MessageArray.MessageArray Evergreen.V388.Id.ChannelMessageId (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId)
    , visibleMessages : Evergreen.V388.VisibleMessages.VisibleMessages Evergreen.V388.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Thread.LastTypedAt Evergreen.V388.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) Evergreen.V388.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V388.Drawing.Drawing (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) Evergreen.V388.Game.MatchData
    }


type alias GuildMember =
    { joinedAt : Effect.Time.Posix
    , lastPostedAt : Maybe Effect.Time.Posix
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V388.Id.Id Evergreen.V388.Id.UserId
    , name : Evergreen.V388.GuildName.GuildName
    , icon : Maybe Evergreen.V388.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId) FrontendChannel
    , membersAndOwner : Evergreen.V388.MembersAndOwner.MembersAndOwner (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) GuildMember
    , invites :
        SeqDict.SeqDict
            (Evergreen.V388.SecretId.SecretId Evergreen.V388.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V388.Id.Id Evergreen.V388.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V388.ChannelName.ChannelName
    , description : Evergreen.V388.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V388.MessageArray.MessageArray Evergreen.V388.Id.ChannelMessageId (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId)
    , visibleMessages : Evergreen.V388.VisibleMessages.VisibleMessages Evergreen.V388.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Thread.LastTypedAt Evergreen.V388.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) Evergreen.V388.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V388.Drawing.Drawing (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId))
    , permissionOverwrites : List Evergreen.V388.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V388.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V388.GuildName.GuildName
    , icon : Maybe Evergreen.V388.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V388.MembersAndOwner.MembersAndOwner
            (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V388.Discord.Id Evergreen.V388.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V388.Id.Id Evergreen.V388.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V388.Id.Id Evergreen.V388.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V388.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V388.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V388.Id.Id Evergreen.V388.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V388.GuildName.GuildName
    , owner : Evergreen.V388.Id.Id Evergreen.V388.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V388.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V388.Message.Message Evergreen.V388.Id.ChannelMessageId (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId))
    , permissionOverwrites : List Evergreen.V388.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V388.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V388.MembersAndOwner.MembersAndOwner
            (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V388.Discord.Id Evergreen.V388.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V388.NonemptyDict.NonemptyDict
            (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V388.Message.Message Evergreen.V388.Id.ChannelMessageId (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V388.Discord.PartialUser
        , icon : Maybe Evergreen.V388.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V388.Discord.User
        , linkedTo : Evergreen.V388.Id.Id Evergreen.V388.Id.UserId
        , icon : Maybe Evergreen.V388.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V388.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V388.Discord.User
        , linkedTo : Evergreen.V388.Id.Id Evergreen.V388.Id.UserId
        , icon : Maybe Evergreen.V388.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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
    { users : AdminDataStatus (Evergreen.V388.NonemptyDict.NonemptyDict (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Evergreen.V388.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V388.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V388.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V388.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) AdminData_DiscordGuild)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V388.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V388.SessionIdHash.SessionIdHash, Evergreen.V388.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V388.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V388.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , orphanedFiles : AdminDataStatus (SeqDict.SeqDict Evergreen.V388.FileStatus.FileHash Evergreen.V388.FileStatus.BackendFileData)
    , deleteOrphanedFiles : DeleteOrphanedFilesStatus
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V388.SessionIdHash.SessionIdHash Evergreen.V388.UserSession.UserSession)
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Evergreen.V388.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId) Evergreen.V388.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V388.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V388.SessionIdHash.SessionIdHash Evergreen.V388.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V388.TextEditor.LocalState
    , calls : Evergreen.V388.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V388.Id.Id Evergreen.V388.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V388.Id.Id Evergreen.V388.Id.UserId
    , name : Evergreen.V388.ChannelName.ChannelName
    , description : Evergreen.V388.ChannelDescription.ChannelDescription
    , messages : Evergreen.V388.IdArray.IdArray Evergreen.V388.Id.ChannelMessageId (Evergreen.V388.Message.Message Evergreen.V388.Id.ChannelMessageId (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Thread.LastTypedAt Evergreen.V388.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) Evergreen.V388.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V388.Drawing.Drawing (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) Evergreen.V388.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V388.Id.Id Evergreen.V388.Id.UserId
    , name : Evergreen.V388.GuildName.GuildName
    , icon : Maybe Evergreen.V388.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId) BackendChannel
    , membersAndOwner : Evergreen.V388.MembersAndOwner.MembersAndOwner (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) GuildMember
    , bannedUsers : SeqSet.SeqSet (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId)
    , invites :
        SeqDict.SeqDict
            (Evergreen.V388.SecretId.SecretId Evergreen.V388.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V388.Id.Id Evergreen.V388.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V388.ChannelName.ChannelName
    , description : Evergreen.V388.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V388.IdArray.IdArray Evergreen.V388.Id.ChannelMessageId (Evergreen.V388.Message.Message Evergreen.V388.Id.ChannelMessageId (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Thread.LastTypedAt Evergreen.V388.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V388.OneToOne.OneToOne (Evergreen.V388.Discord.Id Evergreen.V388.Discord.MessageId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) Evergreen.V388.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V388.Drawing.Drawing (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId))
    , permissionOverwrites : List Evergreen.V388.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V388.GuildName.GuildName
    , icon : Maybe Evergreen.V388.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V388.MembersAndOwner.MembersAndOwner
            (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V388.Discord.Id Evergreen.V388.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V388.Id.Id Evergreen.V388.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V388.Id.Id Evergreen.V388.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId
    , messages : List Evergreen.V388.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V388.Discord.Message
    , threads : List DiscordThreadReload
    }
