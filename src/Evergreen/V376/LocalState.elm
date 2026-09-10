module Evergreen.V376.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V376.Call
import Evergreen.V376.ChannelDescription
import Evergreen.V376.ChannelName
import Evergreen.V376.Discord
import Evergreen.V376.DiscordUserData
import Evergreen.V376.DmChannel
import Evergreen.V376.DmChannelId
import Evergreen.V376.Drawing
import Evergreen.V376.FileStatus
import Evergreen.V376.Game
import Evergreen.V376.GuildName
import Evergreen.V376.Id
import Evergreen.V376.IdArray
import Evergreen.V376.Log
import Evergreen.V376.MembersAndOwner
import Evergreen.V376.Message
import Evergreen.V376.MessageArray
import Evergreen.V376.NonemptyDict
import Evergreen.V376.OneToOne
import Evergreen.V376.Pagination
import Evergreen.V376.Postmark
import Evergreen.V376.SecretId
import Evergreen.V376.SessionIdHash
import Evergreen.V376.Slack
import Evergreen.V376.TextEditor
import Evergreen.V376.Thread
import Evergreen.V376.ToBackendLog
import Evergreen.V376.User
import Evergreen.V376.UserSession
import Evergreen.V376.VisibleMessages
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
        Evergreen.V376.NonemptyDict.NonemptyDict
            (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V376.Message.Message Evergreen.V376.Id.ChannelMessageId (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V376.Discord.PartialUser
        , icon : Maybe Evergreen.V376.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V376.Discord.User
        , linkedTo : Evergreen.V376.Id.Id Evergreen.V376.Id.UserId
        , icon : Maybe Evergreen.V376.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V376.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V376.Discord.User
        , linkedTo : Evergreen.V376.Id.Id Evergreen.V376.Id.UserId
        , icon : Maybe Evergreen.V376.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V376.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V376.Message.Message Evergreen.V376.Id.ChannelMessageId (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId))
    , permissionOverwrites : List Evergreen.V376.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V376.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V376.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V376.MembersAndOwner.MembersAndOwner
            (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V376.Discord.Id Evergreen.V376.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V376.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V376.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V376.Id.Id Evergreen.V376.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V376.GuildName.GuildName
    , owner : Evergreen.V376.Id.Id Evergreen.V376.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V376.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V376.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V376.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V376.Call.RemoteCallData
    , currentlyViewing : Evergreen.V376.UserSession.Viewing
    }


type BackupContents
    = FullBackup
    | SubsetBackup


type alias LastBackup =
    { createdAt : Effect.Time.Posix
    , contents : BackupContents
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V376.Id.Id Evergreen.V376.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V376.Id.Id Evergreen.V376.Id.UserId
    , name : Evergreen.V376.ChannelName.ChannelName
    , description : Evergreen.V376.ChannelDescription.ChannelDescription
    , messages : Evergreen.V376.MessageArray.MessageArray Evergreen.V376.Id.ChannelMessageId (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)
    , visibleMessages : Evergreen.V376.VisibleMessages.VisibleMessages Evergreen.V376.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) (Evergreen.V376.Thread.LastTypedAt Evergreen.V376.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) Evergreen.V376.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V376.Drawing.Drawing (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) Evergreen.V376.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V376.Id.Id Evergreen.V376.Id.UserId
    , name : Evergreen.V376.GuildName.GuildName
    , icon : Maybe Evergreen.V376.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V376.MembersAndOwner.MembersAndOwner
            (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V376.SecretId.SecretId Evergreen.V376.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V376.Id.Id Evergreen.V376.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V376.ChannelName.ChannelName
    , description : Evergreen.V376.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V376.MessageArray.MessageArray Evergreen.V376.Id.ChannelMessageId (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId)
    , visibleMessages : Evergreen.V376.VisibleMessages.VisibleMessages Evergreen.V376.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Thread.LastTypedAt Evergreen.V376.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) Evergreen.V376.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V376.Drawing.Drawing (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId))
    , permissionOverwrites : List Evergreen.V376.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V376.GuildName.GuildName
    , icon : Maybe Evergreen.V376.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V376.MembersAndOwner.MembersAndOwner
            (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V376.Discord.Id Evergreen.V376.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V376.Id.Id Evergreen.V376.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V376.Id.Id Evergreen.V376.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V376.NonemptyDict.NonemptyDict (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Evergreen.V376.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V376.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V376.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V376.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V376.Pagination.Pagination LogWithTime
    , connections : List ( Evergreen.V376.SessionIdHash.SessionIdHash, Evergreen.V376.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData )
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V376.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V376.SessionIdHash.SessionIdHash Evergreen.V376.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Evergreen.V376.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId) Evergreen.V376.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V376.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V376.SessionIdHash.SessionIdHash Evergreen.V376.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V376.TextEditor.LocalState
    , calls : Evergreen.V376.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V376.Id.Id Evergreen.V376.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V376.Id.Id Evergreen.V376.Id.UserId
    , name : Evergreen.V376.ChannelName.ChannelName
    , description : Evergreen.V376.ChannelDescription.ChannelDescription
    , messages : Evergreen.V376.IdArray.IdArray Evergreen.V376.Id.ChannelMessageId (Evergreen.V376.Message.Message Evergreen.V376.Id.ChannelMessageId (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) (Evergreen.V376.Thread.LastTypedAt Evergreen.V376.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) Evergreen.V376.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V376.Drawing.Drawing (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) Evergreen.V376.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V376.Id.Id Evergreen.V376.Id.UserId
    , name : Evergreen.V376.GuildName.GuildName
    , icon : Maybe Evergreen.V376.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V376.MembersAndOwner.MembersAndOwner
            (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V376.SecretId.SecretId Evergreen.V376.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V376.Id.Id Evergreen.V376.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V376.ChannelName.ChannelName
    , description : Evergreen.V376.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V376.IdArray.IdArray Evergreen.V376.Id.ChannelMessageId (Evergreen.V376.Message.Message Evergreen.V376.Id.ChannelMessageId (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Thread.LastTypedAt Evergreen.V376.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V376.OneToOne.OneToOne (Evergreen.V376.Discord.Id Evergreen.V376.Discord.MessageId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) Evergreen.V376.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V376.Drawing.Drawing (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId))
    , permissionOverwrites : List Evergreen.V376.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V376.GuildName.GuildName
    , icon : Maybe Evergreen.V376.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V376.MembersAndOwner.MembersAndOwner
            (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V376.Discord.Id Evergreen.V376.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V376.Id.Id Evergreen.V376.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V376.Id.Id Evergreen.V376.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId
    , messages : List Evergreen.V376.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V376.Discord.Message
    , threads : List DiscordThreadReload
    }
