module Evergreen.V333.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V333.Call
import Evergreen.V333.ChannelDescription
import Evergreen.V333.ChannelName
import Evergreen.V333.Cloudflare
import Evergreen.V333.Discord
import Evergreen.V333.DiscordUserData
import Evergreen.V333.DmChannel
import Evergreen.V333.DmChannelId
import Evergreen.V333.Drawing
import Evergreen.V333.FileStatus
import Evergreen.V333.Game
import Evergreen.V333.GuildName
import Evergreen.V333.Id
import Evergreen.V333.IdArray
import Evergreen.V333.Log
import Evergreen.V333.MembersAndOwner
import Evergreen.V333.Message
import Evergreen.V333.NonemptyDict
import Evergreen.V333.OneToOne
import Evergreen.V333.Pagination
import Evergreen.V333.Postmark
import Evergreen.V333.SecretId
import Evergreen.V333.SessionIdHash
import Evergreen.V333.Slack
import Evergreen.V333.TextEditor
import Evergreen.V333.Thread
import Evergreen.V333.ToBackendLog
import Evergreen.V333.User
import Evergreen.V333.UserSession
import Evergreen.V333.VisibleMessages
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
        Evergreen.V333.NonemptyDict.NonemptyDict
            (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V333.Message.Message Evergreen.V333.Id.ChannelMessageId (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V333.Discord.PartialUser
        , icon : Maybe Evergreen.V333.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V333.Discord.User
        , linkedTo : Evergreen.V333.Id.Id Evergreen.V333.Id.UserId
        , icon : Maybe Evergreen.V333.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V333.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V333.Discord.User
        , linkedTo : Evergreen.V333.Id.Id Evergreen.V333.Id.UserId
        , icon : Maybe Evergreen.V333.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V333.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V333.Message.Message Evergreen.V333.Id.ChannelMessageId (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId))
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V333.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V333.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V333.MembersAndOwner.MembersAndOwner
            (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V333.Discord.Id Evergreen.V333.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V333.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V333.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V333.Id.Id Evergreen.V333.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V333.GuildName.GuildName
    , owner : Evergreen.V333.Id.Id Evergreen.V333.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V333.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V333.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V333.Call.CallId
    | ConnectedToCall
        Evergreen.V333.Call.CallId
        { sessionId : Evergreen.V333.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V333.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V333.Call.RemoteCallData
    , currentlyViewing : Evergreen.V333.UserSession.Viewing
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V333.Id.Id Evergreen.V333.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V333.Id.Id Evergreen.V333.Id.UserId
    , name : Evergreen.V333.ChannelName.ChannelName
    , description : Evergreen.V333.ChannelDescription.ChannelDescription
    , messages : Evergreen.V333.IdArray.IdArray Evergreen.V333.Id.ChannelMessageId (Evergreen.V333.Message.MessageState Evergreen.V333.Id.ChannelMessageId (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId))
    , visibleMessages : Evergreen.V333.VisibleMessages.VisibleMessages Evergreen.V333.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) (Evergreen.V333.Thread.LastTypedAt Evergreen.V333.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) Evergreen.V333.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V333.Drawing.Drawing (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) Evergreen.V333.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V333.Id.Id Evergreen.V333.Id.UserId
    , name : Evergreen.V333.GuildName.GuildName
    , icon : Maybe Evergreen.V333.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V333.MembersAndOwner.MembersAndOwner
            (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V333.SecretId.SecretId Evergreen.V333.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V333.Id.Id Evergreen.V333.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V333.ChannelName.ChannelName
    , description : Evergreen.V333.ChannelDescription.ChannelDescription
    , messages : Evergreen.V333.IdArray.IdArray Evergreen.V333.Id.ChannelMessageId (Evergreen.V333.Message.MessageState Evergreen.V333.Id.ChannelMessageId (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId))
    , visibleMessages : Evergreen.V333.VisibleMessages.VisibleMessages Evergreen.V333.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Thread.LastTypedAt Evergreen.V333.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) Evergreen.V333.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V333.Drawing.Drawing (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId))
    , permissionOverwrites : List Evergreen.V333.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V333.GuildName.GuildName
    , icon : Maybe Evergreen.V333.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V333.MembersAndOwner.MembersAndOwner
            (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V333.Discord.Id Evergreen.V333.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V333.Id.Id Evergreen.V333.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V333.Id.Id Evergreen.V333.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V333.NonemptyDict.NonemptyDict (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) Evergreen.V333.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V333.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V333.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V333.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V333.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V333.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V333.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V333.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V333.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V333.SessionIdHash.SessionIdHash (Evergreen.V333.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V333.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V333.SessionIdHash.SessionIdHash Evergreen.V333.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) Evergreen.V333.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId) Evergreen.V333.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V333.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V333.SessionIdHash.SessionIdHash Evergreen.V333.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V333.TextEditor.LocalState
    , calls : Evergreen.V333.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V333.Id.Id Evergreen.V333.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V333.Id.Id Evergreen.V333.Id.UserId
    , name : Evergreen.V333.ChannelName.ChannelName
    , description : Evergreen.V333.ChannelDescription.ChannelDescription
    , messages : Evergreen.V333.IdArray.IdArray Evergreen.V333.Id.ChannelMessageId (Evergreen.V333.Message.Message Evergreen.V333.Id.ChannelMessageId (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) (Evergreen.V333.Thread.LastTypedAt Evergreen.V333.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) Evergreen.V333.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V333.Drawing.Drawing (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) Evergreen.V333.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V333.Id.Id Evergreen.V333.Id.UserId
    , name : Evergreen.V333.GuildName.GuildName
    , icon : Maybe Evergreen.V333.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V333.MembersAndOwner.MembersAndOwner
            (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V333.SecretId.SecretId Evergreen.V333.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V333.Id.Id Evergreen.V333.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V333.ChannelName.ChannelName
    , description : Evergreen.V333.ChannelDescription.ChannelDescription
    , messages : Evergreen.V333.IdArray.IdArray Evergreen.V333.Id.ChannelMessageId (Evergreen.V333.Message.Message Evergreen.V333.Id.ChannelMessageId (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Thread.LastTypedAt Evergreen.V333.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V333.OneToOne.OneToOne (Evergreen.V333.Discord.Id Evergreen.V333.Discord.MessageId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) Evergreen.V333.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V333.Drawing.Drawing (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId))
    , permissionOverwrites : List Evergreen.V333.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V333.GuildName.GuildName
    , icon : Maybe Evergreen.V333.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V333.MembersAndOwner.MembersAndOwner
            (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V333.Discord.Id Evergreen.V333.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V333.Id.Id Evergreen.V333.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V333.Id.Id Evergreen.V333.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.RoleId) DiscordRole
    }
