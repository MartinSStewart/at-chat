module Evergreen.V266.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V266.Call
import Evergreen.V266.ChannelDescription
import Evergreen.V266.ChannelName
import Evergreen.V266.Cloudflare
import Evergreen.V266.Discord
import Evergreen.V266.DiscordUserData
import Evergreen.V266.DmChannel
import Evergreen.V266.FileStatus
import Evergreen.V266.GuildName
import Evergreen.V266.Id
import Evergreen.V266.Log
import Evergreen.V266.MembersAndOwner
import Evergreen.V266.Message
import Evergreen.V266.NonemptyDict
import Evergreen.V266.OneToOne
import Evergreen.V266.Pagination
import Evergreen.V266.Postmark
import Evergreen.V266.SecretId
import Evergreen.V266.SessionIdHash
import Evergreen.V266.Slack
import Evergreen.V266.TextEditor
import Evergreen.V266.Thread
import Evergreen.V266.ToBackendLog
import Evergreen.V266.User
import Evergreen.V266.UserSession
import Evergreen.V266.VisibleMessages
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
        Evergreen.V266.NonemptyDict.NonemptyDict
            (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V266.Message.Message Evergreen.V266.Id.ChannelMessageId (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V266.Discord.PartialUser
        , icon : Maybe Evergreen.V266.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V266.Discord.User
        , linkedTo : Evergreen.V266.Id.Id Evergreen.V266.Id.UserId
        , icon : Maybe Evergreen.V266.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V266.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V266.Discord.User
        , linkedTo : Evergreen.V266.Id.Id Evergreen.V266.Id.UserId
        , icon : Maybe Evergreen.V266.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V266.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V266.Message.Message Evergreen.V266.Id.ChannelMessageId (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V266.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V266.MembersAndOwner.MembersAndOwner
            (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V266.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V266.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V266.Id.Id Evergreen.V266.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V266.GuildName.GuildName
    , owner : Evergreen.V266.Id.Id Evergreen.V266.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V266.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V266.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V266.Call.CallId
    | ConnectedToCall
        Evergreen.V266.Call.CallId
        { sessionId : Evergreen.V266.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V266.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V266.Id.Id Evergreen.V266.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V266.Id.Id Evergreen.V266.Id.UserId
    , name : Evergreen.V266.ChannelName.ChannelName
    , description : Evergreen.V266.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V266.Message.MessageState Evergreen.V266.Id.ChannelMessageId (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId))
    , visibleMessages : Evergreen.V266.VisibleMessages.VisibleMessages Evergreen.V266.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) (Evergreen.V266.Thread.LastTypedAt Evergreen.V266.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) Evergreen.V266.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V266.Id.Id Evergreen.V266.Id.UserId
    , name : Evergreen.V266.GuildName.GuildName
    , icon : Maybe Evergreen.V266.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V266.MembersAndOwner.MembersAndOwner
            (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V266.SecretId.SecretId Evergreen.V266.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V266.Id.Id Evergreen.V266.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V266.ChannelName.ChannelName
    , description : Evergreen.V266.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V266.Message.MessageState Evergreen.V266.Id.ChannelMessageId (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId))
    , visibleMessages : Evergreen.V266.VisibleMessages.VisibleMessages Evergreen.V266.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Evergreen.V266.Thread.LastTypedAt Evergreen.V266.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) Evergreen.V266.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V266.GuildName.GuildName
    , icon : Maybe Evergreen.V266.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V266.MembersAndOwner.MembersAndOwner
            (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V266.Id.Id Evergreen.V266.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V266.Id.Id Evergreen.V266.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V266.NonemptyDict.NonemptyDict (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) Evergreen.V266.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V266.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V266.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V266.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V266.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V266.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V266.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V266.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V266.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V266.SessionIdHash.SessionIdHash (Evergreen.V266.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V266.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V266.SessionIdHash.SessionIdHash Evergreen.V266.UserSession.UserSession
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) Evergreen.V266.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId) Evergreen.V266.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V266.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V266.SessionIdHash.SessionIdHash Evergreen.V266.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V266.TextEditor.LocalState
    , calls : Evergreen.V266.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V266.Id.Id Evergreen.V266.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V266.Id.Id Evergreen.V266.Id.UserId
    , name : Evergreen.V266.ChannelName.ChannelName
    , description : Evergreen.V266.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V266.Message.Message Evergreen.V266.Id.ChannelMessageId (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) (Evergreen.V266.Thread.LastTypedAt Evergreen.V266.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) Evergreen.V266.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V266.Id.Id Evergreen.V266.Id.UserId
    , name : Evergreen.V266.GuildName.GuildName
    , icon : Maybe Evergreen.V266.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V266.MembersAndOwner.MembersAndOwner
            (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V266.SecretId.SecretId Evergreen.V266.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V266.Id.Id Evergreen.V266.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V266.ChannelName.ChannelName
    , description : Evergreen.V266.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V266.Message.Message Evergreen.V266.Id.ChannelMessageId (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Evergreen.V266.Thread.LastTypedAt Evergreen.V266.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V266.OneToOne.OneToOne (Evergreen.V266.Discord.Id Evergreen.V266.Discord.MessageId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) Evergreen.V266.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V266.GuildName.GuildName
    , icon : Maybe Evergreen.V266.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V266.MembersAndOwner.MembersAndOwner
            (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V266.Id.Id Evergreen.V266.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V266.Id.Id Evergreen.V266.Id.CustomEmojiId)
    }
