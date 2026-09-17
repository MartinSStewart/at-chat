module Evergreen.V383.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V383.BackendMsgLog
import Evergreen.V383.Call
import Evergreen.V383.ChannelDescription
import Evergreen.V383.ChannelName
import Evergreen.V383.Discord
import Evergreen.V383.DiscordUserData
import Evergreen.V383.DmChannel
import Evergreen.V383.DmChannelId
import Evergreen.V383.Drawing
import Evergreen.V383.FileStatus
import Evergreen.V383.Game
import Evergreen.V383.GuildName
import Evergreen.V383.Id
import Evergreen.V383.IdArray
import Evergreen.V383.Log
import Evergreen.V383.MembersAndOwner
import Evergreen.V383.Message
import Evergreen.V383.MessageArray
import Evergreen.V383.NonemptyDict
import Evergreen.V383.OneToOne
import Evergreen.V383.Pagination
import Evergreen.V383.Postmark
import Evergreen.V383.SecretId
import Evergreen.V383.SessionIdHash
import Evergreen.V383.Slack
import Evergreen.V383.TextEditor
import Evergreen.V383.Thread
import Evergreen.V383.ToBackendLog
import Evergreen.V383.User
import Evergreen.V383.UserSession
import Evergreen.V383.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V383.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V383.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V383.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V383.Call.RemoteCallData
    , currentlyViewing : Evergreen.V383.UserSession.Viewing
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
    , archivedBy : Evergreen.V383.Id.Id Evergreen.V383.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V383.Id.Id Evergreen.V383.Id.UserId
    , name : Evergreen.V383.ChannelName.ChannelName
    , description : Evergreen.V383.ChannelDescription.ChannelDescription
    , messages : Evergreen.V383.MessageArray.MessageArray Evergreen.V383.Id.ChannelMessageId (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)
    , visibleMessages : Evergreen.V383.VisibleMessages.VisibleMessages Evergreen.V383.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) (Evergreen.V383.Thread.LastTypedAt Evergreen.V383.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) Evergreen.V383.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V383.Drawing.Drawing (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) Evergreen.V383.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V383.Id.Id Evergreen.V383.Id.UserId
    , name : Evergreen.V383.GuildName.GuildName
    , icon : Maybe Evergreen.V383.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V383.MembersAndOwner.MembersAndOwner
            (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V383.SecretId.SecretId Evergreen.V383.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V383.Id.Id Evergreen.V383.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V383.ChannelName.ChannelName
    , description : Evergreen.V383.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V383.MessageArray.MessageArray Evergreen.V383.Id.ChannelMessageId (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId)
    , visibleMessages : Evergreen.V383.VisibleMessages.VisibleMessages Evergreen.V383.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Thread.LastTypedAt Evergreen.V383.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) Evergreen.V383.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V383.Drawing.Drawing (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId))
    , permissionOverwrites : List Evergreen.V383.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V383.Discord.Permissions
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V383.GuildName.GuildName
    , icon : Maybe Evergreen.V383.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V383.MembersAndOwner.MembersAndOwner
            (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V383.Discord.Id Evergreen.V383.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V383.Id.Id Evergreen.V383.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V383.Id.Id Evergreen.V383.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V383.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V383.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V383.Id.Id Evergreen.V383.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V383.GuildName.GuildName
    , owner : Evergreen.V383.Id.Id Evergreen.V383.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V383.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V383.Message.Message Evergreen.V383.Id.ChannelMessageId (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId))
    , permissionOverwrites : List Evergreen.V383.Discord.Overwrite
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V383.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V383.MembersAndOwner.MembersAndOwner
            (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V383.Discord.Id Evergreen.V383.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V383.NonemptyDict.NonemptyDict
            (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V383.Message.Message Evergreen.V383.Id.ChannelMessageId (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V383.Discord.PartialUser
        , icon : Maybe Evergreen.V383.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V383.Discord.User
        , linkedTo : Evergreen.V383.Id.Id Evergreen.V383.Id.UserId
        , icon : Maybe Evergreen.V383.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V383.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V383.Discord.User
        , linkedTo : Evergreen.V383.Id.Id Evergreen.V383.Id.UserId
        , icon : Maybe Evergreen.V383.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


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
    { users : AdminDataStatus (Evergreen.V383.NonemptyDict.NonemptyDict (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Evergreen.V383.User.BackendUser)
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V383.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V383.Postmark.ApiKey
    , dmChannels : AdminDataStatus (SeqDict.SeqDict Evergreen.V383.DmChannelId.DmChannelId AdminData_DmChannel)
    , discordDmChannels : AdminDataStatus (SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId) AdminData_DiscordDmChannel)
    , discordUsers : AdminDataStatus (SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) AdminData_DiscordGuild)
    , guilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) AdminData_Guild)
    , deletedGuilds : AdminDataStatus (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) AdminData_DeletedGuild)
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V383.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V383.SessionIdHash.SessionIdHash, Evergreen.V383.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : AdminDataStatus (Array.Array Evergreen.V383.ToBackendLog.ToBackendLogData)
    , backendMsgLogs : AdminDataStatus (Array.Array Evergreen.V383.BackendMsgLog.BackendMsgLogData)
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : AdminDataStatus (Array.Array WebsocketClosedEvent)
    , sessions : AdminDataStatus (SeqDict.SeqDict Evergreen.V383.SessionIdHash.SessionIdHash Evergreen.V383.UserSession.UserSession)
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Evergreen.V383.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId) Evergreen.V383.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V383.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V383.SessionIdHash.SessionIdHash Evergreen.V383.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V383.TextEditor.LocalState
    , calls : Evergreen.V383.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V383.Id.Id Evergreen.V383.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V383.Id.Id Evergreen.V383.Id.UserId
    , name : Evergreen.V383.ChannelName.ChannelName
    , description : Evergreen.V383.ChannelDescription.ChannelDescription
    , messages : Evergreen.V383.IdArray.IdArray Evergreen.V383.Id.ChannelMessageId (Evergreen.V383.Message.Message Evergreen.V383.Id.ChannelMessageId (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) (Evergreen.V383.Thread.LastTypedAt Evergreen.V383.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) Evergreen.V383.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V383.Drawing.Drawing (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) Evergreen.V383.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V383.Id.Id Evergreen.V383.Id.UserId
    , name : Evergreen.V383.GuildName.GuildName
    , icon : Maybe Evergreen.V383.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V383.MembersAndOwner.MembersAndOwner
            (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V383.SecretId.SecretId Evergreen.V383.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V383.Id.Id Evergreen.V383.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V383.ChannelName.ChannelName
    , description : Evergreen.V383.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V383.IdArray.IdArray Evergreen.V383.Id.ChannelMessageId (Evergreen.V383.Message.Message Evergreen.V383.Id.ChannelMessageId (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Thread.LastTypedAt Evergreen.V383.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V383.OneToOne.OneToOne (Evergreen.V383.Discord.Id Evergreen.V383.Discord.MessageId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) Evergreen.V383.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V383.Drawing.Drawing (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId))
    , permissionOverwrites : List Evergreen.V383.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V383.GuildName.GuildName
    , icon : Maybe Evergreen.V383.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V383.MembersAndOwner.MembersAndOwner
            (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V383.Discord.Id Evergreen.V383.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V383.Id.Id Evergreen.V383.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V383.Id.Id Evergreen.V383.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId
    , messages : List Evergreen.V383.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V383.Discord.Message
    , threads : List DiscordThreadReload
    }
