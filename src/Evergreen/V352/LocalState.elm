module Evergreen.V352.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V352.Call
import Evergreen.V352.ChannelDescription
import Evergreen.V352.ChannelName
import Evergreen.V352.Discord
import Evergreen.V352.DiscordUserData
import Evergreen.V352.DmChannel
import Evergreen.V352.DmChannelId
import Evergreen.V352.Drawing
import Evergreen.V352.FileStatus
import Evergreen.V352.Game
import Evergreen.V352.GuildName
import Evergreen.V352.Id
import Evergreen.V352.IdArray
import Evergreen.V352.Log
import Evergreen.V352.MembersAndOwner
import Evergreen.V352.Message
import Evergreen.V352.MessageArray
import Evergreen.V352.NonemptyDict
import Evergreen.V352.OneToOne
import Evergreen.V352.Pagination
import Evergreen.V352.Postmark
import Evergreen.V352.SecretId
import Evergreen.V352.SessionIdHash
import Evergreen.V352.Slack
import Evergreen.V352.TextEditor
import Evergreen.V352.Thread
import Evergreen.V352.ToBackendLog
import Evergreen.V352.User
import Evergreen.V352.UserSession
import Evergreen.V352.VisibleMessages
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
        Evergreen.V352.NonemptyDict.NonemptyDict
            (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V352.Message.Message Evergreen.V352.Id.ChannelMessageId (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V352.Discord.PartialUser
        , icon : Maybe Evergreen.V352.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V352.Discord.User
        , linkedTo : Evergreen.V352.Id.Id Evergreen.V352.Id.UserId
        , icon : Maybe Evergreen.V352.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V352.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V352.Discord.User
        , linkedTo : Evergreen.V352.Id.Id Evergreen.V352.Id.UserId
        , icon : Maybe Evergreen.V352.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V352.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V352.Message.Message Evergreen.V352.Id.ChannelMessageId (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId))
    , permissionOverwrites : List Evergreen.V352.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V352.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V352.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V352.MembersAndOwner.MembersAndOwner
            (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V352.Discord.Id Evergreen.V352.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V352.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V352.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V352.Id.Id Evergreen.V352.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V352.GuildName.GuildName
    , owner : Evergreen.V352.Id.Id Evergreen.V352.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V352.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V352.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V352.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V352.Call.RemoteCallData
    , currentlyViewing : Evergreen.V352.UserSession.Viewing
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V352.Id.Id Evergreen.V352.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V352.Id.Id Evergreen.V352.Id.UserId
    , name : Evergreen.V352.ChannelName.ChannelName
    , description : Evergreen.V352.ChannelDescription.ChannelDescription
    , messages : Evergreen.V352.MessageArray.MessageArray Evergreen.V352.Id.ChannelMessageId (Evergreen.V352.Message.Message Evergreen.V352.Id.ChannelMessageId (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId))
    , visibleMessages : Evergreen.V352.VisibleMessages.VisibleMessages Evergreen.V352.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) (Evergreen.V352.Thread.LastTypedAt Evergreen.V352.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) Evergreen.V352.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V352.Drawing.Drawing (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) Evergreen.V352.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V352.Id.Id Evergreen.V352.Id.UserId
    , name : Evergreen.V352.GuildName.GuildName
    , icon : Maybe Evergreen.V352.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V352.MembersAndOwner.MembersAndOwner
            (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V352.SecretId.SecretId Evergreen.V352.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V352.Id.Id Evergreen.V352.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V352.ChannelName.ChannelName
    , description : Evergreen.V352.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V352.MessageArray.MessageArray Evergreen.V352.Id.ChannelMessageId (Evergreen.V352.Message.Message Evergreen.V352.Id.ChannelMessageId (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId))
    , visibleMessages : Evergreen.V352.VisibleMessages.VisibleMessages Evergreen.V352.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Thread.LastTypedAt Evergreen.V352.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) Evergreen.V352.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V352.Drawing.Drawing (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId))
    , permissionOverwrites : List Evergreen.V352.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V352.GuildName.GuildName
    , icon : Maybe Evergreen.V352.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V352.MembersAndOwner.MembersAndOwner
            (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V352.Discord.Id Evergreen.V352.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V352.Id.Id Evergreen.V352.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V352.Id.Id Evergreen.V352.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V352.NonemptyDict.NonemptyDict (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) Evergreen.V352.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V352.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V352.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V352.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V352.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V352.SessionIdHash.SessionIdHash (Evergreen.V352.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V352.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V352.SessionIdHash.SessionIdHash Evergreen.V352.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) Evergreen.V352.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId) Evergreen.V352.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V352.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V352.SessionIdHash.SessionIdHash Evergreen.V352.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V352.TextEditor.LocalState
    , calls : Evergreen.V352.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V352.Id.Id Evergreen.V352.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V352.Id.Id Evergreen.V352.Id.UserId
    , name : Evergreen.V352.ChannelName.ChannelName
    , description : Evergreen.V352.ChannelDescription.ChannelDescription
    , messages : Evergreen.V352.IdArray.IdArray Evergreen.V352.Id.ChannelMessageId (Evergreen.V352.Message.Message Evergreen.V352.Id.ChannelMessageId (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) (Evergreen.V352.Thread.LastTypedAt Evergreen.V352.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) Evergreen.V352.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V352.Drawing.Drawing (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) Evergreen.V352.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V352.Id.Id Evergreen.V352.Id.UserId
    , name : Evergreen.V352.GuildName.GuildName
    , icon : Maybe Evergreen.V352.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V352.MembersAndOwner.MembersAndOwner
            (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V352.SecretId.SecretId Evergreen.V352.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V352.Id.Id Evergreen.V352.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V352.ChannelName.ChannelName
    , description : Evergreen.V352.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V352.IdArray.IdArray Evergreen.V352.Id.ChannelMessageId (Evergreen.V352.Message.Message Evergreen.V352.Id.ChannelMessageId (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Thread.LastTypedAt Evergreen.V352.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V352.OneToOne.OneToOne (Evergreen.V352.Discord.Id Evergreen.V352.Discord.MessageId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) Evergreen.V352.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V352.Drawing.Drawing (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId))
    , permissionOverwrites : List Evergreen.V352.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V352.GuildName.GuildName
    , icon : Maybe Evergreen.V352.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V352.MembersAndOwner.MembersAndOwner
            (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V352.Discord.Id Evergreen.V352.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V352.Id.Id Evergreen.V352.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V352.Id.Id Evergreen.V352.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId
    , messages : List Evergreen.V352.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V352.Discord.Message
    , threads : List DiscordThreadReload
    }
