module Evergreen.V372.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V372.Call
import Evergreen.V372.ChannelDescription
import Evergreen.V372.ChannelName
import Evergreen.V372.Discord
import Evergreen.V372.DiscordUserData
import Evergreen.V372.DmChannel
import Evergreen.V372.DmChannelId
import Evergreen.V372.Drawing
import Evergreen.V372.FileStatus
import Evergreen.V372.Game
import Evergreen.V372.GuildName
import Evergreen.V372.Id
import Evergreen.V372.IdArray
import Evergreen.V372.Log
import Evergreen.V372.MembersAndOwner
import Evergreen.V372.Message
import Evergreen.V372.MessageArray
import Evergreen.V372.NonemptyDict
import Evergreen.V372.OneToOne
import Evergreen.V372.Pagination
import Evergreen.V372.Postmark
import Evergreen.V372.SecretId
import Evergreen.V372.SessionIdHash
import Evergreen.V372.Slack
import Evergreen.V372.TextEditor
import Evergreen.V372.Thread
import Evergreen.V372.ToBackendLog
import Evergreen.V372.User
import Evergreen.V372.UserSession
import Evergreen.V372.VisibleMessages
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
        Evergreen.V372.NonemptyDict.NonemptyDict
            (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V372.Message.Message Evergreen.V372.Id.ChannelMessageId (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V372.Discord.PartialUser
        , icon : Maybe Evergreen.V372.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V372.Discord.User
        , linkedTo : Evergreen.V372.Id.Id Evergreen.V372.Id.UserId
        , icon : Maybe Evergreen.V372.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V372.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V372.Discord.User
        , linkedTo : Evergreen.V372.Id.Id Evergreen.V372.Id.UserId
        , icon : Maybe Evergreen.V372.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V372.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V372.Message.Message Evergreen.V372.Id.ChannelMessageId (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId))
    , permissionOverwrites : List Evergreen.V372.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V372.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V372.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V372.MembersAndOwner.MembersAndOwner
            (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V372.Discord.Id Evergreen.V372.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V372.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V372.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V372.Id.Id Evergreen.V372.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V372.GuildName.GuildName
    , owner : Evergreen.V372.Id.Id Evergreen.V372.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V372.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V372.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V372.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V372.Call.RemoteCallData
    , currentlyViewing : Evergreen.V372.UserSession.Viewing
    }


type BackupContents
    = FullBackup
    | SubsetBackup


type alias LastBackup =
    { createdAt : Effect.Time.Posix
    , contents : BackupContents
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V372.Id.Id Evergreen.V372.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V372.Id.Id Evergreen.V372.Id.UserId
    , name : Evergreen.V372.ChannelName.ChannelName
    , description : Evergreen.V372.ChannelDescription.ChannelDescription
    , messages : Evergreen.V372.MessageArray.MessageArray Evergreen.V372.Id.ChannelMessageId (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)
    , visibleMessages : Evergreen.V372.VisibleMessages.VisibleMessages Evergreen.V372.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) (Evergreen.V372.Thread.LastTypedAt Evergreen.V372.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) Evergreen.V372.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V372.Drawing.Drawing (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) Evergreen.V372.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V372.Id.Id Evergreen.V372.Id.UserId
    , name : Evergreen.V372.GuildName.GuildName
    , icon : Maybe Evergreen.V372.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V372.MembersAndOwner.MembersAndOwner
            (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V372.SecretId.SecretId Evergreen.V372.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V372.Id.Id Evergreen.V372.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V372.ChannelName.ChannelName
    , description : Evergreen.V372.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V372.MessageArray.MessageArray Evergreen.V372.Id.ChannelMessageId (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId)
    , visibleMessages : Evergreen.V372.VisibleMessages.VisibleMessages Evergreen.V372.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Thread.LastTypedAt Evergreen.V372.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) Evergreen.V372.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V372.Drawing.Drawing (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId))
    , permissionOverwrites : List Evergreen.V372.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V372.GuildName.GuildName
    , icon : Maybe Evergreen.V372.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V372.MembersAndOwner.MembersAndOwner
            (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V372.Discord.Id Evergreen.V372.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V372.Id.Id Evergreen.V372.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V372.Id.Id Evergreen.V372.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V372.NonemptyDict.NonemptyDict (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Evergreen.V372.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V372.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V372.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V372.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V372.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V372.SessionIdHash.SessionIdHash (Evergreen.V372.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V372.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V372.SessionIdHash.SessionIdHash Evergreen.V372.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Evergreen.V372.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId) Evergreen.V372.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V372.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V372.SessionIdHash.SessionIdHash Evergreen.V372.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V372.TextEditor.LocalState
    , calls : Evergreen.V372.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V372.Id.Id Evergreen.V372.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V372.Id.Id Evergreen.V372.Id.UserId
    , name : Evergreen.V372.ChannelName.ChannelName
    , description : Evergreen.V372.ChannelDescription.ChannelDescription
    , messages : Evergreen.V372.IdArray.IdArray Evergreen.V372.Id.ChannelMessageId (Evergreen.V372.Message.Message Evergreen.V372.Id.ChannelMessageId (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) (Evergreen.V372.Thread.LastTypedAt Evergreen.V372.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) Evergreen.V372.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V372.Drawing.Drawing (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) Evergreen.V372.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V372.Id.Id Evergreen.V372.Id.UserId
    , name : Evergreen.V372.GuildName.GuildName
    , icon : Maybe Evergreen.V372.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V372.MembersAndOwner.MembersAndOwner
            (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V372.SecretId.SecretId Evergreen.V372.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V372.Id.Id Evergreen.V372.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V372.ChannelName.ChannelName
    , description : Evergreen.V372.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V372.IdArray.IdArray Evergreen.V372.Id.ChannelMessageId (Evergreen.V372.Message.Message Evergreen.V372.Id.ChannelMessageId (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Thread.LastTypedAt Evergreen.V372.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V372.OneToOne.OneToOne (Evergreen.V372.Discord.Id Evergreen.V372.Discord.MessageId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) Evergreen.V372.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V372.Drawing.Drawing (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId))
    , permissionOverwrites : List Evergreen.V372.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V372.GuildName.GuildName
    , icon : Maybe Evergreen.V372.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V372.MembersAndOwner.MembersAndOwner
            (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V372.Discord.Id Evergreen.V372.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V372.Id.Id Evergreen.V372.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V372.Id.Id Evergreen.V372.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId
    , messages : List Evergreen.V372.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V372.Discord.Message
    , threads : List DiscordThreadReload
    }
