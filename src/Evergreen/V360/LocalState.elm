module Evergreen.V360.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V360.Call
import Evergreen.V360.ChannelDescription
import Evergreen.V360.ChannelName
import Evergreen.V360.Discord
import Evergreen.V360.DiscordUserData
import Evergreen.V360.DmChannel
import Evergreen.V360.DmChannelId
import Evergreen.V360.Drawing
import Evergreen.V360.FileStatus
import Evergreen.V360.Game
import Evergreen.V360.GuildName
import Evergreen.V360.Id
import Evergreen.V360.IdArray
import Evergreen.V360.Log
import Evergreen.V360.MembersAndOwner
import Evergreen.V360.Message
import Evergreen.V360.MessageArray
import Evergreen.V360.NonemptyDict
import Evergreen.V360.OneToOne
import Evergreen.V360.Pagination
import Evergreen.V360.Postmark
import Evergreen.V360.SecretId
import Evergreen.V360.SessionIdHash
import Evergreen.V360.Slack
import Evergreen.V360.TextEditor
import Evergreen.V360.Thread
import Evergreen.V360.ToBackendLog
import Evergreen.V360.User
import Evergreen.V360.UserSession
import Evergreen.V360.VisibleMessages
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
        Evergreen.V360.NonemptyDict.NonemptyDict
            (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V360.Message.Message Evergreen.V360.Id.ChannelMessageId (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V360.Discord.PartialUser
        , icon : Maybe Evergreen.V360.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V360.Discord.User
        , linkedTo : Evergreen.V360.Id.Id Evergreen.V360.Id.UserId
        , icon : Maybe Evergreen.V360.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V360.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V360.Discord.User
        , linkedTo : Evergreen.V360.Id.Id Evergreen.V360.Id.UserId
        , icon : Maybe Evergreen.V360.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V360.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V360.Message.Message Evergreen.V360.Id.ChannelMessageId (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId))
    , permissionOverwrites : List Evergreen.V360.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V360.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V360.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V360.MembersAndOwner.MembersAndOwner
            (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V360.Discord.Id Evergreen.V360.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V360.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V360.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V360.Id.Id Evergreen.V360.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V360.GuildName.GuildName
    , owner : Evergreen.V360.Id.Id Evergreen.V360.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V360.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V360.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V360.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V360.Call.RemoteCallData
    , currentlyViewing : Evergreen.V360.UserSession.Viewing
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V360.Id.Id Evergreen.V360.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V360.Id.Id Evergreen.V360.Id.UserId
    , name : Evergreen.V360.ChannelName.ChannelName
    , description : Evergreen.V360.ChannelDescription.ChannelDescription
    , messages : Evergreen.V360.MessageArray.MessageArray Evergreen.V360.Id.ChannelMessageId (Evergreen.V360.Message.Message Evergreen.V360.Id.ChannelMessageId (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId))
    , visibleMessages : Evergreen.V360.VisibleMessages.VisibleMessages Evergreen.V360.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) (Evergreen.V360.Thread.LastTypedAt Evergreen.V360.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) Evergreen.V360.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V360.Drawing.Drawing (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) Evergreen.V360.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V360.Id.Id Evergreen.V360.Id.UserId
    , name : Evergreen.V360.GuildName.GuildName
    , icon : Maybe Evergreen.V360.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V360.MembersAndOwner.MembersAndOwner
            (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V360.SecretId.SecretId Evergreen.V360.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V360.Id.Id Evergreen.V360.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V360.ChannelName.ChannelName
    , description : Evergreen.V360.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V360.MessageArray.MessageArray Evergreen.V360.Id.ChannelMessageId (Evergreen.V360.Message.Message Evergreen.V360.Id.ChannelMessageId (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId))
    , visibleMessages : Evergreen.V360.VisibleMessages.VisibleMessages Evergreen.V360.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Thread.LastTypedAt Evergreen.V360.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) Evergreen.V360.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V360.Drawing.Drawing (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId))
    , permissionOverwrites : List Evergreen.V360.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V360.GuildName.GuildName
    , icon : Maybe Evergreen.V360.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V360.MembersAndOwner.MembersAndOwner
            (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V360.Discord.Id Evergreen.V360.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V360.Id.Id Evergreen.V360.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V360.Id.Id Evergreen.V360.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V360.NonemptyDict.NonemptyDict (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) Evergreen.V360.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V360.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V360.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V360.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V360.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V360.SessionIdHash.SessionIdHash (Evergreen.V360.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V360.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V360.SessionIdHash.SessionIdHash Evergreen.V360.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) Evergreen.V360.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId) Evergreen.V360.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V360.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V360.SessionIdHash.SessionIdHash Evergreen.V360.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V360.TextEditor.LocalState
    , calls : Evergreen.V360.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V360.Id.Id Evergreen.V360.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V360.Id.Id Evergreen.V360.Id.UserId
    , name : Evergreen.V360.ChannelName.ChannelName
    , description : Evergreen.V360.ChannelDescription.ChannelDescription
    , messages : Evergreen.V360.IdArray.IdArray Evergreen.V360.Id.ChannelMessageId (Evergreen.V360.Message.Message Evergreen.V360.Id.ChannelMessageId (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) (Evergreen.V360.Thread.LastTypedAt Evergreen.V360.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) Evergreen.V360.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V360.Drawing.Drawing (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) Evergreen.V360.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V360.Id.Id Evergreen.V360.Id.UserId
    , name : Evergreen.V360.GuildName.GuildName
    , icon : Maybe Evergreen.V360.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V360.MembersAndOwner.MembersAndOwner
            (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V360.SecretId.SecretId Evergreen.V360.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V360.Id.Id Evergreen.V360.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V360.ChannelName.ChannelName
    , description : Evergreen.V360.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V360.IdArray.IdArray Evergreen.V360.Id.ChannelMessageId (Evergreen.V360.Message.Message Evergreen.V360.Id.ChannelMessageId (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Thread.LastTypedAt Evergreen.V360.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V360.OneToOne.OneToOne (Evergreen.V360.Discord.Id Evergreen.V360.Discord.MessageId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) Evergreen.V360.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V360.Drawing.Drawing (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId))
    , permissionOverwrites : List Evergreen.V360.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V360.GuildName.GuildName
    , icon : Maybe Evergreen.V360.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V360.MembersAndOwner.MembersAndOwner
            (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V360.Discord.Id Evergreen.V360.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V360.Id.Id Evergreen.V360.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V360.Id.Id Evergreen.V360.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId
    , messages : List Evergreen.V360.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V360.Discord.Message
    , threads : List DiscordThreadReload
    }
