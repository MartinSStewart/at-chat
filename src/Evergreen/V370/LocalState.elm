module Evergreen.V370.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V370.Call
import Evergreen.V370.ChannelDescription
import Evergreen.V370.ChannelName
import Evergreen.V370.Discord
import Evergreen.V370.DiscordUserData
import Evergreen.V370.DmChannel
import Evergreen.V370.DmChannelId
import Evergreen.V370.Drawing
import Evergreen.V370.FileStatus
import Evergreen.V370.Game
import Evergreen.V370.GuildName
import Evergreen.V370.Id
import Evergreen.V370.IdArray
import Evergreen.V370.Log
import Evergreen.V370.MembersAndOwner
import Evergreen.V370.Message
import Evergreen.V370.MessageArray
import Evergreen.V370.NonemptyDict
import Evergreen.V370.OneToOne
import Evergreen.V370.Pagination
import Evergreen.V370.Postmark
import Evergreen.V370.SecretId
import Evergreen.V370.SessionIdHash
import Evergreen.V370.Slack
import Evergreen.V370.TextEditor
import Evergreen.V370.Thread
import Evergreen.V370.ToBackendLog
import Evergreen.V370.User
import Evergreen.V370.UserSession
import Evergreen.V370.VisibleMessages
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
        Evergreen.V370.NonemptyDict.NonemptyDict
            (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V370.Message.Message Evergreen.V370.Id.ChannelMessageId (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId))
    }


type alias DiscordGatewayStatus =
    { websocketIsOpen : Bool
    , failedReconnectAttempts : Int
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V370.Discord.PartialUser
        , icon : Maybe Evergreen.V370.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V370.Discord.User
        , linkedTo : Evergreen.V370.Id.Id Evergreen.V370.Id.UserId
        , icon : Maybe Evergreen.V370.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V370.DiscordUserData.DiscordUserLoadingData
        , gateway : DiscordGatewayStatus
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V370.Discord.User
        , linkedTo : Evergreen.V370.Id.Id Evergreen.V370.Id.UserId
        , icon : Maybe Evergreen.V370.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V370.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V370.Message.Message Evergreen.V370.Id.ChannelMessageId (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId))
    , permissionOverwrites : List Evergreen.V370.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V370.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V370.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V370.MembersAndOwner.MembersAndOwner
            (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V370.Discord.Id Evergreen.V370.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V370.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V370.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V370.Id.Id Evergreen.V370.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V370.GuildName.GuildName
    , owner : Evergreen.V370.Id.Id Evergreen.V370.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V370.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V370.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V370.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V370.Call.RemoteCallData
    , currentlyViewing : Evergreen.V370.UserSession.Viewing
    }


type BackupContents
    = FullBackup
    | SubsetBackup


type alias LastBackup =
    { createdAt : Effect.Time.Posix
    , contents : BackupContents
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V370.Id.Id Evergreen.V370.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V370.Id.Id Evergreen.V370.Id.UserId
    , name : Evergreen.V370.ChannelName.ChannelName
    , description : Evergreen.V370.ChannelDescription.ChannelDescription
    , messages : Evergreen.V370.MessageArray.MessageArray Evergreen.V370.Id.ChannelMessageId (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)
    , visibleMessages : Evergreen.V370.VisibleMessages.VisibleMessages Evergreen.V370.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) (Evergreen.V370.Thread.LastTypedAt Evergreen.V370.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) Evergreen.V370.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V370.Drawing.Drawing (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) Evergreen.V370.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V370.Id.Id Evergreen.V370.Id.UserId
    , name : Evergreen.V370.GuildName.GuildName
    , icon : Maybe Evergreen.V370.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V370.MembersAndOwner.MembersAndOwner
            (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V370.SecretId.SecretId Evergreen.V370.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V370.Id.Id Evergreen.V370.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V370.ChannelName.ChannelName
    , description : Evergreen.V370.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V370.MessageArray.MessageArray Evergreen.V370.Id.ChannelMessageId (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId)
    , visibleMessages : Evergreen.V370.VisibleMessages.VisibleMessages Evergreen.V370.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Thread.LastTypedAt Evergreen.V370.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) Evergreen.V370.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V370.Drawing.Drawing (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId))
    , permissionOverwrites : List Evergreen.V370.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V370.GuildName.GuildName
    , icon : Maybe Evergreen.V370.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V370.MembersAndOwner.MembersAndOwner
            (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V370.Discord.Id Evergreen.V370.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V370.Id.Id Evergreen.V370.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V370.Id.Id Evergreen.V370.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V370.NonemptyDict.NonemptyDict (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Evergreen.V370.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V370.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V370.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V370.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V370.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V370.SessionIdHash.SessionIdHash (Evergreen.V370.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V370.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V370.SessionIdHash.SessionIdHash Evergreen.V370.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Evergreen.V370.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId) Evergreen.V370.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V370.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V370.SessionIdHash.SessionIdHash Evergreen.V370.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V370.TextEditor.LocalState
    , calls : Evergreen.V370.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V370.Id.Id Evergreen.V370.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V370.Id.Id Evergreen.V370.Id.UserId
    , name : Evergreen.V370.ChannelName.ChannelName
    , description : Evergreen.V370.ChannelDescription.ChannelDescription
    , messages : Evergreen.V370.IdArray.IdArray Evergreen.V370.Id.ChannelMessageId (Evergreen.V370.Message.Message Evergreen.V370.Id.ChannelMessageId (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) (Evergreen.V370.Thread.LastTypedAt Evergreen.V370.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) Evergreen.V370.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V370.Drawing.Drawing (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) Evergreen.V370.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V370.Id.Id Evergreen.V370.Id.UserId
    , name : Evergreen.V370.GuildName.GuildName
    , icon : Maybe Evergreen.V370.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V370.MembersAndOwner.MembersAndOwner
            (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V370.SecretId.SecretId Evergreen.V370.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V370.Id.Id Evergreen.V370.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V370.ChannelName.ChannelName
    , description : Evergreen.V370.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V370.IdArray.IdArray Evergreen.V370.Id.ChannelMessageId (Evergreen.V370.Message.Message Evergreen.V370.Id.ChannelMessageId (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Thread.LastTypedAt Evergreen.V370.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V370.OneToOne.OneToOne (Evergreen.V370.Discord.Id Evergreen.V370.Discord.MessageId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) Evergreen.V370.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V370.Drawing.Drawing (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId))
    , permissionOverwrites : List Evergreen.V370.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V370.GuildName.GuildName
    , icon : Maybe Evergreen.V370.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V370.MembersAndOwner.MembersAndOwner
            (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V370.Discord.Id Evergreen.V370.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V370.Id.Id Evergreen.V370.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V370.Id.Id Evergreen.V370.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId
    , messages : List Evergreen.V370.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V370.Discord.Message
    , threads : List DiscordThreadReload
    }
