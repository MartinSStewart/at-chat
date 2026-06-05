module Evergreen.V277.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V277.Call
import Evergreen.V277.ChannelDescription
import Evergreen.V277.ChannelName
import Evergreen.V277.Cloudflare
import Evergreen.V277.Discord
import Evergreen.V277.DiscordUserData
import Evergreen.V277.DmChannel
import Evergreen.V277.FileStatus
import Evergreen.V277.GuildName
import Evergreen.V277.Id
import Evergreen.V277.Log
import Evergreen.V277.MembersAndOwner
import Evergreen.V277.Message
import Evergreen.V277.NonemptyDict
import Evergreen.V277.OneToOne
import Evergreen.V277.Pagination
import Evergreen.V277.Postmark
import Evergreen.V277.SecretId
import Evergreen.V277.SessionIdHash
import Evergreen.V277.Slack
import Evergreen.V277.TextEditor
import Evergreen.V277.Thread
import Evergreen.V277.ToBackendLog
import Evergreen.V277.User
import Evergreen.V277.UserSession
import Evergreen.V277.VisibleMessages
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
        Evergreen.V277.NonemptyDict.NonemptyDict
            (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V277.Message.Message Evergreen.V277.Id.ChannelMessageId (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V277.Discord.PartialUser
        , icon : Maybe Evergreen.V277.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V277.Discord.User
        , linkedTo : Evergreen.V277.Id.Id Evergreen.V277.Id.UserId
        , icon : Maybe Evergreen.V277.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V277.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V277.Discord.User
        , linkedTo : Evergreen.V277.Id.Id Evergreen.V277.Id.UserId
        , icon : Maybe Evergreen.V277.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V277.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V277.Message.Message Evergreen.V277.Id.ChannelMessageId (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V277.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V277.MembersAndOwner.MembersAndOwner
            (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V277.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V277.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V277.Id.Id Evergreen.V277.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V277.GuildName.GuildName
    , owner : Evergreen.V277.Id.Id Evergreen.V277.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V277.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V277.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V277.Call.CallId
    | ConnectedToCall
        Evergreen.V277.Call.CallId
        { sessionId : Evergreen.V277.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V277.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V277.Id.Id Evergreen.V277.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V277.Id.Id Evergreen.V277.Id.UserId
    , name : Evergreen.V277.ChannelName.ChannelName
    , description : Evergreen.V277.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V277.Message.MessageState Evergreen.V277.Id.ChannelMessageId (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId))
    , visibleMessages : Evergreen.V277.VisibleMessages.VisibleMessages Evergreen.V277.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) (Evergreen.V277.Thread.LastTypedAt Evergreen.V277.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) Evergreen.V277.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V277.Id.Id Evergreen.V277.Id.UserId
    , name : Evergreen.V277.GuildName.GuildName
    , icon : Maybe Evergreen.V277.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V277.MembersAndOwner.MembersAndOwner
            (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V277.SecretId.SecretId Evergreen.V277.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V277.Id.Id Evergreen.V277.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V277.ChannelName.ChannelName
    , description : Evergreen.V277.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V277.Message.MessageState Evergreen.V277.Id.ChannelMessageId (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId))
    , visibleMessages : Evergreen.V277.VisibleMessages.VisibleMessages Evergreen.V277.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Evergreen.V277.Thread.LastTypedAt Evergreen.V277.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) Evergreen.V277.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V277.GuildName.GuildName
    , icon : Maybe Evergreen.V277.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V277.MembersAndOwner.MembersAndOwner
            (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V277.Id.Id Evergreen.V277.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V277.Id.Id Evergreen.V277.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V277.NonemptyDict.NonemptyDict (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) Evergreen.V277.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V277.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V277.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V277.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V277.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V277.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V277.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V277.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V277.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V277.SessionIdHash.SessionIdHash (Evergreen.V277.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V277.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V277.SessionIdHash.SessionIdHash Evergreen.V277.UserSession.UserSession
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) Evergreen.V277.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId) Evergreen.V277.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V277.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V277.SessionIdHash.SessionIdHash Evergreen.V277.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V277.TextEditor.LocalState
    , calls : Evergreen.V277.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V277.Id.Id Evergreen.V277.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V277.Id.Id Evergreen.V277.Id.UserId
    , name : Evergreen.V277.ChannelName.ChannelName
    , description : Evergreen.V277.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V277.Message.Message Evergreen.V277.Id.ChannelMessageId (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) (Evergreen.V277.Thread.LastTypedAt Evergreen.V277.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) Evergreen.V277.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V277.Id.Id Evergreen.V277.Id.UserId
    , name : Evergreen.V277.GuildName.GuildName
    , icon : Maybe Evergreen.V277.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V277.MembersAndOwner.MembersAndOwner
            (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V277.SecretId.SecretId Evergreen.V277.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V277.Id.Id Evergreen.V277.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V277.ChannelName.ChannelName
    , description : Evergreen.V277.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V277.Message.Message Evergreen.V277.Id.ChannelMessageId (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Evergreen.V277.Thread.LastTypedAt Evergreen.V277.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V277.OneToOne.OneToOne (Evergreen.V277.Discord.Id Evergreen.V277.Discord.MessageId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) Evergreen.V277.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V277.GuildName.GuildName
    , icon : Maybe Evergreen.V277.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V277.MembersAndOwner.MembersAndOwner
            (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V277.Id.Id Evergreen.V277.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V277.Id.Id Evergreen.V277.Id.CustomEmojiId)
    }
