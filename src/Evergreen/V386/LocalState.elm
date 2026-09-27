module Evergreen.V386.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V386.BackendMsgLog
import Evergreen.V386.Call
import Evergreen.V386.ChannelDescription
import Evergreen.V386.ChannelName
import Evergreen.V386.Discord
import Evergreen.V386.DiscordUserData
import Evergreen.V386.DmChannel
import Evergreen.V386.DmChannelId
import Evergreen.V386.Drawing
import Evergreen.V386.FileStatus
import Evergreen.V386.Game
import Evergreen.V386.GuildName
import Evergreen.V386.Id
import Evergreen.V386.IdArray
import Evergreen.V386.Log
import Evergreen.V386.MembersAndOwner
import Evergreen.V386.Message
import Evergreen.V386.MessageArray
import Evergreen.V386.NonemptyDict
import Evergreen.V386.OneToOne
import Evergreen.V386.Pagination
import Evergreen.V386.Postmark
import Evergreen.V386.SecretId
import Evergreen.V386.SessionIdHash
import Evergreen.V386.Slack
import Evergreen.V386.TextEditor
import Evergreen.V386.Thread
import Evergreen.V386.ToBackendLog
import Evergreen.V386.User
import Evergreen.V386.UserSession
import Evergreen.V386.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V386.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V386.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V386.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V386.Call.RemoteCallData
    , currentlyViewing : Evergreen.V386.UserSession.Viewing
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
    , archivedBy : Evergreen.V386.Id.Id Evergreen.V386.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V386.Id.Id Evergreen.V386.Id.UserId
    , name : Evergreen.V386.ChannelName.ChannelName
    , description : Evergreen.V386.ChannelDescription.ChannelDescription
    , messages : Evergreen.V386.MessageArray.MessageArray Evergreen.V386.Id.ChannelMessageId (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId)
    , visibleMessages : Evergreen.V386.VisibleMessages.VisibleMessages Evergreen.V386.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Thread.LastTypedAt Evergreen.V386.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) Evergreen.V386.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V386.Drawing.Drawing (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) Evergreen.V386.Game.MatchData
    }


type alias GuildMember =
    { joinedAt : Effect.Time.Posix
    , lastPostedAt : Maybe Effect.Time.Posix
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V386.Id.Id Evergreen.V386.Id.UserId
    , name : Evergreen.V386.GuildName.GuildName
    , icon : Maybe Evergreen.V386.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId) FrontendChannel
    , membersAndOwner : Evergreen.V386.MembersAndOwner.MembersAndOwner (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) GuildMember
    , invites :
        SeqDict.SeqDict
            (Evergreen.V386.SecretId.SecretId Evergreen.V386.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V386.Id.Id Evergreen.V386.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V386.ChannelName.ChannelName
    , description : Evergreen.V386.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V386.MessageArray.MessageArray Evergreen.V386.Id.ChannelMessageId (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId)
    , visibleMessages : Evergreen.V386.VisibleMessages.VisibleMessages Evergreen.V386.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Thread.LastTypedAt Evergreen.V386.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) Evergreen.V386.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V386.Drawing.Drawing (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId))
    , permissionOverwrites : List Evergreen.V386.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V386.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V386.GuildName.GuildName
    , icon : Maybe Evergreen.V386.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V386.MembersAndOwner.MembersAndOwner
            (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V386.Discord.Id Evergreen.V386.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V386.Id.Id Evergreen.V386.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V386.Id.Id Evergreen.V386.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V386.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V386.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V386.Id.Id Evergreen.V386.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V386.GuildName.GuildName
    , owner : Evergreen.V386.Id.Id Evergreen.V386.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V386.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V386.Message.Message Evergreen.V386.Id.ChannelMessageId (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId))
    , permissionOverwrites : List Evergreen.V386.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V386.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V386.MembersAndOwner.MembersAndOwner
            (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V386.Discord.Id Evergreen.V386.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V386.NonemptyDict.NonemptyDict
            (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V386.Message.Message Evergreen.V386.Id.ChannelMessageId (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V386.Discord.PartialUser
        , icon : Maybe Evergreen.V386.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V386.Discord.User
        , linkedTo : Evergreen.V386.Id.Id Evergreen.V386.Id.UserId
        , icon : Maybe Evergreen.V386.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V386.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V386.Discord.User
        , linkedTo : Evergreen.V386.Id.Id Evergreen.V386.Id.UserId
        , icon : Maybe Evergreen.V386.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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


type alias AdminData =
    { users : AdminDataStatus (Evergreen.V386.NonemptyDict.NonemptyDict (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Evergreen.V386.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V386.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V386.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V386.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) AdminData_DiscordGuild)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V386.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V386.SessionIdHash.SessionIdHash, Evergreen.V386.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V386.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V386.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , orphanedFiles : AdminDataStatus (SeqDict.SeqDict Evergreen.V386.FileStatus.FileHash Evergreen.V386.FileStatus.BackendFileData)
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V386.SessionIdHash.SessionIdHash Evergreen.V386.UserSession.UserSession)
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Evergreen.V386.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId) Evergreen.V386.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V386.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V386.SessionIdHash.SessionIdHash Evergreen.V386.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V386.TextEditor.LocalState
    , calls : Evergreen.V386.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V386.Id.Id Evergreen.V386.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V386.Id.Id Evergreen.V386.Id.UserId
    , name : Evergreen.V386.ChannelName.ChannelName
    , description : Evergreen.V386.ChannelDescription.ChannelDescription
    , messages : Evergreen.V386.IdArray.IdArray Evergreen.V386.Id.ChannelMessageId (Evergreen.V386.Message.Message Evergreen.V386.Id.ChannelMessageId (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Thread.LastTypedAt Evergreen.V386.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) Evergreen.V386.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V386.Drawing.Drawing (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) Evergreen.V386.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V386.Id.Id Evergreen.V386.Id.UserId
    , name : Evergreen.V386.GuildName.GuildName
    , icon : Maybe Evergreen.V386.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId) BackendChannel
    , membersAndOwner : Evergreen.V386.MembersAndOwner.MembersAndOwner (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) GuildMember
    , bannedUsers : SeqSet.SeqSet (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId)
    , invites :
        SeqDict.SeqDict
            (Evergreen.V386.SecretId.SecretId Evergreen.V386.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V386.Id.Id Evergreen.V386.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V386.ChannelName.ChannelName
    , description : Evergreen.V386.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V386.IdArray.IdArray Evergreen.V386.Id.ChannelMessageId (Evergreen.V386.Message.Message Evergreen.V386.Id.ChannelMessageId (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Thread.LastTypedAt Evergreen.V386.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V386.OneToOne.OneToOne (Evergreen.V386.Discord.Id Evergreen.V386.Discord.MessageId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) Evergreen.V386.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V386.Drawing.Drawing (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId))
    , permissionOverwrites : List Evergreen.V386.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V386.GuildName.GuildName
    , icon : Maybe Evergreen.V386.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V386.MembersAndOwner.MembersAndOwner
            (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V386.Discord.Id Evergreen.V386.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V386.Id.Id Evergreen.V386.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V386.Id.Id Evergreen.V386.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId
    , messages : List Evergreen.V386.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V386.Discord.Message
    , threads : List DiscordThreadReload
    }
