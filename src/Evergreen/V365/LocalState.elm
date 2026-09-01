module Evergreen.V365.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V365.Call
import Evergreen.V365.ChannelDescription
import Evergreen.V365.ChannelName
import Evergreen.V365.Discord
import Evergreen.V365.DiscordUserData
import Evergreen.V365.DmChannel
import Evergreen.V365.DmChannelId
import Evergreen.V365.Drawing
import Evergreen.V365.FileStatus
import Evergreen.V365.Game
import Evergreen.V365.GuildName
import Evergreen.V365.Id
import Evergreen.V365.IdArray
import Evergreen.V365.Log
import Evergreen.V365.MembersAndOwner
import Evergreen.V365.Message
import Evergreen.V365.MessageArray
import Evergreen.V365.NonemptyDict
import Evergreen.V365.OneToOne
import Evergreen.V365.Pagination
import Evergreen.V365.Postmark
import Evergreen.V365.SecretId
import Evergreen.V365.SessionIdHash
import Evergreen.V365.Slack
import Evergreen.V365.TextEditor
import Evergreen.V365.Thread
import Evergreen.V365.ToBackendLog
import Evergreen.V365.User
import Evergreen.V365.UserSession
import Evergreen.V365.VisibleMessages
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
        Evergreen.V365.NonemptyDict.NonemptyDict
            (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V365.Message.Message Evergreen.V365.Id.ChannelMessageId (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V365.Discord.PartialUser
        , icon : Maybe Evergreen.V365.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V365.Discord.User
        , linkedTo : Evergreen.V365.Id.Id Evergreen.V365.Id.UserId
        , icon : Maybe Evergreen.V365.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V365.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V365.Discord.User
        , linkedTo : Evergreen.V365.Id.Id Evergreen.V365.Id.UserId
        , icon : Maybe Evergreen.V365.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V365.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V365.Message.Message Evergreen.V365.Id.ChannelMessageId (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId))
    , permissionOverwrites : List Evergreen.V365.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V365.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V365.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V365.MembersAndOwner.MembersAndOwner
            (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V365.Discord.Id Evergreen.V365.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V365.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V365.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V365.Id.Id Evergreen.V365.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V365.GuildName.GuildName
    , owner : Evergreen.V365.Id.Id Evergreen.V365.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V365.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V365.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V365.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V365.Call.RemoteCallData
    , currentlyViewing : Evergreen.V365.UserSession.Viewing
    }


type BackupContents
    = FullBackup
    | SubsetBackup


type alias LastBackup =
    { createdAt : Effect.Time.Posix
    , contents : BackupContents
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V365.Id.Id Evergreen.V365.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V365.Id.Id Evergreen.V365.Id.UserId
    , name : Evergreen.V365.ChannelName.ChannelName
    , description : Evergreen.V365.ChannelDescription.ChannelDescription
    , messages : Evergreen.V365.MessageArray.MessageArray Evergreen.V365.Id.ChannelMessageId (Evergreen.V365.Message.Message Evergreen.V365.Id.ChannelMessageId (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId))
    , visibleMessages : Evergreen.V365.VisibleMessages.VisibleMessages Evergreen.V365.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) (Evergreen.V365.Thread.LastTypedAt Evergreen.V365.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) Evergreen.V365.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V365.Drawing.Drawing (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) Evergreen.V365.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V365.Id.Id Evergreen.V365.Id.UserId
    , name : Evergreen.V365.GuildName.GuildName
    , icon : Maybe Evergreen.V365.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V365.MembersAndOwner.MembersAndOwner
            (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V365.SecretId.SecretId Evergreen.V365.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V365.Id.Id Evergreen.V365.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V365.ChannelName.ChannelName
    , description : Evergreen.V365.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V365.MessageArray.MessageArray Evergreen.V365.Id.ChannelMessageId (Evergreen.V365.Message.Message Evergreen.V365.Id.ChannelMessageId (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId))
    , visibleMessages : Evergreen.V365.VisibleMessages.VisibleMessages Evergreen.V365.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Thread.LastTypedAt Evergreen.V365.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) Evergreen.V365.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V365.Drawing.Drawing (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId))
    , permissionOverwrites : List Evergreen.V365.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V365.GuildName.GuildName
    , icon : Maybe Evergreen.V365.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V365.MembersAndOwner.MembersAndOwner
            (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V365.Discord.Id Evergreen.V365.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V365.Id.Id Evergreen.V365.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V365.Id.Id Evergreen.V365.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V365.NonemptyDict.NonemptyDict (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) Evergreen.V365.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V365.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V365.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V365.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V365.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V365.SessionIdHash.SessionIdHash (Evergreen.V365.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V365.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , lastBackup : Maybe LastBackup
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V365.SessionIdHash.SessionIdHash Evergreen.V365.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) Evergreen.V365.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId) Evergreen.V365.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V365.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V365.SessionIdHash.SessionIdHash Evergreen.V365.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V365.TextEditor.LocalState
    , calls : Evergreen.V365.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V365.Id.Id Evergreen.V365.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V365.Id.Id Evergreen.V365.Id.UserId
    , name : Evergreen.V365.ChannelName.ChannelName
    , description : Evergreen.V365.ChannelDescription.ChannelDescription
    , messages : Evergreen.V365.IdArray.IdArray Evergreen.V365.Id.ChannelMessageId (Evergreen.V365.Message.Message Evergreen.V365.Id.ChannelMessageId (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) (Evergreen.V365.Thread.LastTypedAt Evergreen.V365.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) Evergreen.V365.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V365.Drawing.Drawing (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) Evergreen.V365.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V365.Id.Id Evergreen.V365.Id.UserId
    , name : Evergreen.V365.GuildName.GuildName
    , icon : Maybe Evergreen.V365.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V365.MembersAndOwner.MembersAndOwner
            (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V365.SecretId.SecretId Evergreen.V365.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V365.Id.Id Evergreen.V365.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V365.ChannelName.ChannelName
    , description : Evergreen.V365.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V365.IdArray.IdArray Evergreen.V365.Id.ChannelMessageId (Evergreen.V365.Message.Message Evergreen.V365.Id.ChannelMessageId (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Thread.LastTypedAt Evergreen.V365.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V365.OneToOne.OneToOne (Evergreen.V365.Discord.Id Evergreen.V365.Discord.MessageId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) Evergreen.V365.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V365.Drawing.Drawing (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId))
    , permissionOverwrites : List Evergreen.V365.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V365.GuildName.GuildName
    , icon : Maybe Evergreen.V365.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V365.MembersAndOwner.MembersAndOwner
            (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V365.Discord.Id Evergreen.V365.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V365.Id.Id Evergreen.V365.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V365.Id.Id Evergreen.V365.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId
    , messages : List Evergreen.V365.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V365.Discord.Message
    , threads : List DiscordThreadReload
    }
