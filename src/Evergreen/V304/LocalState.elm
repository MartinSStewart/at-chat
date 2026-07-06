module Evergreen.V304.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V304.Call
import Evergreen.V304.ChannelDescription
import Evergreen.V304.ChannelName
import Evergreen.V304.Cloudflare
import Evergreen.V304.Discord
import Evergreen.V304.DiscordUserData
import Evergreen.V304.DmChannel
import Evergreen.V304.DmChannelId
import Evergreen.V304.Drawing
import Evergreen.V304.FileStatus
import Evergreen.V304.Game
import Evergreen.V304.GuildName
import Evergreen.V304.Id
import Evergreen.V304.IdArray
import Evergreen.V304.Log
import Evergreen.V304.MembersAndOwner
import Evergreen.V304.Message
import Evergreen.V304.NonemptyDict
import Evergreen.V304.OneToOne
import Evergreen.V304.Pagination
import Evergreen.V304.Postmark
import Evergreen.V304.SecretId
import Evergreen.V304.SessionIdHash
import Evergreen.V304.Slack
import Evergreen.V304.TextEditor
import Evergreen.V304.Thread
import Evergreen.V304.ToBackendLog
import Evergreen.V304.User
import Evergreen.V304.UserSession
import Evergreen.V304.VisibleMessages
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
        Evergreen.V304.NonemptyDict.NonemptyDict
            (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V304.Message.Message Evergreen.V304.Id.ChannelMessageId (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V304.Discord.PartialUser
        , icon : Maybe Evergreen.V304.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V304.Discord.User
        , linkedTo : Evergreen.V304.Id.Id Evergreen.V304.Id.UserId
        , icon : Maybe Evergreen.V304.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V304.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V304.Discord.User
        , linkedTo : Evergreen.V304.Id.Id Evergreen.V304.Id.UserId
        , icon : Maybe Evergreen.V304.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V304.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V304.Message.Message Evergreen.V304.Id.ChannelMessageId (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V304.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V304.MembersAndOwner.MembersAndOwner
            (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V304.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V304.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V304.Id.Id Evergreen.V304.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V304.GuildName.GuildName
    , owner : Evergreen.V304.Id.Id Evergreen.V304.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V304.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V304.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V304.Call.CallId
    | ConnectedToCall
        Evergreen.V304.Call.CallId
        { sessionId : Evergreen.V304.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V304.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V304.Call.RemoteCallData
    , currentlyViewing : Maybe ( Evergreen.V304.Id.AnyGuildOrDmId, Evergreen.V304.Id.ThreadRoute )
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V304.Id.Id Evergreen.V304.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V304.Id.Id Evergreen.V304.Id.UserId
    , name : Evergreen.V304.ChannelName.ChannelName
    , description : Evergreen.V304.ChannelDescription.ChannelDescription
    , messages : Evergreen.V304.IdArray.IdArray Evergreen.V304.Id.ChannelMessageId (Evergreen.V304.Message.MessageState Evergreen.V304.Id.ChannelMessageId (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId))
    , visibleMessages : Evergreen.V304.VisibleMessages.VisibleMessages Evergreen.V304.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) (Evergreen.V304.Thread.LastTypedAt Evergreen.V304.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) Evergreen.V304.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V304.Drawing.Drawing (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) Evergreen.V304.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V304.Id.Id Evergreen.V304.Id.UserId
    , name : Evergreen.V304.GuildName.GuildName
    , icon : Maybe Evergreen.V304.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V304.MembersAndOwner.MembersAndOwner
            (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V304.SecretId.SecretId Evergreen.V304.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V304.Id.Id Evergreen.V304.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V304.ChannelName.ChannelName
    , description : Evergreen.V304.ChannelDescription.ChannelDescription
    , messages : Evergreen.V304.IdArray.IdArray Evergreen.V304.Id.ChannelMessageId (Evergreen.V304.Message.MessageState Evergreen.V304.Id.ChannelMessageId (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId))
    , visibleMessages : Evergreen.V304.VisibleMessages.VisibleMessages Evergreen.V304.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Evergreen.V304.Thread.LastTypedAt Evergreen.V304.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) Evergreen.V304.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V304.Drawing.Drawing (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V304.GuildName.GuildName
    , icon : Maybe Evergreen.V304.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V304.MembersAndOwner.MembersAndOwner
            (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V304.Id.Id Evergreen.V304.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V304.Id.Id Evergreen.V304.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V304.NonemptyDict.NonemptyDict (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) Evergreen.V304.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V304.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V304.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V304.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V304.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V304.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V304.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V304.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V304.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V304.SessionIdHash.SessionIdHash (Evergreen.V304.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V304.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V304.SessionIdHash.SessionIdHash Evergreen.V304.UserSession.UserSession
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) Evergreen.V304.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId) Evergreen.V304.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V304.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V304.SessionIdHash.SessionIdHash Evergreen.V304.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V304.TextEditor.LocalState
    , calls : Evergreen.V304.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V304.Id.Id Evergreen.V304.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V304.Id.Id Evergreen.V304.Id.UserId
    , name : Evergreen.V304.ChannelName.ChannelName
    , description : Evergreen.V304.ChannelDescription.ChannelDescription
    , messages : Evergreen.V304.IdArray.IdArray Evergreen.V304.Id.ChannelMessageId (Evergreen.V304.Message.Message Evergreen.V304.Id.ChannelMessageId (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) (Evergreen.V304.Thread.LastTypedAt Evergreen.V304.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) Evergreen.V304.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V304.Drawing.Drawing (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) Evergreen.V304.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V304.Id.Id Evergreen.V304.Id.UserId
    , name : Evergreen.V304.GuildName.GuildName
    , icon : Maybe Evergreen.V304.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V304.MembersAndOwner.MembersAndOwner
            (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V304.SecretId.SecretId Evergreen.V304.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V304.Id.Id Evergreen.V304.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V304.ChannelName.ChannelName
    , description : Evergreen.V304.ChannelDescription.ChannelDescription
    , messages : Evergreen.V304.IdArray.IdArray Evergreen.V304.Id.ChannelMessageId (Evergreen.V304.Message.Message Evergreen.V304.Id.ChannelMessageId (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Evergreen.V304.Thread.LastTypedAt Evergreen.V304.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V304.OneToOne.OneToOne (Evergreen.V304.Discord.Id Evergreen.V304.Discord.MessageId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) Evergreen.V304.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V304.Drawing.Drawing (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V304.GuildName.GuildName
    , icon : Maybe Evergreen.V304.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V304.MembersAndOwner.MembersAndOwner
            (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V304.Id.Id Evergreen.V304.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V304.Id.Id Evergreen.V304.Id.CustomEmojiId)
    }
