module Evergreen.V397.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V397.BackendMsgLog
import Evergreen.V397.Call
import Evergreen.V397.ChannelDescription
import Evergreen.V397.ChannelName
import Evergreen.V397.Discord
import Evergreen.V397.DiscordUserData
import Evergreen.V397.DmChannel
import Evergreen.V397.DmChannelId
import Evergreen.V397.Drawing
import Evergreen.V397.FileStatus
import Evergreen.V397.Game
import Evergreen.V397.GuildName
import Evergreen.V397.Id
import Evergreen.V397.IdArray
import Evergreen.V397.Log
import Evergreen.V397.MembersAndOwner
import Evergreen.V397.Message
import Evergreen.V397.MessageArray
import Evergreen.V397.NonemptyDict
import Evergreen.V397.OneToOne
import Evergreen.V397.Pagination
import Evergreen.V397.Postmark
import Evergreen.V397.SecretId
import Evergreen.V397.SessionIdHash
import Evergreen.V397.Slack
import Evergreen.V397.TextEditor
import Evergreen.V397.Thread
import Evergreen.V397.ToBackendLog
import Evergreen.V397.User
import Evergreen.V397.UserSession
import Evergreen.V397.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V397.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V397.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V397.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V397.Call.RemoteCallData
    , currentlyViewing : Evergreen.V397.UserSession.Viewing
    }


type BackupContents
    = FullBackup
    | SubsetBackup


type alias LastBackup =
    { createdAt : Effect.Time.Posix
    , contents : BackupContents
    }


type AdminData_InvalidChannelNameGuild
    = InvalidChannelName_Guild Evergreen.V397.GuildName.GuildName
    | InvalidChannelName_DeletedGuild Evergreen.V397.GuildName.GuildName
    | InvalidChannelName_DiscordGuild Evergreen.V397.GuildName.GuildName


type alias AdminData_InvalidChannelName =
    { guild : AdminData_InvalidChannelNameGuild
    , channelName : Evergreen.V397.ChannelName.ChannelName
    , error : String
    }


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V397.Id.Id Evergreen.V397.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V397.Id.Id Evergreen.V397.Id.UserId
    , name : Evergreen.V397.ChannelName.ChannelName
    , description : Evergreen.V397.ChannelDescription.ChannelDescription
    , messages : Evergreen.V397.MessageArray.MessageArray Evergreen.V397.Id.ChannelMessageId (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId)
    , visibleMessages : Evergreen.V397.VisibleMessages.VisibleMessages Evergreen.V397.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , threads : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) Evergreen.V397.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V397.Drawing.Drawing (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) Evergreen.V397.Game.MatchData
    }


type alias GuildMember =
    { joinedAt : Effect.Time.Posix
    , lastPostedAt : Maybe Effect.Time.Posix
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V397.Id.Id Evergreen.V397.Id.UserId
    , name : Evergreen.V397.GuildName.GuildName
    , icon : Maybe Evergreen.V397.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId) FrontendChannel
    , membersAndOwner : Evergreen.V397.MembersAndOwner.MembersAndOwner (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) GuildMember
    , invites :
        SeqDict.SeqDict
            (Evergreen.V397.SecretId.SecretId Evergreen.V397.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V397.Id.Id Evergreen.V397.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Thread.LastTypedAt (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId))
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V397.ChannelName.ChannelName
    , description : Evergreen.V397.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V397.MessageArray.MessageArray Evergreen.V397.Id.ChannelMessageId (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId)
    , visibleMessages : Evergreen.V397.VisibleMessages.VisibleMessages Evergreen.V397.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) Evergreen.V397.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V397.Drawing.Drawing (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId))
    , permissionOverwrites : List Evergreen.V397.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V397.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V397.GuildName.GuildName
    , icon : Maybe Evergreen.V397.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V397.MembersAndOwner.MembersAndOwner
            (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V397.Discord.Id Evergreen.V397.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V397.Id.Id Evergreen.V397.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V397.Id.Id Evergreen.V397.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Thread.LastTypedAt (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId))
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V397.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V397.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V397.Id.Id Evergreen.V397.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V397.GuildName.GuildName
    , owner : Evergreen.V397.Id.Id Evergreen.V397.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V397.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V397.Message.Message Evergreen.V397.Id.ChannelMessageId (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId))
    , permissionOverwrites : List Evergreen.V397.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V397.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V397.MembersAndOwner.MembersAndOwner
            (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V397.Discord.Id Evergreen.V397.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V397.NonemptyDict.NonemptyDict
            (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V397.Message.Message Evergreen.V397.Id.ChannelMessageId (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V397.Discord.PartialUser
        , icon : Maybe Evergreen.V397.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V397.Discord.User
        , linkedTo : Evergreen.V397.Id.Id Evergreen.V397.Id.UserId
        , icon : Maybe Evergreen.V397.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V397.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V397.Discord.User
        , linkedTo : Evergreen.V397.Id.Id Evergreen.V397.Id.UserId
        , icon : Maybe Evergreen.V397.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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
    { users : AdminDataStatus (Evergreen.V397.NonemptyDict.NonemptyDict (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Evergreen.V397.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V397.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V397.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V397.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) AdminData_DiscordGuild)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , logs : Evergreen.V397.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V397.SessionIdHash.SessionIdHash, Evergreen.V397.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V397.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V397.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , invalidChannelNames : List AdminData_InvalidChannelName
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , orphanedFiles : AdminDataStatus (SeqDict.SeqDict Evergreen.V397.FileStatus.FileHash Evergreen.V397.FileStatus.BackendFileData)
    , deleteOrphanedFiles : DeleteOrphanedFilesStatus
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V397.SessionIdHash.SessionIdHash Evergreen.V397.UserSession.UserSession)
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Evergreen.V397.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId) Evergreen.V397.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V397.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V397.SessionIdHash.SessionIdHash Evergreen.V397.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V397.TextEditor.LocalState
    , calls : Evergreen.V397.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V397.Id.Id Evergreen.V397.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V397.Id.Id Evergreen.V397.Id.UserId
    , name : Evergreen.V397.ChannelName.ChannelName
    , description : Evergreen.V397.ChannelDescription.ChannelDescription
    , messages : Evergreen.V397.IdArray.IdArray Evergreen.V397.Id.ChannelMessageId (Evergreen.V397.Message.Message Evergreen.V397.Id.ChannelMessageId (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId))
    , status : ChannelStatus
    , threads : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) Evergreen.V397.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V397.Drawing.Drawing (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) Evergreen.V397.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V397.Id.Id Evergreen.V397.Id.UserId
    , name : Evergreen.V397.GuildName.GuildName
    , icon : Maybe Evergreen.V397.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId) BackendChannel
    , membersAndOwner : Evergreen.V397.MembersAndOwner.MembersAndOwner (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) GuildMember
    , bannedUsers : SeqSet.SeqSet (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId)
    , invites :
        SeqDict.SeqDict
            (Evergreen.V397.SecretId.SecretId Evergreen.V397.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V397.Id.Id Evergreen.V397.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Thread.LastTypedAt (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId))
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V397.ChannelName.ChannelName
    , description : Evergreen.V397.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V397.IdArray.IdArray Evergreen.V397.Id.ChannelMessageId (Evergreen.V397.Message.Message Evergreen.V397.Id.ChannelMessageId (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId))
    , status : ChannelStatus
    , linkedMessageIds : Evergreen.V397.OneToOne.OneToOne (Evergreen.V397.Discord.Id Evergreen.V397.Discord.MessageId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) Evergreen.V397.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V397.Drawing.Drawing (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId))
    , permissionOverwrites : List Evergreen.V397.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V397.GuildName.GuildName
    , icon : Maybe Evergreen.V397.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V397.MembersAndOwner.MembersAndOwner
            (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V397.Discord.Id Evergreen.V397.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V397.Id.Id Evergreen.V397.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V397.Id.Id Evergreen.V397.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Thread.LastTypedAt (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId))
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId
    , messages : List Evergreen.V397.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V397.Discord.Message
    , threads : List DiscordThreadReload
    }
