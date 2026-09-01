module Evergreen.V366.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V366.Call
import Evergreen.V366.ChannelDescription
import Evergreen.V366.ChannelName
import Evergreen.V366.Discord
import Evergreen.V366.DiscordUserData
import Evergreen.V366.DmChannel
import Evergreen.V366.DmChannelId
import Evergreen.V366.Drawing
import Evergreen.V366.FileStatus
import Evergreen.V366.Game
import Evergreen.V366.GuildName
import Evergreen.V366.Id
import Evergreen.V366.IdArray
import Evergreen.V366.Log
import Evergreen.V366.MembersAndOwner
import Evergreen.V366.Message
import Evergreen.V366.MessageArray
import Evergreen.V366.NonemptyDict
import Evergreen.V366.OneToOne
import Evergreen.V366.Pagination
import Evergreen.V366.Postmark
import Evergreen.V366.SecretId
import Evergreen.V366.SessionIdHash
import Evergreen.V366.Slack
import Evergreen.V366.TextEditor
import Evergreen.V366.Thread
import Evergreen.V366.ToBackendLog
import Evergreen.V366.User
import Evergreen.V366.UserSession
import Evergreen.V366.VisibleMessages
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
        Evergreen.V366.NonemptyDict.NonemptyDict
            (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V366.Message.Message Evergreen.V366.Id.ChannelMessageId (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V366.Discord.PartialUser
        , icon : Maybe Evergreen.V366.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V366.Discord.User
        , linkedTo : Evergreen.V366.Id.Id Evergreen.V366.Id.UserId
        , icon : Maybe Evergreen.V366.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V366.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V366.Discord.User
        , linkedTo : Evergreen.V366.Id.Id Evergreen.V366.Id.UserId
        , icon : Maybe Evergreen.V366.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V366.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V366.Message.Message Evergreen.V366.Id.ChannelMessageId (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId))
    , permissionOverwrites : List Evergreen.V366.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V366.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V366.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V366.MembersAndOwner.MembersAndOwner
            (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V366.Discord.Id Evergreen.V366.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V366.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V366.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V366.Id.Id Evergreen.V366.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V366.GuildName.GuildName
    , owner : Evergreen.V366.Id.Id Evergreen.V366.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V366.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V366.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V366.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V366.Call.RemoteCallData
    , currentlyViewing : Evergreen.V366.UserSession.Viewing
    }


type BackupContents
    = FullBackup
    | SubsetBackup


type alias LastBackup =
    { createdAt : Effect.Time.Posix
    , contents : BackupContents
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V366.Id.Id Evergreen.V366.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V366.Id.Id Evergreen.V366.Id.UserId
    , name : Evergreen.V366.ChannelName.ChannelName
    , description : Evergreen.V366.ChannelDescription.ChannelDescription
    , messages : Evergreen.V366.MessageArray.MessageArray Evergreen.V366.Id.ChannelMessageId (Evergreen.V366.Message.Message Evergreen.V366.Id.ChannelMessageId (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId))
    , visibleMessages : Evergreen.V366.VisibleMessages.VisibleMessages Evergreen.V366.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) (Evergreen.V366.Thread.LastTypedAt Evergreen.V366.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) Evergreen.V366.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V366.Drawing.Drawing (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) Evergreen.V366.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V366.Id.Id Evergreen.V366.Id.UserId
    , name : Evergreen.V366.GuildName.GuildName
    , icon : Maybe Evergreen.V366.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V366.MembersAndOwner.MembersAndOwner
            (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V366.SecretId.SecretId Evergreen.V366.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V366.Id.Id Evergreen.V366.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V366.ChannelName.ChannelName
    , description : Evergreen.V366.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V366.MessageArray.MessageArray Evergreen.V366.Id.ChannelMessageId (Evergreen.V366.Message.Message Evergreen.V366.Id.ChannelMessageId (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId))
    , visibleMessages : Evergreen.V366.VisibleMessages.VisibleMessages Evergreen.V366.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Thread.LastTypedAt Evergreen.V366.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) Evergreen.V366.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V366.Drawing.Drawing (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId))
    , permissionOverwrites : List Evergreen.V366.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V366.GuildName.GuildName
    , icon : Maybe Evergreen.V366.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V366.MembersAndOwner.MembersAndOwner
            (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V366.Discord.Id Evergreen.V366.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V366.Id.Id Evergreen.V366.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V366.Id.Id Evergreen.V366.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V366.NonemptyDict.NonemptyDict (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) Evergreen.V366.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V366.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V366.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V366.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V366.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V366.SessionIdHash.SessionIdHash (Evergreen.V366.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V366.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V366.SessionIdHash.SessionIdHash Evergreen.V366.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) Evergreen.V366.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId) Evergreen.V366.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V366.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V366.SessionIdHash.SessionIdHash Evergreen.V366.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V366.TextEditor.LocalState
    , calls : Evergreen.V366.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V366.Id.Id Evergreen.V366.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V366.Id.Id Evergreen.V366.Id.UserId
    , name : Evergreen.V366.ChannelName.ChannelName
    , description : Evergreen.V366.ChannelDescription.ChannelDescription
    , messages : Evergreen.V366.IdArray.IdArray Evergreen.V366.Id.ChannelMessageId (Evergreen.V366.Message.Message Evergreen.V366.Id.ChannelMessageId (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) (Evergreen.V366.Thread.LastTypedAt Evergreen.V366.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) Evergreen.V366.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V366.Drawing.Drawing (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) Evergreen.V366.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V366.Id.Id Evergreen.V366.Id.UserId
    , name : Evergreen.V366.GuildName.GuildName
    , icon : Maybe Evergreen.V366.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V366.MembersAndOwner.MembersAndOwner
            (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V366.SecretId.SecretId Evergreen.V366.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V366.Id.Id Evergreen.V366.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V366.ChannelName.ChannelName
    , description : Evergreen.V366.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V366.IdArray.IdArray Evergreen.V366.Id.ChannelMessageId (Evergreen.V366.Message.Message Evergreen.V366.Id.ChannelMessageId (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Thread.LastTypedAt Evergreen.V366.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V366.OneToOne.OneToOne (Evergreen.V366.Discord.Id Evergreen.V366.Discord.MessageId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) Evergreen.V366.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V366.Drawing.Drawing (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId))
    , permissionOverwrites : List Evergreen.V366.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V366.GuildName.GuildName
    , icon : Maybe Evergreen.V366.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V366.MembersAndOwner.MembersAndOwner
            (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V366.Discord.Id Evergreen.V366.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V366.Id.Id Evergreen.V366.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V366.Id.Id Evergreen.V366.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId
    , messages : List Evergreen.V366.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V366.Discord.Message
    , threads : List DiscordThreadReload
    }
