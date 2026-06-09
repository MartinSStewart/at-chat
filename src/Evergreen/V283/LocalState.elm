module Evergreen.V283.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V283.Call
import Evergreen.V283.ChannelDescription
import Evergreen.V283.ChannelName
import Evergreen.V283.Cloudflare
import Evergreen.V283.Discord
import Evergreen.V283.DiscordUserData
import Evergreen.V283.DmChannel
import Evergreen.V283.FileStatus
import Evergreen.V283.GuildName
import Evergreen.V283.Id
import Evergreen.V283.Log
import Evergreen.V283.MembersAndOwner
import Evergreen.V283.Message
import Evergreen.V283.NonemptyDict
import Evergreen.V283.OneToOne
import Evergreen.V283.Pagination
import Evergreen.V283.Postmark
import Evergreen.V283.SecretId
import Evergreen.V283.SessionIdHash
import Evergreen.V283.Slack
import Evergreen.V283.TextEditor
import Evergreen.V283.Thread
import Evergreen.V283.ToBackendLog
import Evergreen.V283.User
import Evergreen.V283.UserSession
import Evergreen.V283.VisibleMessages
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
        Evergreen.V283.NonemptyDict.NonemptyDict
            (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V283.Message.Message Evergreen.V283.Id.ChannelMessageId (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V283.Discord.PartialUser
        , icon : Maybe Evergreen.V283.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V283.Discord.User
        , linkedTo : Evergreen.V283.Id.Id Evergreen.V283.Id.UserId
        , icon : Maybe Evergreen.V283.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V283.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V283.Discord.User
        , linkedTo : Evergreen.V283.Id.Id Evergreen.V283.Id.UserId
        , icon : Maybe Evergreen.V283.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V283.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V283.Message.Message Evergreen.V283.Id.ChannelMessageId (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V283.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V283.MembersAndOwner.MembersAndOwner
            (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V283.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V283.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V283.Id.Id Evergreen.V283.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V283.GuildName.GuildName
    , owner : Evergreen.V283.Id.Id Evergreen.V283.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V283.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V283.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V283.Call.CallId
    | ConnectedToCall
        Evergreen.V283.Call.CallId
        { sessionId : Evergreen.V283.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V283.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V283.Call.RemoteCallData
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V283.Id.Id Evergreen.V283.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V283.Id.Id Evergreen.V283.Id.UserId
    , name : Evergreen.V283.ChannelName.ChannelName
    , description : Evergreen.V283.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V283.Message.MessageState Evergreen.V283.Id.ChannelMessageId (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId))
    , visibleMessages : Evergreen.V283.VisibleMessages.VisibleMessages Evergreen.V283.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) (Evergreen.V283.Thread.LastTypedAt Evergreen.V283.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) Evergreen.V283.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V283.Id.Id Evergreen.V283.Id.UserId
    , name : Evergreen.V283.GuildName.GuildName
    , icon : Maybe Evergreen.V283.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V283.MembersAndOwner.MembersAndOwner
            (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V283.SecretId.SecretId Evergreen.V283.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V283.Id.Id Evergreen.V283.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V283.ChannelName.ChannelName
    , description : Evergreen.V283.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V283.Message.MessageState Evergreen.V283.Id.ChannelMessageId (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId))
    , visibleMessages : Evergreen.V283.VisibleMessages.VisibleMessages Evergreen.V283.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Evergreen.V283.Thread.LastTypedAt Evergreen.V283.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) Evergreen.V283.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V283.GuildName.GuildName
    , icon : Maybe Evergreen.V283.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V283.MembersAndOwner.MembersAndOwner
            (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V283.Id.Id Evergreen.V283.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V283.Id.Id Evergreen.V283.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V283.NonemptyDict.NonemptyDict (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) Evergreen.V283.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V283.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V283.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V283.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V283.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V283.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V283.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V283.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V283.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V283.SessionIdHash.SessionIdHash (Evergreen.V283.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V283.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V283.SessionIdHash.SessionIdHash Evergreen.V283.UserSession.UserSession
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) Evergreen.V283.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId) Evergreen.V283.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V283.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V283.SessionIdHash.SessionIdHash Evergreen.V283.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V283.TextEditor.LocalState
    , calls : Evergreen.V283.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V283.Id.Id Evergreen.V283.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V283.Id.Id Evergreen.V283.Id.UserId
    , name : Evergreen.V283.ChannelName.ChannelName
    , description : Evergreen.V283.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V283.Message.Message Evergreen.V283.Id.ChannelMessageId (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) (Evergreen.V283.Thread.LastTypedAt Evergreen.V283.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) Evergreen.V283.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V283.Id.Id Evergreen.V283.Id.UserId
    , name : Evergreen.V283.GuildName.GuildName
    , icon : Maybe Evergreen.V283.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V283.MembersAndOwner.MembersAndOwner
            (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V283.SecretId.SecretId Evergreen.V283.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V283.Id.Id Evergreen.V283.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V283.ChannelName.ChannelName
    , description : Evergreen.V283.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V283.Message.Message Evergreen.V283.Id.ChannelMessageId (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Evergreen.V283.Thread.LastTypedAt Evergreen.V283.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V283.OneToOne.OneToOne (Evergreen.V283.Discord.Id Evergreen.V283.Discord.MessageId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) Evergreen.V283.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V283.GuildName.GuildName
    , icon : Maybe Evergreen.V283.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V283.MembersAndOwner.MembersAndOwner
            (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V283.Id.Id Evergreen.V283.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V283.Id.Id Evergreen.V283.Id.CustomEmojiId)
    }
