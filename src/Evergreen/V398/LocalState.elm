module Evergreen.V398.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V398.BackendMsgLog
import Evergreen.V398.Call
import Evergreen.V398.ChannelDescription
import Evergreen.V398.ChannelName
import Evergreen.V398.Discord
import Evergreen.V398.DiscordUserData
import Evergreen.V398.DmChannel
import Evergreen.V398.DmChannelId
import Evergreen.V398.Drawing
import Evergreen.V398.FileStatus
import Evergreen.V398.Game
import Evergreen.V398.GuildName
import Evergreen.V398.Id
import Evergreen.V398.IdArray
import Evergreen.V398.Log
import Evergreen.V398.MembersAndOwner
import Evergreen.V398.Message
import Evergreen.V398.MessageArray
import Evergreen.V398.NonemptyDict
import Evergreen.V398.OneToOne
import Evergreen.V398.Pagination
import Evergreen.V398.Postmark
import Evergreen.V398.SecretId
import Evergreen.V398.SessionIdHash
import Evergreen.V398.Slack
import Evergreen.V398.TextEditor
import Evergreen.V398.Thread
import Evergreen.V398.ToBackendLog
import Evergreen.V398.User
import Evergreen.V398.UserSession
import Evergreen.V398.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V398.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V398.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V398.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V398.Call.RemoteCallData
    , currentlyViewing : Evergreen.V398.UserSession.Viewing
    }


type BackupContents
    = FullBackup
    | SubsetBackup


type alias LastBackup =
    { createdAt : Effect.Time.Posix
    , contents : BackupContents
    }


type AdminData_InvalidChannelNameGuild
    = InvalidChannelName_Guild Evergreen.V398.GuildName.GuildName
    | InvalidChannelName_DeletedGuild Evergreen.V398.GuildName.GuildName
    | InvalidChannelName_DiscordGuild Evergreen.V398.GuildName.GuildName


type alias AdminData_InvalidChannelName =
    { guild : AdminData_InvalidChannelNameGuild
    , channelName : Evergreen.V398.ChannelName.ChannelName
    , error : String
    }


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V398.Id.Id Evergreen.V398.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V398.Id.Id Evergreen.V398.Id.UserId
    , name : Evergreen.V398.ChannelName.ChannelName
    , description : Evergreen.V398.ChannelDescription.ChannelDescription
    , messages : Evergreen.V398.MessageArray.MessageArray Evergreen.V398.Id.ChannelMessageId (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId)
    , visibleMessages : Evergreen.V398.VisibleMessages.VisibleMessages Evergreen.V398.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , threads : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) Evergreen.V398.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V398.Drawing.Drawing (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) Evergreen.V398.Game.MatchData
    }


type alias GuildMember =
    { joinedAt : Effect.Time.Posix
    , lastPostedAt : Maybe Effect.Time.Posix
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V398.Id.Id Evergreen.V398.Id.UserId
    , name : Evergreen.V398.GuildName.GuildName
    , icon : Maybe Evergreen.V398.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId) FrontendChannel
    , membersAndOwner : Evergreen.V398.MembersAndOwner.MembersAndOwner (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) GuildMember
    , invites :
        SeqDict.SeqDict
            (Evergreen.V398.SecretId.SecretId Evergreen.V398.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V398.Id.Id Evergreen.V398.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Thread.LastTypedAt (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId))
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V398.ChannelName.ChannelName
    , description : Evergreen.V398.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V398.MessageArray.MessageArray Evergreen.V398.Id.ChannelMessageId (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId)
    , visibleMessages : Evergreen.V398.VisibleMessages.VisibleMessages Evergreen.V398.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) Evergreen.V398.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V398.Drawing.Drawing (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId))
    , permissionOverwrites : List Evergreen.V398.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V398.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V398.GuildName.GuildName
    , icon : Maybe Evergreen.V398.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V398.MembersAndOwner.MembersAndOwner
            (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V398.Discord.Id Evergreen.V398.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V398.Id.Id Evergreen.V398.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V398.Id.Id Evergreen.V398.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Thread.LastTypedAt (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId))
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V398.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V398.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V398.Id.Id Evergreen.V398.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V398.GuildName.GuildName
    , owner : Evergreen.V398.Id.Id Evergreen.V398.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V398.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V398.Message.Message Evergreen.V398.Id.ChannelMessageId (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId))
    , permissionOverwrites : List Evergreen.V398.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V398.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V398.MembersAndOwner.MembersAndOwner
            (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V398.Discord.Id Evergreen.V398.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V398.NonemptyDict.NonemptyDict
            (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V398.Message.Message Evergreen.V398.Id.ChannelMessageId (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V398.Discord.PartialUser
        , icon : Maybe Evergreen.V398.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V398.Discord.User
        , linkedTo : Evergreen.V398.Id.Id Evergreen.V398.Id.UserId
        , icon : Maybe Evergreen.V398.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V398.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V398.Discord.User
        , linkedTo : Evergreen.V398.Id.Id Evergreen.V398.Id.UserId
        , icon : Maybe Evergreen.V398.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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
    { users : AdminDataStatus (Evergreen.V398.NonemptyDict.NonemptyDict (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Evergreen.V398.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V398.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V398.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V398.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) AdminData_DiscordGuild)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , logs : Evergreen.V398.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V398.SessionIdHash.SessionIdHash, Evergreen.V398.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V398.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V398.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , invalidChannelNames : List AdminData_InvalidChannelName
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , orphanedFiles : AdminDataStatus (SeqDict.SeqDict Evergreen.V398.FileStatus.FileHash Evergreen.V398.FileStatus.BackendFileData)
    , deleteOrphanedFiles : DeleteOrphanedFilesStatus
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V398.SessionIdHash.SessionIdHash Evergreen.V398.UserSession.UserSession)
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Evergreen.V398.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId) Evergreen.V398.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V398.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V398.SessionIdHash.SessionIdHash Evergreen.V398.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V398.TextEditor.LocalState
    , calls : Evergreen.V398.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V398.Id.Id Evergreen.V398.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V398.Id.Id Evergreen.V398.Id.UserId
    , name : Evergreen.V398.ChannelName.ChannelName
    , description : Evergreen.V398.ChannelDescription.ChannelDescription
    , messages : Evergreen.V398.IdArray.IdArray Evergreen.V398.Id.ChannelMessageId (Evergreen.V398.Message.Message Evergreen.V398.Id.ChannelMessageId (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId))
    , status : ChannelStatus
    , threads : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) Evergreen.V398.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V398.Drawing.Drawing (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) Evergreen.V398.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V398.Id.Id Evergreen.V398.Id.UserId
    , name : Evergreen.V398.GuildName.GuildName
    , icon : Maybe Evergreen.V398.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId) BackendChannel
    , membersAndOwner : Evergreen.V398.MembersAndOwner.MembersAndOwner (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) GuildMember
    , bannedUsers : SeqSet.SeqSet (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId)
    , invites :
        SeqDict.SeqDict
            (Evergreen.V398.SecretId.SecretId Evergreen.V398.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V398.Id.Id Evergreen.V398.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Thread.LastTypedAt (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId))
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V398.ChannelName.ChannelName
    , description : Evergreen.V398.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V398.IdArray.IdArray Evergreen.V398.Id.ChannelMessageId (Evergreen.V398.Message.Message Evergreen.V398.Id.ChannelMessageId (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId))
    , status : ChannelStatus
    , linkedMessageIds : Evergreen.V398.OneToOne.OneToOne (Evergreen.V398.Discord.Id Evergreen.V398.Discord.MessageId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) Evergreen.V398.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V398.Drawing.Drawing (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId))
    , permissionOverwrites : List Evergreen.V398.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V398.GuildName.GuildName
    , icon : Maybe Evergreen.V398.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V398.MembersAndOwner.MembersAndOwner
            (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V398.Discord.Id Evergreen.V398.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V398.Id.Id Evergreen.V398.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V398.Id.Id Evergreen.V398.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Thread.LastTypedAt (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId))
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId
    , messages : List Evergreen.V398.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V398.Discord.Message
    , threads : List DiscordThreadReload
    }
