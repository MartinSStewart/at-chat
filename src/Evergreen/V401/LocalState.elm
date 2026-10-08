module Evergreen.V401.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V401.BackendMsgLog
import Evergreen.V401.Call
import Evergreen.V401.ChannelDescription
import Evergreen.V401.ChannelName
import Evergreen.V401.Discord
import Evergreen.V401.DiscordUserData
import Evergreen.V401.DmChannel
import Evergreen.V401.DmChannelId
import Evergreen.V401.Drawing
import Evergreen.V401.FileStatus
import Evergreen.V401.Game
import Evergreen.V401.GuildName
import Evergreen.V401.Id
import Evergreen.V401.IdArray
import Evergreen.V401.Log
import Evergreen.V401.MembersAndOwner
import Evergreen.V401.Message
import Evergreen.V401.MessageArray
import Evergreen.V401.NonemptyDict
import Evergreen.V401.OneToOne
import Evergreen.V401.Pagination
import Evergreen.V401.Postmark
import Evergreen.V401.SecretId
import Evergreen.V401.SessionIdHash
import Evergreen.V401.Slack
import Evergreen.V401.TextEditor
import Evergreen.V401.Thread
import Evergreen.V401.ToBackendLog
import Evergreen.V401.User
import Evergreen.V401.UserSession
import Evergreen.V401.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V401.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V401.Log.Log
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V401.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V401.Call.RemoteCallData
    , currentlyViewing : Evergreen.V401.UserSession.Viewing
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
    , archivedBy : Evergreen.V401.Id.Id Evergreen.V401.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V401.Id.Id Evergreen.V401.Id.UserId
    , name : Evergreen.V401.ChannelName.ChannelName
    , description : Evergreen.V401.ChannelDescription.ChannelDescription
    , messages : Evergreen.V401.MessageArray.MessageArray Evergreen.V401.Id.ChannelMessageId (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId)
    , visibleMessages : Evergreen.V401.VisibleMessages.VisibleMessages Evergreen.V401.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , threads : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) Evergreen.V401.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V401.Drawing.Drawing (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) Evergreen.V401.Game.MatchData
    }


type alias GuildMember =
    { joinedAt : Effect.Time.Posix
    , lastPostedAt : Maybe Effect.Time.Posix
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V401.Id.Id Evergreen.V401.Id.UserId
    , name : Evergreen.V401.GuildName.GuildName
    , icon : Maybe Evergreen.V401.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId) FrontendChannel
    , membersAndOwner : Evergreen.V401.MembersAndOwner.MembersAndOwner (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) GuildMember
    , invites :
        SeqDict.SeqDict
            (Evergreen.V401.SecretId.SecretId Evergreen.V401.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V401.Id.Id Evergreen.V401.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Thread.LastTypedAt (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId))
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V401.ChannelName.ChannelName
    , description : Evergreen.V401.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V401.MessageArray.MessageArray Evergreen.V401.Id.ChannelMessageId (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId)
    , visibleMessages : Evergreen.V401.VisibleMessages.VisibleMessages Evergreen.V401.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) Evergreen.V401.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V401.Drawing.Drawing (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId))
    , permissionOverwrites : List Evergreen.V401.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V401.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V401.GuildName.GuildName
    , icon : Maybe Evergreen.V401.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V401.MembersAndOwner.MembersAndOwner
            (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V401.Discord.Id Evergreen.V401.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V401.Id.Id Evergreen.V401.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V401.Id.Id Evergreen.V401.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Thread.LastTypedAt (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId))
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V401.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V401.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V401.Id.Id Evergreen.V401.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V401.GuildName.GuildName
    , owner : Evergreen.V401.Id.Id Evergreen.V401.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V401.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V401.Message.Message Evergreen.V401.Id.ChannelMessageId (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId))
    , permissionOverwrites : List Evergreen.V401.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V401.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V401.MembersAndOwner.MembersAndOwner
            (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V401.Discord.Id Evergreen.V401.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V401.NonemptyDict.NonemptyDict
            (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V401.Message.Message Evergreen.V401.Id.ChannelMessageId (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V401.Discord.PartialUser
        , icon : Maybe Evergreen.V401.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V401.Discord.User
        , linkedTo : Evergreen.V401.Id.Id Evergreen.V401.Id.UserId
        , icon : Maybe Evergreen.V401.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V401.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V401.Discord.User
        , linkedTo : Evergreen.V401.Id.Id Evergreen.V401.Id.UserId
        , icon : Maybe Evergreen.V401.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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
    { users : AdminDataStatus (Evergreen.V401.NonemptyDict.NonemptyDict (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Evergreen.V401.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V401.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V401.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V401.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) AdminData_DiscordGuild)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , logs : Evergreen.V401.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V401.SessionIdHash.SessionIdHash, Evergreen.V401.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V401.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V401.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , orphanedFiles : AdminDataStatus (SeqDict.SeqDict Evergreen.V401.FileStatus.FileHash Evergreen.V401.FileStatus.BackendFileData)
    , deleteOrphanedFiles : DeleteOrphanedFilesStatus
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V401.SessionIdHash.SessionIdHash Evergreen.V401.UserSession.UserSession)
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Evergreen.V401.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId) Evergreen.V401.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V401.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V401.SessionIdHash.SessionIdHash Evergreen.V401.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V401.TextEditor.LocalState
    , calls : Evergreen.V401.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V401.Id.Id Evergreen.V401.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V401.Id.Id Evergreen.V401.Id.UserId
    , name : Evergreen.V401.ChannelName.ChannelName
    , description : Evergreen.V401.ChannelDescription.ChannelDescription
    , messages : Evergreen.V401.IdArray.IdArray Evergreen.V401.Id.ChannelMessageId (Evergreen.V401.Message.Message Evergreen.V401.Id.ChannelMessageId (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId))
    , status : ChannelStatus
    , threads : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) Evergreen.V401.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V401.Drawing.Drawing (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) Evergreen.V401.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V401.Id.Id Evergreen.V401.Id.UserId
    , name : Evergreen.V401.GuildName.GuildName
    , icon : Maybe Evergreen.V401.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId) BackendChannel
    , membersAndOwner : Evergreen.V401.MembersAndOwner.MembersAndOwner (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) GuildMember
    , bannedUsers : SeqSet.SeqSet (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId)
    , invites :
        SeqDict.SeqDict
            (Evergreen.V401.SecretId.SecretId Evergreen.V401.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V401.Id.Id Evergreen.V401.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Thread.LastTypedAt (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId))
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V401.ChannelName.ChannelName
    , description : Evergreen.V401.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V401.IdArray.IdArray Evergreen.V401.Id.ChannelMessageId (Evergreen.V401.Message.Message Evergreen.V401.Id.ChannelMessageId (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId))
    , status : ChannelStatus
    , linkedMessageIds : Evergreen.V401.OneToOne.OneToOne (Evergreen.V401.Discord.Id Evergreen.V401.Discord.MessageId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) Evergreen.V401.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V401.Drawing.Drawing (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId))
    , permissionOverwrites : List Evergreen.V401.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V401.GuildName.GuildName
    , icon : Maybe Evergreen.V401.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V401.MembersAndOwner.MembersAndOwner
            (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V401.Discord.Id Evergreen.V401.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V401.Id.Id Evergreen.V401.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V401.Id.Id Evergreen.V401.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Thread.LastTypedAt (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId))
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId
    , messages : List Evergreen.V401.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V401.Discord.Message
    , threads : List DiscordThreadReload
    }
