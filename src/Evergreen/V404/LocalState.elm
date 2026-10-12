module Evergreen.V404.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V404.BackendMsgLog
import Evergreen.V404.Call
import Evergreen.V404.ChannelDescription
import Evergreen.V404.ChannelName
import Evergreen.V404.Discord
import Evergreen.V404.DiscordUserData
import Evergreen.V404.DmChannel
import Evergreen.V404.DmChannelId
import Evergreen.V404.Drawing
import Evergreen.V404.FileStatus
import Evergreen.V404.Game
import Evergreen.V404.GuildName
import Evergreen.V404.Id
import Evergreen.V404.IdArray
import Evergreen.V404.Log
import Evergreen.V404.MembersAndOwner
import Evergreen.V404.Message
import Evergreen.V404.MessageArray
import Evergreen.V404.NonemptyDict
import Evergreen.V404.OneToOne
import Evergreen.V404.Pagination
import Evergreen.V404.Postmark
import Evergreen.V404.SecretId
import Evergreen.V404.SessionIdHash
import Evergreen.V404.Slack
import Evergreen.V404.TextEditor
import Evergreen.V404.Thread
import Evergreen.V404.ToBackendLog
import Evergreen.V404.User
import Evergreen.V404.UserSession
import Evergreen.V404.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V404.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V404.Discord.Id Evergreen.V404.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V404.Log.Log
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V404.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V404.Call.RemoteCallData
    , currentlyViewing : Evergreen.V404.UserSession.Viewing
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
    , archivedBy : Evergreen.V404.Id.Id Evergreen.V404.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V404.Id.Id Evergreen.V404.Id.UserId
    , name : Evergreen.V404.ChannelName.ChannelName
    , description : Evergreen.V404.ChannelDescription.ChannelDescription
    , messages : Evergreen.V404.MessageArray.MessageArray Evergreen.V404.Id.ChannelMessageId (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelId)
    , visibleMessages : Evergreen.V404.VisibleMessages.VisibleMessages Evergreen.V404.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , threads : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId) Evergreen.V404.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V404.Drawing.Drawing (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId) Evergreen.V404.Game.MatchData
    }


type alias GuildMember =
    { joinedAt : Effect.Time.Posix
    , lastPostedAt : Maybe Effect.Time.Posix
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V404.Id.Id Evergreen.V404.Id.UserId
    , name : Evergreen.V404.GuildName.GuildName
    , icon : Maybe Evergreen.V404.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelId) FrontendChannel
    , membersAndOwner : Evergreen.V404.MembersAndOwner.MembersAndOwner (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) GuildMember
    , invites :
        SeqDict.SeqDict
            (Evergreen.V404.SecretId.SecretId Evergreen.V404.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V404.Id.Id Evergreen.V404.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) (Evergreen.V404.Thread.LastTypedAt (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelId))
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V404.ChannelName.ChannelName
    , description : Evergreen.V404.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V404.MessageArray.MessageArray Evergreen.V404.Id.ChannelMessageId (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId)
    , visibleMessages : Evergreen.V404.VisibleMessages.VisibleMessages Evergreen.V404.Id.ChannelMessageId
    , threads : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId) Evergreen.V404.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V404.Drawing.Drawing (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId))
    , permissionOverwrites : List Evergreen.V404.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V404.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V404.GuildName.GuildName
    , icon : Maybe Evergreen.V404.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V404.MembersAndOwner.MembersAndOwner
            (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V404.Discord.Id Evergreen.V404.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V404.Id.Id Evergreen.V404.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V404.Id.Id Evergreen.V404.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V404.Discord.Id Evergreen.V404.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) (Evergreen.V404.Thread.LastTypedAt (Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId))
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V404.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V404.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V404.Id.Id Evergreen.V404.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V404.GuildName.GuildName
    , owner : Evergreen.V404.Id.Id Evergreen.V404.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V404.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V404.Message.Message Evergreen.V404.Id.ChannelMessageId (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId))
    , permissionOverwrites : List Evergreen.V404.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V404.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V404.MembersAndOwner.MembersAndOwner
            (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V404.Discord.Id Evergreen.V404.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V404.Discord.Id Evergreen.V404.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V404.NonemptyDict.NonemptyDict
            (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V404.Message.Message Evergreen.V404.Id.ChannelMessageId (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V404.Discord.PartialUser
        , icon : Maybe Evergreen.V404.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V404.Discord.User
        , linkedTo : Evergreen.V404.Id.Id Evergreen.V404.Id.UserId
        , icon : Maybe Evergreen.V404.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V404.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V404.Discord.User
        , linkedTo : Evergreen.V404.Id.Id Evergreen.V404.Id.UserId
        , icon : Maybe Evergreen.V404.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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
    { users : AdminDataStatus (Evergreen.V404.NonemptyDict.NonemptyDict (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) Evergreen.V404.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V404.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V404.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V404.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V404.Discord.Id Evergreen.V404.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId) AdminData_DiscordGuild)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , logs : Evergreen.V404.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V404.SessionIdHash.SessionIdHash, Evergreen.V404.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V404.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V404.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , orphanedFiles : AdminDataStatus (SeqDict.SeqDict Evergreen.V404.FileStatus.FileHash Evergreen.V404.FileStatus.BackendFileData)
    , deleteOrphanedFiles : DeleteOrphanedFilesStatus
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V404.SessionIdHash.SessionIdHash Evergreen.V404.UserSession.UserSession)
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) Evergreen.V404.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V404.Discord.Id Evergreen.V404.Discord.PrivateChannelId) Evergreen.V404.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V404.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V404.SessionIdHash.SessionIdHash Evergreen.V404.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V404.TextEditor.LocalState
    , calls : Evergreen.V404.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V404.Id.Id Evergreen.V404.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V404.Id.Id Evergreen.V404.Id.UserId
    , name : Evergreen.V404.ChannelName.ChannelName
    , description : Evergreen.V404.ChannelDescription.ChannelDescription
    , messages : Evergreen.V404.IdArray.IdArray Evergreen.V404.Id.ChannelMessageId (Evergreen.V404.Message.Message Evergreen.V404.Id.ChannelMessageId (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelId))
    , status : ChannelStatus
    , threads : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId) Evergreen.V404.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V404.Drawing.Drawing (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId) Evergreen.V404.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V404.Id.Id Evergreen.V404.Id.UserId
    , name : Evergreen.V404.GuildName.GuildName
    , icon : Maybe Evergreen.V404.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelId) BackendChannel
    , membersAndOwner : Evergreen.V404.MembersAndOwner.MembersAndOwner (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) GuildMember
    , bannedUsers : SeqSet.SeqSet (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId)
    , invites :
        SeqDict.SeqDict
            (Evergreen.V404.SecretId.SecretId Evergreen.V404.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V404.Id.Id Evergreen.V404.Id.UserId
            }
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) (Evergreen.V404.Thread.LastTypedAt (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelId))
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V404.ChannelName.ChannelName
    , description : Evergreen.V404.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V404.IdArray.IdArray Evergreen.V404.Id.ChannelMessageId (Evergreen.V404.Message.Message Evergreen.V404.Id.ChannelMessageId (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId))
    , status : ChannelStatus
    , linkedMessageIds : Evergreen.V404.OneToOne.OneToOne (Evergreen.V404.Discord.Id Evergreen.V404.Discord.MessageId) (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId) Evergreen.V404.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V404.Drawing.Drawing (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId))
    , permissionOverwrites : List Evergreen.V404.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V404.GuildName.GuildName
    , icon : Maybe Evergreen.V404.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V404.MembersAndOwner.MembersAndOwner
            (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V404.Discord.Id Evergreen.V404.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V404.Id.Id Evergreen.V404.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V404.Id.Id Evergreen.V404.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V404.Discord.Id Evergreen.V404.Discord.RoleId) DiscordRole
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) (Evergreen.V404.Thread.LastTypedAt (Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId))
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId
    , messages : List Evergreen.V404.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V404.Discord.Message
    , threads : List DiscordThreadReload
    }
