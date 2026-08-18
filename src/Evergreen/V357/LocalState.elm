module Evergreen.V357.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V357.Call
import Evergreen.V357.ChannelDescription
import Evergreen.V357.ChannelName
import Evergreen.V357.Discord
import Evergreen.V357.DiscordUserData
import Evergreen.V357.DmChannel
import Evergreen.V357.DmChannelId
import Evergreen.V357.Drawing
import Evergreen.V357.FileStatus
import Evergreen.V357.Game
import Evergreen.V357.GuildName
import Evergreen.V357.Id
import Evergreen.V357.IdArray
import Evergreen.V357.Log
import Evergreen.V357.MembersAndOwner
import Evergreen.V357.Message
import Evergreen.V357.MessageArray
import Evergreen.V357.NonemptyDict
import Evergreen.V357.OneToOne
import Evergreen.V357.Pagination
import Evergreen.V357.Postmark
import Evergreen.V357.SecretId
import Evergreen.V357.SessionIdHash
import Evergreen.V357.Slack
import Evergreen.V357.TextEditor
import Evergreen.V357.Thread
import Evergreen.V357.ToBackendLog
import Evergreen.V357.User
import Evergreen.V357.UserSession
import Evergreen.V357.VisibleMessages
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
        Evergreen.V357.NonemptyDict.NonemptyDict
            (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V357.Message.Message Evergreen.V357.Id.ChannelMessageId (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V357.Discord.PartialUser
        , icon : Maybe Evergreen.V357.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V357.Discord.User
        , linkedTo : Evergreen.V357.Id.Id Evergreen.V357.Id.UserId
        , icon : Maybe Evergreen.V357.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V357.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V357.Discord.User
        , linkedTo : Evergreen.V357.Id.Id Evergreen.V357.Id.UserId
        , icon : Maybe Evergreen.V357.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V357.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V357.Message.Message Evergreen.V357.Id.ChannelMessageId (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId))
    , permissionOverwrites : List Evergreen.V357.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V357.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V357.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V357.MembersAndOwner.MembersAndOwner
            (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V357.Discord.Id Evergreen.V357.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V357.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V357.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V357.Id.Id Evergreen.V357.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V357.GuildName.GuildName
    , owner : Evergreen.V357.Id.Id Evergreen.V357.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V357.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V357.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V357.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V357.Call.RemoteCallData
    , currentlyViewing : Evergreen.V357.UserSession.Viewing
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V357.Id.Id Evergreen.V357.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V357.Id.Id Evergreen.V357.Id.UserId
    , name : Evergreen.V357.ChannelName.ChannelName
    , description : Evergreen.V357.ChannelDescription.ChannelDescription
    , messages : Evergreen.V357.MessageArray.MessageArray Evergreen.V357.Id.ChannelMessageId (Evergreen.V357.Message.Message Evergreen.V357.Id.ChannelMessageId (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId))
    , visibleMessages : Evergreen.V357.VisibleMessages.VisibleMessages Evergreen.V357.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) (Evergreen.V357.Thread.LastTypedAt Evergreen.V357.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) Evergreen.V357.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V357.Drawing.Drawing (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) Evergreen.V357.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V357.Id.Id Evergreen.V357.Id.UserId
    , name : Evergreen.V357.GuildName.GuildName
    , icon : Maybe Evergreen.V357.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V357.MembersAndOwner.MembersAndOwner
            (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V357.SecretId.SecretId Evergreen.V357.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V357.Id.Id Evergreen.V357.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V357.ChannelName.ChannelName
    , description : Evergreen.V357.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V357.MessageArray.MessageArray Evergreen.V357.Id.ChannelMessageId (Evergreen.V357.Message.Message Evergreen.V357.Id.ChannelMessageId (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId))
    , visibleMessages : Evergreen.V357.VisibleMessages.VisibleMessages Evergreen.V357.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Thread.LastTypedAt Evergreen.V357.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) Evergreen.V357.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V357.Drawing.Drawing (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId))
    , permissionOverwrites : List Evergreen.V357.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V357.GuildName.GuildName
    , icon : Maybe Evergreen.V357.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V357.MembersAndOwner.MembersAndOwner
            (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V357.Discord.Id Evergreen.V357.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V357.Id.Id Evergreen.V357.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V357.Id.Id Evergreen.V357.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V357.NonemptyDict.NonemptyDict (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Evergreen.V357.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V357.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V357.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V357.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V357.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V357.SessionIdHash.SessionIdHash (Evergreen.V357.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V357.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V357.SessionIdHash.SessionIdHash Evergreen.V357.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Evergreen.V357.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId) Evergreen.V357.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V357.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V357.SessionIdHash.SessionIdHash Evergreen.V357.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V357.TextEditor.LocalState
    , calls : Evergreen.V357.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V357.Id.Id Evergreen.V357.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V357.Id.Id Evergreen.V357.Id.UserId
    , name : Evergreen.V357.ChannelName.ChannelName
    , description : Evergreen.V357.ChannelDescription.ChannelDescription
    , messages : Evergreen.V357.IdArray.IdArray Evergreen.V357.Id.ChannelMessageId (Evergreen.V357.Message.Message Evergreen.V357.Id.ChannelMessageId (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) (Evergreen.V357.Thread.LastTypedAt Evergreen.V357.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) Evergreen.V357.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V357.Drawing.Drawing (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) Evergreen.V357.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V357.Id.Id Evergreen.V357.Id.UserId
    , name : Evergreen.V357.GuildName.GuildName
    , icon : Maybe Evergreen.V357.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V357.MembersAndOwner.MembersAndOwner
            (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V357.SecretId.SecretId Evergreen.V357.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V357.Id.Id Evergreen.V357.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V357.ChannelName.ChannelName
    , description : Evergreen.V357.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V357.IdArray.IdArray Evergreen.V357.Id.ChannelMessageId (Evergreen.V357.Message.Message Evergreen.V357.Id.ChannelMessageId (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Thread.LastTypedAt Evergreen.V357.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V357.OneToOne.OneToOne (Evergreen.V357.Discord.Id Evergreen.V357.Discord.MessageId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) Evergreen.V357.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V357.Drawing.Drawing (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId))
    , permissionOverwrites : List Evergreen.V357.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V357.GuildName.GuildName
    , icon : Maybe Evergreen.V357.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V357.MembersAndOwner.MembersAndOwner
            (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V357.Discord.Id Evergreen.V357.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V357.Id.Id Evergreen.V357.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V357.Id.Id Evergreen.V357.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId
    , messages : List Evergreen.V357.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V357.Discord.Message
    , threads : List DiscordThreadReload
    }
