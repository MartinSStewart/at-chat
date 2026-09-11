module Evergreen.V377.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V377.Call
import Evergreen.V377.ChannelDescription
import Evergreen.V377.ChannelName
import Evergreen.V377.Discord
import Evergreen.V377.DiscordUserData
import Evergreen.V377.DmChannel
import Evergreen.V377.DmChannelId
import Evergreen.V377.Drawing
import Evergreen.V377.FileStatus
import Evergreen.V377.Game
import Evergreen.V377.GuildName
import Evergreen.V377.Id
import Evergreen.V377.IdArray
import Evergreen.V377.Log
import Evergreen.V377.MembersAndOwner
import Evergreen.V377.Message
import Evergreen.V377.MessageArray
import Evergreen.V377.NonemptyDict
import Evergreen.V377.OneToOne
import Evergreen.V377.Pagination
import Evergreen.V377.Postmark
import Evergreen.V377.SecretId
import Evergreen.V377.SessionIdHash
import Evergreen.V377.Slack
import Evergreen.V377.TextEditor
import Evergreen.V377.Thread
import Evergreen.V377.ToBackendLog
import Evergreen.V377.User
import Evergreen.V377.UserSession
import Evergreen.V377.VisibleMessages
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
        Evergreen.V377.NonemptyDict.NonemptyDict
            (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V377.Message.Message Evergreen.V377.Id.ChannelMessageId (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V377.Discord.PartialUser
        , icon : Maybe Evergreen.V377.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V377.Discord.User
        , linkedTo : Evergreen.V377.Id.Id Evergreen.V377.Id.UserId
        , icon : Maybe Evergreen.V377.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V377.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V377.Discord.User
        , linkedTo : Evergreen.V377.Id.Id Evergreen.V377.Id.UserId
        , icon : Maybe Evergreen.V377.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V377.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V377.Message.Message Evergreen.V377.Id.ChannelMessageId (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId))
    , permissionOverwrites : List Evergreen.V377.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V377.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V377.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V377.MembersAndOwner.MembersAndOwner
            (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V377.Discord.Id Evergreen.V377.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V377.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V377.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V377.Id.Id Evergreen.V377.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V377.GuildName.GuildName
    , owner : Evergreen.V377.Id.Id Evergreen.V377.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V377.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V377.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V377.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V377.Call.RemoteCallData
    , currentlyViewing : Evergreen.V377.UserSession.Viewing
    }


type BackupContents
    = FullBackup
    | SubsetBackup


type alias LastBackup =
    { createdAt : Effect.Time.Posix
    , contents : BackupContents
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V377.Id.Id Evergreen.V377.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V377.Id.Id Evergreen.V377.Id.UserId
    , name : Evergreen.V377.ChannelName.ChannelName
    , description : Evergreen.V377.ChannelDescription.ChannelDescription
    , messages : Evergreen.V377.MessageArray.MessageArray Evergreen.V377.Id.ChannelMessageId (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)
    , visibleMessages : Evergreen.V377.VisibleMessages.VisibleMessages Evergreen.V377.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) (Evergreen.V377.Thread.LastTypedAt Evergreen.V377.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) Evergreen.V377.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V377.Drawing.Drawing (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) Evergreen.V377.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V377.Id.Id Evergreen.V377.Id.UserId
    , name : Evergreen.V377.GuildName.GuildName
    , icon : Maybe Evergreen.V377.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V377.MembersAndOwner.MembersAndOwner
            (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V377.SecretId.SecretId Evergreen.V377.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V377.Id.Id Evergreen.V377.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V377.ChannelName.ChannelName
    , description : Evergreen.V377.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V377.MessageArray.MessageArray Evergreen.V377.Id.ChannelMessageId (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId)
    , visibleMessages : Evergreen.V377.VisibleMessages.VisibleMessages Evergreen.V377.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Thread.LastTypedAt Evergreen.V377.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) Evergreen.V377.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V377.Drawing.Drawing (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId))
    , permissionOverwrites : List Evergreen.V377.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V377.GuildName.GuildName
    , icon : Maybe Evergreen.V377.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V377.MembersAndOwner.MembersAndOwner
            (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V377.Discord.Id Evergreen.V377.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V377.Id.Id Evergreen.V377.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V377.Id.Id Evergreen.V377.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V377.NonemptyDict.NonemptyDict (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Evergreen.V377.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V377.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V377.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V377.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V377.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V377.SessionIdHash.SessionIdHash, Evergreen.V377.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V377.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V377.SessionIdHash.SessionIdHash Evergreen.V377.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Evergreen.V377.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId) Evergreen.V377.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V377.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V377.SessionIdHash.SessionIdHash Evergreen.V377.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V377.TextEditor.LocalState
    , calls : Evergreen.V377.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V377.Id.Id Evergreen.V377.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V377.Id.Id Evergreen.V377.Id.UserId
    , name : Evergreen.V377.ChannelName.ChannelName
    , description : Evergreen.V377.ChannelDescription.ChannelDescription
    , messages : Evergreen.V377.IdArray.IdArray Evergreen.V377.Id.ChannelMessageId (Evergreen.V377.Message.Message Evergreen.V377.Id.ChannelMessageId (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) (Evergreen.V377.Thread.LastTypedAt Evergreen.V377.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) Evergreen.V377.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V377.Drawing.Drawing (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) Evergreen.V377.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V377.Id.Id Evergreen.V377.Id.UserId
    , name : Evergreen.V377.GuildName.GuildName
    , icon : Maybe Evergreen.V377.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V377.MembersAndOwner.MembersAndOwner
            (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V377.SecretId.SecretId Evergreen.V377.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V377.Id.Id Evergreen.V377.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V377.ChannelName.ChannelName
    , description : Evergreen.V377.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V377.IdArray.IdArray Evergreen.V377.Id.ChannelMessageId (Evergreen.V377.Message.Message Evergreen.V377.Id.ChannelMessageId (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Thread.LastTypedAt Evergreen.V377.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V377.OneToOne.OneToOne (Evergreen.V377.Discord.Id Evergreen.V377.Discord.MessageId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) Evergreen.V377.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V377.Drawing.Drawing (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId))
    , permissionOverwrites : List Evergreen.V377.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V377.GuildName.GuildName
    , icon : Maybe Evergreen.V377.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V377.MembersAndOwner.MembersAndOwner
            (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V377.Discord.Id Evergreen.V377.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V377.Id.Id Evergreen.V377.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V377.Id.Id Evergreen.V377.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId
    , messages : List Evergreen.V377.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V377.Discord.Message
    , threads : List DiscordThreadReload
    }
