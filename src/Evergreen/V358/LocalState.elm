module Evergreen.V358.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V358.Call
import Evergreen.V358.ChannelDescription
import Evergreen.V358.ChannelName
import Evergreen.V358.Discord
import Evergreen.V358.DiscordUserData
import Evergreen.V358.DmChannel
import Evergreen.V358.DmChannelId
import Evergreen.V358.Drawing
import Evergreen.V358.FileStatus
import Evergreen.V358.Game
import Evergreen.V358.GuildName
import Evergreen.V358.Id
import Evergreen.V358.IdArray
import Evergreen.V358.Log
import Evergreen.V358.MembersAndOwner
import Evergreen.V358.Message
import Evergreen.V358.MessageArray
import Evergreen.V358.NonemptyDict
import Evergreen.V358.OneToOne
import Evergreen.V358.Pagination
import Evergreen.V358.Postmark
import Evergreen.V358.SecretId
import Evergreen.V358.SessionIdHash
import Evergreen.V358.Slack
import Evergreen.V358.TextEditor
import Evergreen.V358.Thread
import Evergreen.V358.ToBackendLog
import Evergreen.V358.User
import Evergreen.V358.UserSession
import Evergreen.V358.VisibleMessages
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
        Evergreen.V358.NonemptyDict.NonemptyDict
            (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V358.Message.Message Evergreen.V358.Id.ChannelMessageId (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V358.Discord.PartialUser
        , icon : Maybe Evergreen.V358.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V358.Discord.User
        , linkedTo : Evergreen.V358.Id.Id Evergreen.V358.Id.UserId
        , icon : Maybe Evergreen.V358.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V358.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V358.Discord.User
        , linkedTo : Evergreen.V358.Id.Id Evergreen.V358.Id.UserId
        , icon : Maybe Evergreen.V358.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V358.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V358.Message.Message Evergreen.V358.Id.ChannelMessageId (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId))
    , permissionOverwrites : List Evergreen.V358.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V358.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V358.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V358.MembersAndOwner.MembersAndOwner
            (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V358.Discord.Id Evergreen.V358.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V358.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V358.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V358.Id.Id Evergreen.V358.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V358.GuildName.GuildName
    , owner : Evergreen.V358.Id.Id Evergreen.V358.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V358.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V358.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V358.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V358.Call.RemoteCallData
    , currentlyViewing : Evergreen.V358.UserSession.Viewing
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V358.Id.Id Evergreen.V358.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V358.Id.Id Evergreen.V358.Id.UserId
    , name : Evergreen.V358.ChannelName.ChannelName
    , description : Evergreen.V358.ChannelDescription.ChannelDescription
    , messages : Evergreen.V358.MessageArray.MessageArray Evergreen.V358.Id.ChannelMessageId (Evergreen.V358.Message.Message Evergreen.V358.Id.ChannelMessageId (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId))
    , visibleMessages : Evergreen.V358.VisibleMessages.VisibleMessages Evergreen.V358.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) (Evergreen.V358.Thread.LastTypedAt Evergreen.V358.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) Evergreen.V358.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V358.Drawing.Drawing (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) Evergreen.V358.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V358.Id.Id Evergreen.V358.Id.UserId
    , name : Evergreen.V358.GuildName.GuildName
    , icon : Maybe Evergreen.V358.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V358.MembersAndOwner.MembersAndOwner
            (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V358.SecretId.SecretId Evergreen.V358.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V358.Id.Id Evergreen.V358.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V358.ChannelName.ChannelName
    , description : Evergreen.V358.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V358.MessageArray.MessageArray Evergreen.V358.Id.ChannelMessageId (Evergreen.V358.Message.Message Evergreen.V358.Id.ChannelMessageId (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId))
    , visibleMessages : Evergreen.V358.VisibleMessages.VisibleMessages Evergreen.V358.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Thread.LastTypedAt Evergreen.V358.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) Evergreen.V358.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V358.Drawing.Drawing (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId))
    , permissionOverwrites : List Evergreen.V358.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V358.GuildName.GuildName
    , icon : Maybe Evergreen.V358.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V358.MembersAndOwner.MembersAndOwner
            (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V358.Discord.Id Evergreen.V358.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V358.Id.Id Evergreen.V358.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V358.Id.Id Evergreen.V358.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V358.NonemptyDict.NonemptyDict (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) Evergreen.V358.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V358.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V358.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V358.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V358.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V358.SessionIdHash.SessionIdHash (Evergreen.V358.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V358.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V358.SessionIdHash.SessionIdHash Evergreen.V358.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) Evergreen.V358.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId) Evergreen.V358.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V358.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V358.SessionIdHash.SessionIdHash Evergreen.V358.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V358.TextEditor.LocalState
    , calls : Evergreen.V358.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V358.Id.Id Evergreen.V358.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V358.Id.Id Evergreen.V358.Id.UserId
    , name : Evergreen.V358.ChannelName.ChannelName
    , description : Evergreen.V358.ChannelDescription.ChannelDescription
    , messages : Evergreen.V358.IdArray.IdArray Evergreen.V358.Id.ChannelMessageId (Evergreen.V358.Message.Message Evergreen.V358.Id.ChannelMessageId (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) (Evergreen.V358.Thread.LastTypedAt Evergreen.V358.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) Evergreen.V358.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V358.Drawing.Drawing (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) Evergreen.V358.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V358.Id.Id Evergreen.V358.Id.UserId
    , name : Evergreen.V358.GuildName.GuildName
    , icon : Maybe Evergreen.V358.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V358.MembersAndOwner.MembersAndOwner
            (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V358.SecretId.SecretId Evergreen.V358.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V358.Id.Id Evergreen.V358.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V358.ChannelName.ChannelName
    , description : Evergreen.V358.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V358.IdArray.IdArray Evergreen.V358.Id.ChannelMessageId (Evergreen.V358.Message.Message Evergreen.V358.Id.ChannelMessageId (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Thread.LastTypedAt Evergreen.V358.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V358.OneToOne.OneToOne (Evergreen.V358.Discord.Id Evergreen.V358.Discord.MessageId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) Evergreen.V358.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V358.Drawing.Drawing (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId))
    , permissionOverwrites : List Evergreen.V358.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V358.GuildName.GuildName
    , icon : Maybe Evergreen.V358.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V358.MembersAndOwner.MembersAndOwner
            (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V358.Discord.Id Evergreen.V358.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V358.Id.Id Evergreen.V358.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V358.Id.Id Evergreen.V358.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId
    , messages : List Evergreen.V358.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V358.Discord.Message
    , threads : List DiscordThreadReload
    }
