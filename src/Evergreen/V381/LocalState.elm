module Evergreen.V381.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V381.BackendMsgLog
import Evergreen.V381.Call
import Evergreen.V381.ChannelDescription
import Evergreen.V381.ChannelName
import Evergreen.V381.Discord
import Evergreen.V381.DiscordUserData
import Evergreen.V381.DmChannel
import Evergreen.V381.DmChannelId
import Evergreen.V381.Drawing
import Evergreen.V381.FileStatus
import Evergreen.V381.Game
import Evergreen.V381.GuildName
import Evergreen.V381.Id
import Evergreen.V381.IdArray
import Evergreen.V381.Log
import Evergreen.V381.MembersAndOwner
import Evergreen.V381.Message
import Evergreen.V381.MessageArray
import Evergreen.V381.NonemptyDict
import Evergreen.V381.OneToOne
import Evergreen.V381.Pagination
import Evergreen.V381.Postmark
import Evergreen.V381.SecretId
import Evergreen.V381.SessionIdHash
import Evergreen.V381.Slack
import Evergreen.V381.TextEditor
import Evergreen.V381.Thread
import Evergreen.V381.ToBackendLog
import Evergreen.V381.User
import Evergreen.V381.UserSession
import Evergreen.V381.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V381.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V381.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V381.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V381.Call.RemoteCallData
    , currentlyViewing : Evergreen.V381.UserSession.Viewing
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
    , archivedBy : Evergreen.V381.Id.Id Evergreen.V381.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V381.Id.Id Evergreen.V381.Id.UserId
    , name : Evergreen.V381.ChannelName.ChannelName
    , description : Evergreen.V381.ChannelDescription.ChannelDescription
    , messages : Evergreen.V381.MessageArray.MessageArray Evergreen.V381.Id.ChannelMessageId (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)
    , visibleMessages : Evergreen.V381.VisibleMessages.VisibleMessages Evergreen.V381.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) (Evergreen.V381.Thread.LastTypedAt Evergreen.V381.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) Evergreen.V381.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V381.Drawing.Drawing (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) Evergreen.V381.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V381.Id.Id Evergreen.V381.Id.UserId
    , name : Evergreen.V381.GuildName.GuildName
    , icon : Maybe Evergreen.V381.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V381.MembersAndOwner.MembersAndOwner
            (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V381.SecretId.SecretId Evergreen.V381.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V381.Id.Id Evergreen.V381.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V381.ChannelName.ChannelName
    , description : Evergreen.V381.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V381.MessageArray.MessageArray Evergreen.V381.Id.ChannelMessageId (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId)
    , visibleMessages : Evergreen.V381.VisibleMessages.VisibleMessages Evergreen.V381.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Thread.LastTypedAt Evergreen.V381.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) Evergreen.V381.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V381.Drawing.Drawing (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId))
    , permissionOverwrites : List Evergreen.V381.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V381.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V381.GuildName.GuildName
    , icon : Maybe Evergreen.V381.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V381.MembersAndOwner.MembersAndOwner
            (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V381.Discord.Id Evergreen.V381.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V381.Id.Id Evergreen.V381.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V381.Id.Id Evergreen.V381.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V381.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V381.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V381.Id.Id Evergreen.V381.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V381.GuildName.GuildName
    , owner : Evergreen.V381.Id.Id Evergreen.V381.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V381.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V381.Message.Message Evergreen.V381.Id.ChannelMessageId (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId))
    , permissionOverwrites : List Evergreen.V381.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V381.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V381.MembersAndOwner.MembersAndOwner
            (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V381.Discord.Id Evergreen.V381.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V381.NonemptyDict.NonemptyDict
            (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V381.Message.Message Evergreen.V381.Id.ChannelMessageId (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V381.Discord.PartialUser
        , icon : Maybe Evergreen.V381.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V381.Discord.User
        , linkedTo : Evergreen.V381.Id.Id Evergreen.V381.Id.UserId
        , icon : Maybe Evergreen.V381.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V381.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V381.Discord.User
        , linkedTo : Evergreen.V381.Id.Id Evergreen.V381.Id.UserId
        , icon : Maybe Evergreen.V381.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type AdminDataStatus a
    = AdminDataNotLoaded
    | AdminDataLoading
    | AdminDataLoaded a


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : AdminDataStatus (Evergreen.V381.NonemptyDict.NonemptyDict (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Evergreen.V381.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V381.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V381.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V381.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) AdminData_DiscordGuild)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V381.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V381.SessionIdHash.SessionIdHash, Evergreen.V381.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V381.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V381.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V381.SessionIdHash.SessionIdHash Evergreen.V381.UserSession.UserSession)
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Evergreen.V381.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId) Evergreen.V381.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V381.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V381.SessionIdHash.SessionIdHash Evergreen.V381.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V381.TextEditor.LocalState
    , calls : Evergreen.V381.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V381.Id.Id Evergreen.V381.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V381.Id.Id Evergreen.V381.Id.UserId
    , name : Evergreen.V381.ChannelName.ChannelName
    , description : Evergreen.V381.ChannelDescription.ChannelDescription
    , messages : Evergreen.V381.IdArray.IdArray Evergreen.V381.Id.ChannelMessageId (Evergreen.V381.Message.Message Evergreen.V381.Id.ChannelMessageId (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) (Evergreen.V381.Thread.LastTypedAt Evergreen.V381.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) Evergreen.V381.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V381.Drawing.Drawing (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) Evergreen.V381.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V381.Id.Id Evergreen.V381.Id.UserId
    , name : Evergreen.V381.GuildName.GuildName
    , icon : Maybe Evergreen.V381.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V381.MembersAndOwner.MembersAndOwner
            (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V381.SecretId.SecretId Evergreen.V381.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V381.Id.Id Evergreen.V381.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V381.ChannelName.ChannelName
    , description : Evergreen.V381.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V381.IdArray.IdArray Evergreen.V381.Id.ChannelMessageId (Evergreen.V381.Message.Message Evergreen.V381.Id.ChannelMessageId (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Thread.LastTypedAt Evergreen.V381.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V381.OneToOne.OneToOne (Evergreen.V381.Discord.Id Evergreen.V381.Discord.MessageId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) Evergreen.V381.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V381.Drawing.Drawing (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId))
    , permissionOverwrites : List Evergreen.V381.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V381.GuildName.GuildName
    , icon : Maybe Evergreen.V381.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V381.MembersAndOwner.MembersAndOwner
            (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V381.Discord.Id Evergreen.V381.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V381.Id.Id Evergreen.V381.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V381.Id.Id Evergreen.V381.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId
    , messages : List Evergreen.V381.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V381.Discord.Message
    , threads : List DiscordThreadReload
    }
