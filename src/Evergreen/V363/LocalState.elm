module Evergreen.V363.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V363.Call
import Evergreen.V363.ChannelDescription
import Evergreen.V363.ChannelName
import Evergreen.V363.Discord
import Evergreen.V363.DiscordUserData
import Evergreen.V363.DmChannel
import Evergreen.V363.DmChannelId
import Evergreen.V363.Drawing
import Evergreen.V363.FileStatus
import Evergreen.V363.Game
import Evergreen.V363.GuildName
import Evergreen.V363.Id
import Evergreen.V363.IdArray
import Evergreen.V363.Log
import Evergreen.V363.MembersAndOwner
import Evergreen.V363.Message
import Evergreen.V363.MessageArray
import Evergreen.V363.NonemptyDict
import Evergreen.V363.OneToOne
import Evergreen.V363.Pagination
import Evergreen.V363.Postmark
import Evergreen.V363.SecretId
import Evergreen.V363.SessionIdHash
import Evergreen.V363.Slack
import Evergreen.V363.TextEditor
import Evergreen.V363.Thread
import Evergreen.V363.ToBackendLog
import Evergreen.V363.User
import Evergreen.V363.UserSession
import Evergreen.V363.VisibleMessages
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
        Evergreen.V363.NonemptyDict.NonemptyDict
            (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V363.Message.Message Evergreen.V363.Id.ChannelMessageId (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V363.Discord.PartialUser
        , icon : Maybe Evergreen.V363.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V363.Discord.User
        , linkedTo : Evergreen.V363.Id.Id Evergreen.V363.Id.UserId
        , icon : Maybe Evergreen.V363.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V363.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V363.Discord.User
        , linkedTo : Evergreen.V363.Id.Id Evergreen.V363.Id.UserId
        , icon : Maybe Evergreen.V363.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V363.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V363.Message.Message Evergreen.V363.Id.ChannelMessageId (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId))
    , permissionOverwrites : List Evergreen.V363.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V363.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V363.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V363.MembersAndOwner.MembersAndOwner
            (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V363.Discord.Id Evergreen.V363.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V363.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V363.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V363.Id.Id Evergreen.V363.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V363.GuildName.GuildName
    , owner : Evergreen.V363.Id.Id Evergreen.V363.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V363.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V363.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V363.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V363.Call.RemoteCallData
    , currentlyViewing : Evergreen.V363.UserSession.Viewing
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V363.Id.Id Evergreen.V363.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V363.Id.Id Evergreen.V363.Id.UserId
    , name : Evergreen.V363.ChannelName.ChannelName
    , description : Evergreen.V363.ChannelDescription.ChannelDescription
    , messages : Evergreen.V363.MessageArray.MessageArray Evergreen.V363.Id.ChannelMessageId (Evergreen.V363.Message.Message Evergreen.V363.Id.ChannelMessageId (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId))
    , visibleMessages : Evergreen.V363.VisibleMessages.VisibleMessages Evergreen.V363.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) (Evergreen.V363.Thread.LastTypedAt Evergreen.V363.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) Evergreen.V363.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V363.Drawing.Drawing (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) Evergreen.V363.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V363.Id.Id Evergreen.V363.Id.UserId
    , name : Evergreen.V363.GuildName.GuildName
    , icon : Maybe Evergreen.V363.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V363.MembersAndOwner.MembersAndOwner
            (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V363.SecretId.SecretId Evergreen.V363.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V363.Id.Id Evergreen.V363.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V363.ChannelName.ChannelName
    , description : Evergreen.V363.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V363.MessageArray.MessageArray Evergreen.V363.Id.ChannelMessageId (Evergreen.V363.Message.Message Evergreen.V363.Id.ChannelMessageId (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId))
    , visibleMessages : Evergreen.V363.VisibleMessages.VisibleMessages Evergreen.V363.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Thread.LastTypedAt Evergreen.V363.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) Evergreen.V363.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V363.Drawing.Drawing (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId))
    , permissionOverwrites : List Evergreen.V363.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V363.GuildName.GuildName
    , icon : Maybe Evergreen.V363.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V363.MembersAndOwner.MembersAndOwner
            (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V363.Discord.Id Evergreen.V363.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V363.Id.Id Evergreen.V363.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V363.Id.Id Evergreen.V363.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V363.NonemptyDict.NonemptyDict (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) Evergreen.V363.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V363.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V363.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V363.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V363.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V363.SessionIdHash.SessionIdHash (Evergreen.V363.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V363.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V363.SessionIdHash.SessionIdHash Evergreen.V363.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) Evergreen.V363.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId) Evergreen.V363.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V363.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V363.SessionIdHash.SessionIdHash Evergreen.V363.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V363.TextEditor.LocalState
    , calls : Evergreen.V363.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V363.Id.Id Evergreen.V363.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V363.Id.Id Evergreen.V363.Id.UserId
    , name : Evergreen.V363.ChannelName.ChannelName
    , description : Evergreen.V363.ChannelDescription.ChannelDescription
    , messages : Evergreen.V363.IdArray.IdArray Evergreen.V363.Id.ChannelMessageId (Evergreen.V363.Message.Message Evergreen.V363.Id.ChannelMessageId (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) (Evergreen.V363.Thread.LastTypedAt Evergreen.V363.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) Evergreen.V363.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V363.Drawing.Drawing (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) Evergreen.V363.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V363.Id.Id Evergreen.V363.Id.UserId
    , name : Evergreen.V363.GuildName.GuildName
    , icon : Maybe Evergreen.V363.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V363.MembersAndOwner.MembersAndOwner
            (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V363.SecretId.SecretId Evergreen.V363.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V363.Id.Id Evergreen.V363.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V363.ChannelName.ChannelName
    , description : Evergreen.V363.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V363.IdArray.IdArray Evergreen.V363.Id.ChannelMessageId (Evergreen.V363.Message.Message Evergreen.V363.Id.ChannelMessageId (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Thread.LastTypedAt Evergreen.V363.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V363.OneToOne.OneToOne (Evergreen.V363.Discord.Id Evergreen.V363.Discord.MessageId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) Evergreen.V363.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V363.Drawing.Drawing (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId))
    , permissionOverwrites : List Evergreen.V363.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V363.GuildName.GuildName
    , icon : Maybe Evergreen.V363.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V363.MembersAndOwner.MembersAndOwner
            (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V363.Discord.Id Evergreen.V363.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V363.Id.Id Evergreen.V363.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V363.Id.Id Evergreen.V363.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId
    , messages : List Evergreen.V363.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V363.Discord.Message
    , threads : List DiscordThreadReload
    }
