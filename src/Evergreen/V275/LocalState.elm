module Evergreen.V275.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V275.Call
import Evergreen.V275.ChannelDescription
import Evergreen.V275.ChannelName
import Evergreen.V275.Cloudflare
import Evergreen.V275.Discord
import Evergreen.V275.DiscordUserData
import Evergreen.V275.DmChannel
import Evergreen.V275.FileStatus
import Evergreen.V275.GuildName
import Evergreen.V275.Id
import Evergreen.V275.Log
import Evergreen.V275.MembersAndOwner
import Evergreen.V275.Message
import Evergreen.V275.NonemptyDict
import Evergreen.V275.OneToOne
import Evergreen.V275.Pagination
import Evergreen.V275.Postmark
import Evergreen.V275.SecretId
import Evergreen.V275.SessionIdHash
import Evergreen.V275.Slack
import Evergreen.V275.TextEditor
import Evergreen.V275.Thread
import Evergreen.V275.ToBackendLog
import Evergreen.V275.User
import Evergreen.V275.UserSession
import Evergreen.V275.VisibleMessages
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
        Evergreen.V275.NonemptyDict.NonemptyDict
            (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V275.Message.Message Evergreen.V275.Id.ChannelMessageId (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V275.Discord.PartialUser
        , icon : Maybe Evergreen.V275.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V275.Discord.User
        , linkedTo : Evergreen.V275.Id.Id Evergreen.V275.Id.UserId
        , icon : Maybe Evergreen.V275.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V275.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V275.Discord.User
        , linkedTo : Evergreen.V275.Id.Id Evergreen.V275.Id.UserId
        , icon : Maybe Evergreen.V275.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V275.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V275.Message.Message Evergreen.V275.Id.ChannelMessageId (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V275.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V275.MembersAndOwner.MembersAndOwner
            (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V275.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V275.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V275.Id.Id Evergreen.V275.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V275.GuildName.GuildName
    , owner : Evergreen.V275.Id.Id Evergreen.V275.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V275.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V275.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V275.Call.CallId
    | ConnectedToCall
        Evergreen.V275.Call.CallId
        { sessionId : Evergreen.V275.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V275.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V275.Id.Id Evergreen.V275.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V275.Id.Id Evergreen.V275.Id.UserId
    , name : Evergreen.V275.ChannelName.ChannelName
    , description : Evergreen.V275.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V275.Message.MessageState Evergreen.V275.Id.ChannelMessageId (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId))
    , visibleMessages : Evergreen.V275.VisibleMessages.VisibleMessages Evergreen.V275.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) (Evergreen.V275.Thread.LastTypedAt Evergreen.V275.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) Evergreen.V275.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V275.Id.Id Evergreen.V275.Id.UserId
    , name : Evergreen.V275.GuildName.GuildName
    , icon : Maybe Evergreen.V275.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V275.MembersAndOwner.MembersAndOwner
            (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V275.SecretId.SecretId Evergreen.V275.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V275.Id.Id Evergreen.V275.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V275.ChannelName.ChannelName
    , description : Evergreen.V275.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V275.Message.MessageState Evergreen.V275.Id.ChannelMessageId (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId))
    , visibleMessages : Evergreen.V275.VisibleMessages.VisibleMessages Evergreen.V275.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Evergreen.V275.Thread.LastTypedAt Evergreen.V275.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) Evergreen.V275.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V275.GuildName.GuildName
    , icon : Maybe Evergreen.V275.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V275.MembersAndOwner.MembersAndOwner
            (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V275.Id.Id Evergreen.V275.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V275.Id.Id Evergreen.V275.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V275.NonemptyDict.NonemptyDict (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) Evergreen.V275.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V275.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V275.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V275.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V275.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V275.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V275.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V275.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V275.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V275.SessionIdHash.SessionIdHash (Evergreen.V275.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V275.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V275.SessionIdHash.SessionIdHash Evergreen.V275.UserSession.UserSession
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) Evergreen.V275.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId) Evergreen.V275.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V275.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V275.SessionIdHash.SessionIdHash Evergreen.V275.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V275.TextEditor.LocalState
    , calls : Evergreen.V275.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V275.Id.Id Evergreen.V275.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V275.Id.Id Evergreen.V275.Id.UserId
    , name : Evergreen.V275.ChannelName.ChannelName
    , description : Evergreen.V275.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V275.Message.Message Evergreen.V275.Id.ChannelMessageId (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) (Evergreen.V275.Thread.LastTypedAt Evergreen.V275.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) Evergreen.V275.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V275.Id.Id Evergreen.V275.Id.UserId
    , name : Evergreen.V275.GuildName.GuildName
    , icon : Maybe Evergreen.V275.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V275.MembersAndOwner.MembersAndOwner
            (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V275.SecretId.SecretId Evergreen.V275.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V275.Id.Id Evergreen.V275.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V275.ChannelName.ChannelName
    , description : Evergreen.V275.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V275.Message.Message Evergreen.V275.Id.ChannelMessageId (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Evergreen.V275.Thread.LastTypedAt Evergreen.V275.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V275.OneToOne.OneToOne (Evergreen.V275.Discord.Id Evergreen.V275.Discord.MessageId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) Evergreen.V275.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V275.GuildName.GuildName
    , icon : Maybe Evergreen.V275.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V275.MembersAndOwner.MembersAndOwner
            (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V275.Id.Id Evergreen.V275.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V275.Id.Id Evergreen.V275.Id.CustomEmojiId)
    }
