module Evergreen.V364.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V364.Call
import Evergreen.V364.ChannelDescription
import Evergreen.V364.ChannelName
import Evergreen.V364.Discord
import Evergreen.V364.DiscordUserData
import Evergreen.V364.DmChannel
import Evergreen.V364.DmChannelId
import Evergreen.V364.Drawing
import Evergreen.V364.FileStatus
import Evergreen.V364.Game
import Evergreen.V364.GuildName
import Evergreen.V364.Id
import Evergreen.V364.IdArray
import Evergreen.V364.Log
import Evergreen.V364.MembersAndOwner
import Evergreen.V364.Message
import Evergreen.V364.MessageArray
import Evergreen.V364.NonemptyDict
import Evergreen.V364.OneToOne
import Evergreen.V364.Pagination
import Evergreen.V364.Postmark
import Evergreen.V364.SecretId
import Evergreen.V364.SessionIdHash
import Evergreen.V364.Slack
import Evergreen.V364.TextEditor
import Evergreen.V364.Thread
import Evergreen.V364.ToBackendLog
import Evergreen.V364.User
import Evergreen.V364.UserSession
import Evergreen.V364.VisibleMessages
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
        Evergreen.V364.NonemptyDict.NonemptyDict
            (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V364.Message.Message Evergreen.V364.Id.ChannelMessageId (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V364.Discord.PartialUser
        , icon : Maybe Evergreen.V364.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V364.Discord.User
        , linkedTo : Evergreen.V364.Id.Id Evergreen.V364.Id.UserId
        , icon : Maybe Evergreen.V364.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V364.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V364.Discord.User
        , linkedTo : Evergreen.V364.Id.Id Evergreen.V364.Id.UserId
        , icon : Maybe Evergreen.V364.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V364.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V364.Message.Message Evergreen.V364.Id.ChannelMessageId (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId))
    , permissionOverwrites : List Evergreen.V364.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V364.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V364.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V364.MembersAndOwner.MembersAndOwner
            (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V364.Discord.Id Evergreen.V364.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V364.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V364.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V364.Id.Id Evergreen.V364.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V364.GuildName.GuildName
    , owner : Evergreen.V364.Id.Id Evergreen.V364.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V364.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V364.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V364.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V364.Call.RemoteCallData
    , currentlyViewing : Evergreen.V364.UserSession.Viewing
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V364.Id.Id Evergreen.V364.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V364.Id.Id Evergreen.V364.Id.UserId
    , name : Evergreen.V364.ChannelName.ChannelName
    , description : Evergreen.V364.ChannelDescription.ChannelDescription
    , messages : Evergreen.V364.MessageArray.MessageArray Evergreen.V364.Id.ChannelMessageId (Evergreen.V364.Message.Message Evergreen.V364.Id.ChannelMessageId (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId))
    , visibleMessages : Evergreen.V364.VisibleMessages.VisibleMessages Evergreen.V364.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) (Evergreen.V364.Thread.LastTypedAt Evergreen.V364.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) Evergreen.V364.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V364.Drawing.Drawing (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) Evergreen.V364.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V364.Id.Id Evergreen.V364.Id.UserId
    , name : Evergreen.V364.GuildName.GuildName
    , icon : Maybe Evergreen.V364.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V364.MembersAndOwner.MembersAndOwner
            (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V364.SecretId.SecretId Evergreen.V364.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V364.Id.Id Evergreen.V364.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V364.ChannelName.ChannelName
    , description : Evergreen.V364.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V364.MessageArray.MessageArray Evergreen.V364.Id.ChannelMessageId (Evergreen.V364.Message.Message Evergreen.V364.Id.ChannelMessageId (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId))
    , visibleMessages : Evergreen.V364.VisibleMessages.VisibleMessages Evergreen.V364.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Thread.LastTypedAt Evergreen.V364.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) Evergreen.V364.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V364.Drawing.Drawing (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId))
    , permissionOverwrites : List Evergreen.V364.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V364.GuildName.GuildName
    , icon : Maybe Evergreen.V364.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V364.MembersAndOwner.MembersAndOwner
            (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V364.Discord.Id Evergreen.V364.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V364.Id.Id Evergreen.V364.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V364.Id.Id Evergreen.V364.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V364.NonemptyDict.NonemptyDict (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) Evergreen.V364.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V364.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V364.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V364.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V364.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V364.SessionIdHash.SessionIdHash (Evergreen.V364.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V364.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V364.SessionIdHash.SessionIdHash Evergreen.V364.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) Evergreen.V364.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId) Evergreen.V364.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V364.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V364.SessionIdHash.SessionIdHash Evergreen.V364.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V364.TextEditor.LocalState
    , calls : Evergreen.V364.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V364.Id.Id Evergreen.V364.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V364.Id.Id Evergreen.V364.Id.UserId
    , name : Evergreen.V364.ChannelName.ChannelName
    , description : Evergreen.V364.ChannelDescription.ChannelDescription
    , messages : Evergreen.V364.IdArray.IdArray Evergreen.V364.Id.ChannelMessageId (Evergreen.V364.Message.Message Evergreen.V364.Id.ChannelMessageId (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) (Evergreen.V364.Thread.LastTypedAt Evergreen.V364.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) Evergreen.V364.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V364.Drawing.Drawing (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) Evergreen.V364.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V364.Id.Id Evergreen.V364.Id.UserId
    , name : Evergreen.V364.GuildName.GuildName
    , icon : Maybe Evergreen.V364.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V364.MembersAndOwner.MembersAndOwner
            (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V364.SecretId.SecretId Evergreen.V364.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V364.Id.Id Evergreen.V364.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V364.ChannelName.ChannelName
    , description : Evergreen.V364.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V364.IdArray.IdArray Evergreen.V364.Id.ChannelMessageId (Evergreen.V364.Message.Message Evergreen.V364.Id.ChannelMessageId (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Thread.LastTypedAt Evergreen.V364.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V364.OneToOne.OneToOne (Evergreen.V364.Discord.Id Evergreen.V364.Discord.MessageId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) Evergreen.V364.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V364.Drawing.Drawing (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId))
    , permissionOverwrites : List Evergreen.V364.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V364.GuildName.GuildName
    , icon : Maybe Evergreen.V364.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V364.MembersAndOwner.MembersAndOwner
            (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V364.Discord.Id Evergreen.V364.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V364.Id.Id Evergreen.V364.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V364.Id.Id Evergreen.V364.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId
    , messages : List Evergreen.V364.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V364.Discord.Message
    , threads : List DiscordThreadReload
    }
