module Evergreen.V384.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V384.BackendMsgLog
import Evergreen.V384.Call
import Evergreen.V384.ChannelDescription
import Evergreen.V384.ChannelName
import Evergreen.V384.Discord
import Evergreen.V384.DiscordUserData
import Evergreen.V384.DmChannel
import Evergreen.V384.DmChannelId
import Evergreen.V384.Drawing
import Evergreen.V384.FileStatus
import Evergreen.V384.Game
import Evergreen.V384.GuildName
import Evergreen.V384.Id
import Evergreen.V384.IdArray
import Evergreen.V384.Log
import Evergreen.V384.MembersAndOwner
import Evergreen.V384.Message
import Evergreen.V384.MessageArray
import Evergreen.V384.NonemptyDict
import Evergreen.V384.OneToOne
import Evergreen.V384.Pagination
import Evergreen.V384.Postmark
import Evergreen.V384.SecretId
import Evergreen.V384.SessionIdHash
import Evergreen.V384.Slack
import Evergreen.V384.TextEditor
import Evergreen.V384.Thread
import Evergreen.V384.ToBackendLog
import Evergreen.V384.User
import Evergreen.V384.UserSession
import Evergreen.V384.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V384.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V384.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V384.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V384.Call.RemoteCallData
    , currentlyViewing : Evergreen.V384.UserSession.Viewing
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
    , archivedBy : Evergreen.V384.Id.Id Evergreen.V384.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V384.Id.Id Evergreen.V384.Id.UserId
    , name : Evergreen.V384.ChannelName.ChannelName
    , description : Evergreen.V384.ChannelDescription.ChannelDescription
    , messages : Evergreen.V384.MessageArray.MessageArray Evergreen.V384.Id.ChannelMessageId (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)
    , visibleMessages : Evergreen.V384.VisibleMessages.VisibleMessages Evergreen.V384.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) (Evergreen.V384.Thread.LastTypedAt Evergreen.V384.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) Evergreen.V384.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V384.Drawing.Drawing (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) Evergreen.V384.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V384.Id.Id Evergreen.V384.Id.UserId
    , name : Evergreen.V384.GuildName.GuildName
    , icon : Maybe Evergreen.V384.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V384.MembersAndOwner.MembersAndOwner
            (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V384.SecretId.SecretId Evergreen.V384.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V384.Id.Id Evergreen.V384.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V384.ChannelName.ChannelName
    , description : Evergreen.V384.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V384.MessageArray.MessageArray Evergreen.V384.Id.ChannelMessageId (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId)
    , visibleMessages : Evergreen.V384.VisibleMessages.VisibleMessages Evergreen.V384.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Thread.LastTypedAt Evergreen.V384.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) Evergreen.V384.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V384.Drawing.Drawing (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId))
    , permissionOverwrites : List Evergreen.V384.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V384.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V384.GuildName.GuildName
    , icon : Maybe Evergreen.V384.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V384.MembersAndOwner.MembersAndOwner
            (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V384.Discord.Id Evergreen.V384.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V384.Id.Id Evergreen.V384.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V384.Id.Id Evergreen.V384.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V384.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V384.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V384.Id.Id Evergreen.V384.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V384.GuildName.GuildName
    , owner : Evergreen.V384.Id.Id Evergreen.V384.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V384.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V384.Message.Message Evergreen.V384.Id.ChannelMessageId (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId))
    , permissionOverwrites : List Evergreen.V384.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V384.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V384.MembersAndOwner.MembersAndOwner
            (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V384.Discord.Id Evergreen.V384.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V384.NonemptyDict.NonemptyDict
            (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V384.Message.Message Evergreen.V384.Id.ChannelMessageId (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V384.Discord.PartialUser
        , icon : Maybe Evergreen.V384.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V384.Discord.User
        , linkedTo : Evergreen.V384.Id.Id Evergreen.V384.Id.UserId
        , icon : Maybe Evergreen.V384.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V384.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V384.Discord.User
        , linkedTo : Evergreen.V384.Id.Id Evergreen.V384.Id.UserId
        , icon : Maybe Evergreen.V384.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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
    { users : AdminDataStatus (Evergreen.V384.NonemptyDict.NonemptyDict (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Evergreen.V384.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V384.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V384.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V384.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) AdminData_DiscordGuild)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V384.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V384.SessionIdHash.SessionIdHash, Evergreen.V384.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V384.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V384.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V384.SessionIdHash.SessionIdHash Evergreen.V384.UserSession.UserSession)
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Evergreen.V384.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId) Evergreen.V384.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V384.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V384.SessionIdHash.SessionIdHash Evergreen.V384.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V384.TextEditor.LocalState
    , calls : Evergreen.V384.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V384.Id.Id Evergreen.V384.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V384.Id.Id Evergreen.V384.Id.UserId
    , name : Evergreen.V384.ChannelName.ChannelName
    , description : Evergreen.V384.ChannelDescription.ChannelDescription
    , messages : Evergreen.V384.IdArray.IdArray Evergreen.V384.Id.ChannelMessageId (Evergreen.V384.Message.Message Evergreen.V384.Id.ChannelMessageId (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) (Evergreen.V384.Thread.LastTypedAt Evergreen.V384.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) Evergreen.V384.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V384.Drawing.Drawing (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) Evergreen.V384.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V384.Id.Id Evergreen.V384.Id.UserId
    , name : Evergreen.V384.GuildName.GuildName
    , icon : Maybe Evergreen.V384.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V384.MembersAndOwner.MembersAndOwner
            (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V384.SecretId.SecretId Evergreen.V384.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V384.Id.Id Evergreen.V384.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V384.ChannelName.ChannelName
    , description : Evergreen.V384.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V384.IdArray.IdArray Evergreen.V384.Id.ChannelMessageId (Evergreen.V384.Message.Message Evergreen.V384.Id.ChannelMessageId (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Thread.LastTypedAt Evergreen.V384.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V384.OneToOne.OneToOne (Evergreen.V384.Discord.Id Evergreen.V384.Discord.MessageId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) Evergreen.V384.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V384.Drawing.Drawing (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId))
    , permissionOverwrites : List Evergreen.V384.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V384.GuildName.GuildName
    , icon : Maybe Evergreen.V384.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V384.MembersAndOwner.MembersAndOwner
            (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V384.Discord.Id Evergreen.V384.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V384.Id.Id Evergreen.V384.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V384.Id.Id Evergreen.V384.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId
    , messages : List Evergreen.V384.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V384.Discord.Message
    , threads : List DiscordThreadReload
    }
