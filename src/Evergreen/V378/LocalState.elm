module Evergreen.V378.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V378.BackendMsgLog
import Evergreen.V378.Call
import Evergreen.V378.ChannelDescription
import Evergreen.V378.ChannelName
import Evergreen.V378.Discord
import Evergreen.V378.DiscordUserData
import Evergreen.V378.DmChannel
import Evergreen.V378.DmChannelId
import Evergreen.V378.Drawing
import Evergreen.V378.FileStatus
import Evergreen.V378.Game
import Evergreen.V378.GuildName
import Evergreen.V378.Id
import Evergreen.V378.IdArray
import Evergreen.V378.Log
import Evergreen.V378.MembersAndOwner
import Evergreen.V378.Message
import Evergreen.V378.MessageArray
import Evergreen.V378.NonemptyDict
import Evergreen.V378.OneToOne
import Evergreen.V378.Pagination
import Evergreen.V378.Postmark
import Evergreen.V378.SecretId
import Evergreen.V378.SessionIdHash
import Evergreen.V378.Slack
import Evergreen.V378.TextEditor
import Evergreen.V378.Thread
import Evergreen.V378.ToBackendLog
import Evergreen.V378.User
import Evergreen.V378.UserSession
import Evergreen.V378.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V378.NonemptyDict.NonemptyDict
            (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V378.Message.Message Evergreen.V378.Id.ChannelMessageId (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V378.Discord.PartialUser
        , icon : Maybe Evergreen.V378.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V378.Discord.User
        , linkedTo : Evergreen.V378.Id.Id Evergreen.V378.Id.UserId
        , icon : Maybe Evergreen.V378.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V378.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V378.Discord.User
        , linkedTo : Evergreen.V378.Id.Id Evergreen.V378.Id.UserId
        , icon : Maybe Evergreen.V378.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V378.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V378.Message.Message Evergreen.V378.Id.ChannelMessageId (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId))
    , permissionOverwrites : List Evergreen.V378.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V378.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V378.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V378.MembersAndOwner.MembersAndOwner
            (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V378.Discord.Id Evergreen.V378.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V378.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V378.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V378.Id.Id Evergreen.V378.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V378.GuildName.GuildName
    , owner : Evergreen.V378.Id.Id Evergreen.V378.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V378.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V378.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V378.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V378.Call.RemoteCallData
    , currentlyViewing : Evergreen.V378.UserSession.Viewing
    }


type BackupContents
    = FullBackup
    | SubsetBackup


type alias LastBackup =
    { createdAt : Effect.Time.Posix
    , contents : BackupContents
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V378.Id.Id Evergreen.V378.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V378.Id.Id Evergreen.V378.Id.UserId
    , name : Evergreen.V378.ChannelName.ChannelName
    , description : Evergreen.V378.ChannelDescription.ChannelDescription
    , messages : Evergreen.V378.MessageArray.MessageArray Evergreen.V378.Id.ChannelMessageId (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)
    , visibleMessages : Evergreen.V378.VisibleMessages.VisibleMessages Evergreen.V378.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) (Evergreen.V378.Thread.LastTypedAt Evergreen.V378.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) Evergreen.V378.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V378.Drawing.Drawing (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) Evergreen.V378.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V378.Id.Id Evergreen.V378.Id.UserId
    , name : Evergreen.V378.GuildName.GuildName
    , icon : Maybe Evergreen.V378.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V378.MembersAndOwner.MembersAndOwner
            (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V378.SecretId.SecretId Evergreen.V378.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V378.Id.Id Evergreen.V378.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V378.ChannelName.ChannelName
    , description : Evergreen.V378.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V378.MessageArray.MessageArray Evergreen.V378.Id.ChannelMessageId (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId)
    , visibleMessages : Evergreen.V378.VisibleMessages.VisibleMessages Evergreen.V378.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Thread.LastTypedAt Evergreen.V378.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) Evergreen.V378.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V378.Drawing.Drawing (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId))
    , permissionOverwrites : List Evergreen.V378.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V378.GuildName.GuildName
    , icon : Maybe Evergreen.V378.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V378.MembersAndOwner.MembersAndOwner
            (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V378.Discord.Id Evergreen.V378.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V378.Id.Id Evergreen.V378.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V378.Id.Id Evergreen.V378.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V378.NonemptyDict.NonemptyDict (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Evergreen.V378.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V378.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V378.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V378.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V378.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V378.SessionIdHash.SessionIdHash, Evergreen.V378.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V378.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V378.BackendMsgLog.BackendMsgLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V378.SessionIdHash.SessionIdHash Evergreen.V378.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Evergreen.V378.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId) Evergreen.V378.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V378.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V378.SessionIdHash.SessionIdHash Evergreen.V378.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V378.TextEditor.LocalState
    , calls : Evergreen.V378.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V378.Id.Id Evergreen.V378.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V378.Id.Id Evergreen.V378.Id.UserId
    , name : Evergreen.V378.ChannelName.ChannelName
    , description : Evergreen.V378.ChannelDescription.ChannelDescription
    , messages : Evergreen.V378.IdArray.IdArray Evergreen.V378.Id.ChannelMessageId (Evergreen.V378.Message.Message Evergreen.V378.Id.ChannelMessageId (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) (Evergreen.V378.Thread.LastTypedAt Evergreen.V378.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) Evergreen.V378.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V378.Drawing.Drawing (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) Evergreen.V378.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V378.Id.Id Evergreen.V378.Id.UserId
    , name : Evergreen.V378.GuildName.GuildName
    , icon : Maybe Evergreen.V378.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V378.MembersAndOwner.MembersAndOwner
            (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V378.SecretId.SecretId Evergreen.V378.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V378.Id.Id Evergreen.V378.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V378.ChannelName.ChannelName
    , description : Evergreen.V378.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V378.IdArray.IdArray Evergreen.V378.Id.ChannelMessageId (Evergreen.V378.Message.Message Evergreen.V378.Id.ChannelMessageId (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Thread.LastTypedAt Evergreen.V378.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V378.OneToOne.OneToOne (Evergreen.V378.Discord.Id Evergreen.V378.Discord.MessageId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) Evergreen.V378.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V378.Drawing.Drawing (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId))
    , permissionOverwrites : List Evergreen.V378.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V378.GuildName.GuildName
    , icon : Maybe Evergreen.V378.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V378.MembersAndOwner.MembersAndOwner
            (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V378.Discord.Id Evergreen.V378.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V378.Id.Id Evergreen.V378.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V378.Id.Id Evergreen.V378.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId
    , messages : List Evergreen.V378.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V378.Discord.Message
    , threads : List DiscordThreadReload
    }
