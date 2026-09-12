module Evergreen.V379.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V379.BackendMsgLog
import Evergreen.V379.Call
import Evergreen.V379.ChannelDescription
import Evergreen.V379.ChannelName
import Evergreen.V379.Discord
import Evergreen.V379.DiscordUserData
import Evergreen.V379.DmChannel
import Evergreen.V379.DmChannelId
import Evergreen.V379.Drawing
import Evergreen.V379.FileStatus
import Evergreen.V379.Game
import Evergreen.V379.GuildName
import Evergreen.V379.Id
import Evergreen.V379.IdArray
import Evergreen.V379.Log
import Evergreen.V379.MembersAndOwner
import Evergreen.V379.Message
import Evergreen.V379.MessageArray
import Evergreen.V379.NonemptyDict
import Evergreen.V379.OneToOne
import Evergreen.V379.Pagination
import Evergreen.V379.Postmark
import Evergreen.V379.SecretId
import Evergreen.V379.SessionIdHash
import Evergreen.V379.Slack
import Evergreen.V379.TextEditor
import Evergreen.V379.Thread
import Evergreen.V379.ToBackendLog
import Evergreen.V379.User
import Evergreen.V379.UserSession
import Evergreen.V379.VisibleMessages
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
        Evergreen.V379.NonemptyDict.NonemptyDict
            (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V379.Message.Message Evergreen.V379.Id.ChannelMessageId (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V379.Discord.PartialUser
        , icon : Maybe Evergreen.V379.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V379.Discord.User
        , linkedTo : Evergreen.V379.Id.Id Evergreen.V379.Id.UserId
        , icon : Maybe Evergreen.V379.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V379.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V379.Discord.User
        , linkedTo : Evergreen.V379.Id.Id Evergreen.V379.Id.UserId
        , icon : Maybe Evergreen.V379.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V379.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V379.Message.Message Evergreen.V379.Id.ChannelMessageId (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId))
    , permissionOverwrites : List Evergreen.V379.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V379.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V379.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V379.MembersAndOwner.MembersAndOwner
            (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V379.Discord.Id Evergreen.V379.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V379.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V379.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V379.Id.Id Evergreen.V379.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V379.GuildName.GuildName
    , owner : Evergreen.V379.Id.Id Evergreen.V379.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V379.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V379.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V379.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V379.Call.RemoteCallData
    , currentlyViewing : Evergreen.V379.UserSession.Viewing
    }


type BackupContents
    = FullBackup
    | SubsetBackup


type alias LastBackup =
    { createdAt : Effect.Time.Posix
    , contents : BackupContents
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V379.Id.Id Evergreen.V379.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V379.Id.Id Evergreen.V379.Id.UserId
    , name : Evergreen.V379.ChannelName.ChannelName
    , description : Evergreen.V379.ChannelDescription.ChannelDescription
    , messages : Evergreen.V379.MessageArray.MessageArray Evergreen.V379.Id.ChannelMessageId (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)
    , visibleMessages : Evergreen.V379.VisibleMessages.VisibleMessages Evergreen.V379.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) (Evergreen.V379.Thread.LastTypedAt Evergreen.V379.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) Evergreen.V379.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V379.Drawing.Drawing (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) Evergreen.V379.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V379.Id.Id Evergreen.V379.Id.UserId
    , name : Evergreen.V379.GuildName.GuildName
    , icon : Maybe Evergreen.V379.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V379.MembersAndOwner.MembersAndOwner
            (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V379.SecretId.SecretId Evergreen.V379.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V379.Id.Id Evergreen.V379.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V379.ChannelName.ChannelName
    , description : Evergreen.V379.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V379.MessageArray.MessageArray Evergreen.V379.Id.ChannelMessageId (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId)
    , visibleMessages : Evergreen.V379.VisibleMessages.VisibleMessages Evergreen.V379.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Thread.LastTypedAt Evergreen.V379.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) Evergreen.V379.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V379.Drawing.Drawing (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId))
    , permissionOverwrites : List Evergreen.V379.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V379.GuildName.GuildName
    , icon : Maybe Evergreen.V379.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V379.MembersAndOwner.MembersAndOwner
            (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V379.Discord.Id Evergreen.V379.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V379.Id.Id Evergreen.V379.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V379.Id.Id Evergreen.V379.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V379.NonemptyDict.NonemptyDict (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Evergreen.V379.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V379.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V379.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V379.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V379.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V379.SessionIdHash.SessionIdHash, Evergreen.V379.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V379.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V379.BackendMsgLog.BackendMsgLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V379.SessionIdHash.SessionIdHash Evergreen.V379.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Evergreen.V379.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId) Evergreen.V379.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V379.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V379.SessionIdHash.SessionIdHash Evergreen.V379.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V379.TextEditor.LocalState
    , calls : Evergreen.V379.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V379.Id.Id Evergreen.V379.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V379.Id.Id Evergreen.V379.Id.UserId
    , name : Evergreen.V379.ChannelName.ChannelName
    , description : Evergreen.V379.ChannelDescription.ChannelDescription
    , messages : Evergreen.V379.IdArray.IdArray Evergreen.V379.Id.ChannelMessageId (Evergreen.V379.Message.Message Evergreen.V379.Id.ChannelMessageId (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) (Evergreen.V379.Thread.LastTypedAt Evergreen.V379.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) Evergreen.V379.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V379.Drawing.Drawing (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) Evergreen.V379.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V379.Id.Id Evergreen.V379.Id.UserId
    , name : Evergreen.V379.GuildName.GuildName
    , icon : Maybe Evergreen.V379.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V379.MembersAndOwner.MembersAndOwner
            (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V379.SecretId.SecretId Evergreen.V379.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V379.Id.Id Evergreen.V379.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V379.ChannelName.ChannelName
    , description : Evergreen.V379.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V379.IdArray.IdArray Evergreen.V379.Id.ChannelMessageId (Evergreen.V379.Message.Message Evergreen.V379.Id.ChannelMessageId (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Thread.LastTypedAt Evergreen.V379.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V379.OneToOne.OneToOne (Evergreen.V379.Discord.Id Evergreen.V379.Discord.MessageId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) Evergreen.V379.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V379.Drawing.Drawing (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId))
    , permissionOverwrites : List Evergreen.V379.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V379.GuildName.GuildName
    , icon : Maybe Evergreen.V379.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V379.MembersAndOwner.MembersAndOwner
            (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V379.Discord.Id Evergreen.V379.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V379.Id.Id Evergreen.V379.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V379.Id.Id Evergreen.V379.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId
    , messages : List Evergreen.V379.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V379.Discord.Message
    , threads : List DiscordThreadReload
    }
