module Evergreen.V354.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V354.Call
import Evergreen.V354.ChannelDescription
import Evergreen.V354.ChannelName
import Evergreen.V354.Discord
import Evergreen.V354.DiscordUserData
import Evergreen.V354.DmChannel
import Evergreen.V354.DmChannelId
import Evergreen.V354.Drawing
import Evergreen.V354.FileStatus
import Evergreen.V354.Game
import Evergreen.V354.GuildName
import Evergreen.V354.Id
import Evergreen.V354.IdArray
import Evergreen.V354.Log
import Evergreen.V354.MembersAndOwner
import Evergreen.V354.Message
import Evergreen.V354.MessageArray
import Evergreen.V354.NonemptyDict
import Evergreen.V354.OneToOne
import Evergreen.V354.Pagination
import Evergreen.V354.Postmark
import Evergreen.V354.SecretId
import Evergreen.V354.SessionIdHash
import Evergreen.V354.Slack
import Evergreen.V354.TextEditor
import Evergreen.V354.Thread
import Evergreen.V354.ToBackendLog
import Evergreen.V354.User
import Evergreen.V354.UserSession
import Evergreen.V354.VisibleMessages
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
        Evergreen.V354.NonemptyDict.NonemptyDict
            (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V354.Message.Message Evergreen.V354.Id.ChannelMessageId (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V354.Discord.PartialUser
        , icon : Maybe Evergreen.V354.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V354.Discord.User
        , linkedTo : Evergreen.V354.Id.Id Evergreen.V354.Id.UserId
        , icon : Maybe Evergreen.V354.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V354.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V354.Discord.User
        , linkedTo : Evergreen.V354.Id.Id Evergreen.V354.Id.UserId
        , icon : Maybe Evergreen.V354.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V354.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V354.Message.Message Evergreen.V354.Id.ChannelMessageId (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId))
    , permissionOverwrites : List Evergreen.V354.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V354.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V354.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V354.MembersAndOwner.MembersAndOwner
            (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V354.Discord.Id Evergreen.V354.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V354.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V354.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V354.Id.Id Evergreen.V354.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V354.GuildName.GuildName
    , owner : Evergreen.V354.Id.Id Evergreen.V354.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V354.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V354.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V354.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V354.Call.RemoteCallData
    , currentlyViewing : Evergreen.V354.UserSession.Viewing
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V354.Id.Id Evergreen.V354.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V354.Id.Id Evergreen.V354.Id.UserId
    , name : Evergreen.V354.ChannelName.ChannelName
    , description : Evergreen.V354.ChannelDescription.ChannelDescription
    , messages : Evergreen.V354.MessageArray.MessageArray Evergreen.V354.Id.ChannelMessageId (Evergreen.V354.Message.Message Evergreen.V354.Id.ChannelMessageId (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId))
    , visibleMessages : Evergreen.V354.VisibleMessages.VisibleMessages Evergreen.V354.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) (Evergreen.V354.Thread.LastTypedAt Evergreen.V354.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) Evergreen.V354.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V354.Drawing.Drawing (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) Evergreen.V354.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V354.Id.Id Evergreen.V354.Id.UserId
    , name : Evergreen.V354.GuildName.GuildName
    , icon : Maybe Evergreen.V354.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V354.MembersAndOwner.MembersAndOwner
            (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V354.SecretId.SecretId Evergreen.V354.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V354.Id.Id Evergreen.V354.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V354.ChannelName.ChannelName
    , description : Evergreen.V354.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V354.MessageArray.MessageArray Evergreen.V354.Id.ChannelMessageId (Evergreen.V354.Message.Message Evergreen.V354.Id.ChannelMessageId (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId))
    , visibleMessages : Evergreen.V354.VisibleMessages.VisibleMessages Evergreen.V354.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Thread.LastTypedAt Evergreen.V354.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) Evergreen.V354.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V354.Drawing.Drawing (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId))
    , permissionOverwrites : List Evergreen.V354.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V354.GuildName.GuildName
    , icon : Maybe Evergreen.V354.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V354.MembersAndOwner.MembersAndOwner
            (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V354.Discord.Id Evergreen.V354.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V354.Id.Id Evergreen.V354.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V354.Id.Id Evergreen.V354.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V354.NonemptyDict.NonemptyDict (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) Evergreen.V354.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V354.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V354.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V354.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V354.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V354.SessionIdHash.SessionIdHash (Evergreen.V354.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V354.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V354.SessionIdHash.SessionIdHash Evergreen.V354.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) Evergreen.V354.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId) Evergreen.V354.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V354.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V354.SessionIdHash.SessionIdHash Evergreen.V354.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V354.TextEditor.LocalState
    , calls : Evergreen.V354.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V354.Id.Id Evergreen.V354.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V354.Id.Id Evergreen.V354.Id.UserId
    , name : Evergreen.V354.ChannelName.ChannelName
    , description : Evergreen.V354.ChannelDescription.ChannelDescription
    , messages : Evergreen.V354.IdArray.IdArray Evergreen.V354.Id.ChannelMessageId (Evergreen.V354.Message.Message Evergreen.V354.Id.ChannelMessageId (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) (Evergreen.V354.Thread.LastTypedAt Evergreen.V354.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) Evergreen.V354.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V354.Drawing.Drawing (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) Evergreen.V354.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V354.Id.Id Evergreen.V354.Id.UserId
    , name : Evergreen.V354.GuildName.GuildName
    , icon : Maybe Evergreen.V354.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V354.MembersAndOwner.MembersAndOwner
            (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V354.SecretId.SecretId Evergreen.V354.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V354.Id.Id Evergreen.V354.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V354.ChannelName.ChannelName
    , description : Evergreen.V354.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V354.IdArray.IdArray Evergreen.V354.Id.ChannelMessageId (Evergreen.V354.Message.Message Evergreen.V354.Id.ChannelMessageId (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Thread.LastTypedAt Evergreen.V354.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V354.OneToOne.OneToOne (Evergreen.V354.Discord.Id Evergreen.V354.Discord.MessageId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) Evergreen.V354.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V354.Drawing.Drawing (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId))
    , permissionOverwrites : List Evergreen.V354.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V354.GuildName.GuildName
    , icon : Maybe Evergreen.V354.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V354.MembersAndOwner.MembersAndOwner
            (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V354.Discord.Id Evergreen.V354.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V354.Id.Id Evergreen.V354.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V354.Id.Id Evergreen.V354.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId
    , messages : List Evergreen.V354.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V354.Discord.Message
    , threads : List DiscordThreadReload
    }
