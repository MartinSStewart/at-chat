module Evergreen.V375.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V375.Call
import Evergreen.V375.ChannelDescription
import Evergreen.V375.ChannelName
import Evergreen.V375.Discord
import Evergreen.V375.DiscordUserData
import Evergreen.V375.DmChannel
import Evergreen.V375.DmChannelId
import Evergreen.V375.Drawing
import Evergreen.V375.FileStatus
import Evergreen.V375.Game
import Evergreen.V375.GuildName
import Evergreen.V375.Id
import Evergreen.V375.IdArray
import Evergreen.V375.Log
import Evergreen.V375.MembersAndOwner
import Evergreen.V375.Message
import Evergreen.V375.MessageArray
import Evergreen.V375.NonemptyDict
import Evergreen.V375.OneToOne
import Evergreen.V375.Pagination
import Evergreen.V375.Postmark
import Evergreen.V375.SecretId
import Evergreen.V375.SessionIdHash
import Evergreen.V375.Slack
import Evergreen.V375.TextEditor
import Evergreen.V375.Thread
import Evergreen.V375.ToBackendLog
import Evergreen.V375.User
import Evergreen.V375.UserSession
import Evergreen.V375.VisibleMessages
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
        Evergreen.V375.NonemptyDict.NonemptyDict
            (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V375.Message.Message Evergreen.V375.Id.ChannelMessageId (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V375.Discord.PartialUser
        , icon : Maybe Evergreen.V375.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V375.Discord.User
        , linkedTo : Evergreen.V375.Id.Id Evergreen.V375.Id.UserId
        , icon : Maybe Evergreen.V375.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V375.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V375.Discord.User
        , linkedTo : Evergreen.V375.Id.Id Evergreen.V375.Id.UserId
        , icon : Maybe Evergreen.V375.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V375.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V375.Message.Message Evergreen.V375.Id.ChannelMessageId (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId))
    , permissionOverwrites : List Evergreen.V375.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V375.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V375.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V375.MembersAndOwner.MembersAndOwner
            (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V375.Discord.Id Evergreen.V375.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V375.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V375.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V375.Id.Id Evergreen.V375.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V375.GuildName.GuildName
    , owner : Evergreen.V375.Id.Id Evergreen.V375.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V375.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V375.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V375.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V375.Call.RemoteCallData
    , currentlyViewing : Evergreen.V375.UserSession.Viewing
    }


type BackupContents
    = FullBackup
    | SubsetBackup


type alias LastBackup =
    { createdAt : Effect.Time.Posix
    , contents : BackupContents
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V375.Id.Id Evergreen.V375.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V375.Id.Id Evergreen.V375.Id.UserId
    , name : Evergreen.V375.ChannelName.ChannelName
    , description : Evergreen.V375.ChannelDescription.ChannelDescription
    , messages : Evergreen.V375.MessageArray.MessageArray Evergreen.V375.Id.ChannelMessageId (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)
    , visibleMessages : Evergreen.V375.VisibleMessages.VisibleMessages Evergreen.V375.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) (Evergreen.V375.Thread.LastTypedAt Evergreen.V375.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) Evergreen.V375.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V375.Drawing.Drawing (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) Evergreen.V375.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V375.Id.Id Evergreen.V375.Id.UserId
    , name : Evergreen.V375.GuildName.GuildName
    , icon : Maybe Evergreen.V375.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V375.MembersAndOwner.MembersAndOwner
            (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V375.SecretId.SecretId Evergreen.V375.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V375.Id.Id Evergreen.V375.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V375.ChannelName.ChannelName
    , description : Evergreen.V375.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V375.MessageArray.MessageArray Evergreen.V375.Id.ChannelMessageId (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId)
    , visibleMessages : Evergreen.V375.VisibleMessages.VisibleMessages Evergreen.V375.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Thread.LastTypedAt Evergreen.V375.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) Evergreen.V375.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V375.Drawing.Drawing (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId))
    , permissionOverwrites : List Evergreen.V375.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V375.GuildName.GuildName
    , icon : Maybe Evergreen.V375.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V375.MembersAndOwner.MembersAndOwner
            (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V375.Discord.Id Evergreen.V375.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V375.Id.Id Evergreen.V375.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V375.Id.Id Evergreen.V375.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V375.NonemptyDict.NonemptyDict (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Evergreen.V375.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V375.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V375.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V375.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V375.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V375.SessionIdHash.SessionIdHash (Evergreen.V375.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V375.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V375.SessionIdHash.SessionIdHash Evergreen.V375.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Evergreen.V375.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId) Evergreen.V375.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V375.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V375.SessionIdHash.SessionIdHash Evergreen.V375.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V375.TextEditor.LocalState
    , calls : Evergreen.V375.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V375.Id.Id Evergreen.V375.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V375.Id.Id Evergreen.V375.Id.UserId
    , name : Evergreen.V375.ChannelName.ChannelName
    , description : Evergreen.V375.ChannelDescription.ChannelDescription
    , messages : Evergreen.V375.IdArray.IdArray Evergreen.V375.Id.ChannelMessageId (Evergreen.V375.Message.Message Evergreen.V375.Id.ChannelMessageId (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) (Evergreen.V375.Thread.LastTypedAt Evergreen.V375.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) Evergreen.V375.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V375.Drawing.Drawing (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) Evergreen.V375.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V375.Id.Id Evergreen.V375.Id.UserId
    , name : Evergreen.V375.GuildName.GuildName
    , icon : Maybe Evergreen.V375.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V375.MembersAndOwner.MembersAndOwner
            (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V375.SecretId.SecretId Evergreen.V375.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V375.Id.Id Evergreen.V375.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V375.ChannelName.ChannelName
    , description : Evergreen.V375.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V375.IdArray.IdArray Evergreen.V375.Id.ChannelMessageId (Evergreen.V375.Message.Message Evergreen.V375.Id.ChannelMessageId (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Thread.LastTypedAt Evergreen.V375.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V375.OneToOne.OneToOne (Evergreen.V375.Discord.Id Evergreen.V375.Discord.MessageId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) Evergreen.V375.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V375.Drawing.Drawing (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId))
    , permissionOverwrites : List Evergreen.V375.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V375.GuildName.GuildName
    , icon : Maybe Evergreen.V375.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V375.MembersAndOwner.MembersAndOwner
            (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V375.Discord.Id Evergreen.V375.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V375.Id.Id Evergreen.V375.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V375.Id.Id Evergreen.V375.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId
    , messages : List Evergreen.V375.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V375.Discord.Message
    , threads : List DiscordThreadReload
    }
