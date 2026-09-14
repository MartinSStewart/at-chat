module Evergreen.V382.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V382.BackendMsgLog
import Evergreen.V382.Call
import Evergreen.V382.ChannelDescription
import Evergreen.V382.ChannelName
import Evergreen.V382.Discord
import Evergreen.V382.DiscordUserData
import Evergreen.V382.DmChannel
import Evergreen.V382.DmChannelId
import Evergreen.V382.Drawing
import Evergreen.V382.FileStatus
import Evergreen.V382.Game
import Evergreen.V382.GuildName
import Evergreen.V382.Id
import Evergreen.V382.IdArray
import Evergreen.V382.Log
import Evergreen.V382.MembersAndOwner
import Evergreen.V382.Message
import Evergreen.V382.MessageArray
import Evergreen.V382.NonemptyDict
import Evergreen.V382.OneToOne
import Evergreen.V382.Pagination
import Evergreen.V382.Postmark
import Evergreen.V382.SecretId
import Evergreen.V382.SessionIdHash
import Evergreen.V382.Slack
import Evergreen.V382.TextEditor
import Evergreen.V382.Thread
import Evergreen.V382.ToBackendLog
import Evergreen.V382.User
import Evergreen.V382.UserSession
import Evergreen.V382.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V382.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V382.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V382.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V382.Call.RemoteCallData
    , currentlyViewing : Evergreen.V382.UserSession.Viewing
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
    , archivedBy : Evergreen.V382.Id.Id Evergreen.V382.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V382.Id.Id Evergreen.V382.Id.UserId
    , name : Evergreen.V382.ChannelName.ChannelName
    , description : Evergreen.V382.ChannelDescription.ChannelDescription
    , messages : Evergreen.V382.MessageArray.MessageArray Evergreen.V382.Id.ChannelMessageId (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)
    , visibleMessages : Evergreen.V382.VisibleMessages.VisibleMessages Evergreen.V382.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) (Evergreen.V382.Thread.LastTypedAt Evergreen.V382.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) Evergreen.V382.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V382.Drawing.Drawing (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) Evergreen.V382.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V382.Id.Id Evergreen.V382.Id.UserId
    , name : Evergreen.V382.GuildName.GuildName
    , icon : Maybe Evergreen.V382.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V382.MembersAndOwner.MembersAndOwner
            (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V382.SecretId.SecretId Evergreen.V382.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V382.Id.Id Evergreen.V382.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V382.ChannelName.ChannelName
    , description : Evergreen.V382.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V382.MessageArray.MessageArray Evergreen.V382.Id.ChannelMessageId (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId)
    , visibleMessages : Evergreen.V382.VisibleMessages.VisibleMessages Evergreen.V382.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Thread.LastTypedAt Evergreen.V382.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) Evergreen.V382.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V382.Drawing.Drawing (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId))
    , permissionOverwrites : List Evergreen.V382.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V382.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V382.GuildName.GuildName
    , icon : Maybe Evergreen.V382.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V382.MembersAndOwner.MembersAndOwner
            (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V382.Discord.Id Evergreen.V382.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V382.Id.Id Evergreen.V382.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V382.Id.Id Evergreen.V382.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V382.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V382.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V382.Id.Id Evergreen.V382.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V382.GuildName.GuildName
    , owner : Evergreen.V382.Id.Id Evergreen.V382.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V382.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V382.Message.Message Evergreen.V382.Id.ChannelMessageId (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId))
    , permissionOverwrites : List Evergreen.V382.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V382.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V382.MembersAndOwner.MembersAndOwner
            (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V382.Discord.Id Evergreen.V382.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V382.NonemptyDict.NonemptyDict
            (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V382.Message.Message Evergreen.V382.Id.ChannelMessageId (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V382.Discord.PartialUser
        , icon : Maybe Evergreen.V382.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V382.Discord.User
        , linkedTo : Evergreen.V382.Id.Id Evergreen.V382.Id.UserId
        , icon : Maybe Evergreen.V382.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V382.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V382.Discord.User
        , linkedTo : Evergreen.V382.Id.Id Evergreen.V382.Id.UserId
        , icon : Maybe Evergreen.V382.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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
    { users : AdminDataStatus (Evergreen.V382.NonemptyDict.NonemptyDict (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Evergreen.V382.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V382.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V382.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V382.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) AdminData_DiscordGuild)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V382.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V382.SessionIdHash.SessionIdHash, Evergreen.V382.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V382.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V382.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V382.SessionIdHash.SessionIdHash Evergreen.V382.UserSession.UserSession)
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Evergreen.V382.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId) Evergreen.V382.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V382.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V382.SessionIdHash.SessionIdHash Evergreen.V382.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V382.TextEditor.LocalState
    , calls : Evergreen.V382.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V382.Id.Id Evergreen.V382.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V382.Id.Id Evergreen.V382.Id.UserId
    , name : Evergreen.V382.ChannelName.ChannelName
    , description : Evergreen.V382.ChannelDescription.ChannelDescription
    , messages : Evergreen.V382.IdArray.IdArray Evergreen.V382.Id.ChannelMessageId (Evergreen.V382.Message.Message Evergreen.V382.Id.ChannelMessageId (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) (Evergreen.V382.Thread.LastTypedAt Evergreen.V382.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) Evergreen.V382.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V382.Drawing.Drawing (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) Evergreen.V382.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V382.Id.Id Evergreen.V382.Id.UserId
    , name : Evergreen.V382.GuildName.GuildName
    , icon : Maybe Evergreen.V382.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V382.MembersAndOwner.MembersAndOwner
            (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V382.SecretId.SecretId Evergreen.V382.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V382.Id.Id Evergreen.V382.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V382.ChannelName.ChannelName
    , description : Evergreen.V382.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V382.IdArray.IdArray Evergreen.V382.Id.ChannelMessageId (Evergreen.V382.Message.Message Evergreen.V382.Id.ChannelMessageId (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Thread.LastTypedAt Evergreen.V382.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V382.OneToOne.OneToOne (Evergreen.V382.Discord.Id Evergreen.V382.Discord.MessageId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) Evergreen.V382.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V382.Drawing.Drawing (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId))
    , permissionOverwrites : List Evergreen.V382.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V382.GuildName.GuildName
    , icon : Maybe Evergreen.V382.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V382.MembersAndOwner.MembersAndOwner
            (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V382.Discord.Id Evergreen.V382.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V382.Id.Id Evergreen.V382.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V382.Id.Id Evergreen.V382.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId
    , messages : List Evergreen.V382.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V382.Discord.Message
    , threads : List DiscordThreadReload
    }
