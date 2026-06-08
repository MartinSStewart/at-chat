module Evergreen.V279.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V279.Call
import Evergreen.V279.ChannelDescription
import Evergreen.V279.ChannelName
import Evergreen.V279.Cloudflare
import Evergreen.V279.Discord
import Evergreen.V279.DiscordUserData
import Evergreen.V279.DmChannel
import Evergreen.V279.FileStatus
import Evergreen.V279.GuildName
import Evergreen.V279.Id
import Evergreen.V279.Log
import Evergreen.V279.MembersAndOwner
import Evergreen.V279.Message
import Evergreen.V279.NonemptyDict
import Evergreen.V279.OneToOne
import Evergreen.V279.Pagination
import Evergreen.V279.Postmark
import Evergreen.V279.SecretId
import Evergreen.V279.SessionIdHash
import Evergreen.V279.Slack
import Evergreen.V279.TextEditor
import Evergreen.V279.Thread
import Evergreen.V279.ToBackendLog
import Evergreen.V279.User
import Evergreen.V279.UserSession
import Evergreen.V279.VisibleMessages
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
        Evergreen.V279.NonemptyDict.NonemptyDict
            (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V279.Message.Message Evergreen.V279.Id.ChannelMessageId (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V279.Discord.PartialUser
        , icon : Maybe Evergreen.V279.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V279.Discord.User
        , linkedTo : Evergreen.V279.Id.Id Evergreen.V279.Id.UserId
        , icon : Maybe Evergreen.V279.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V279.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V279.Discord.User
        , linkedTo : Evergreen.V279.Id.Id Evergreen.V279.Id.UserId
        , icon : Maybe Evergreen.V279.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V279.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V279.Message.Message Evergreen.V279.Id.ChannelMessageId (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V279.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V279.MembersAndOwner.MembersAndOwner
            (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V279.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V279.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V279.Id.Id Evergreen.V279.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V279.GuildName.GuildName
    , owner : Evergreen.V279.Id.Id Evergreen.V279.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V279.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V279.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V279.Call.CallId
    | ConnectedToCall
        Evergreen.V279.Call.CallId
        { sessionId : Evergreen.V279.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V279.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V279.Id.Id Evergreen.V279.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V279.Id.Id Evergreen.V279.Id.UserId
    , name : Evergreen.V279.ChannelName.ChannelName
    , description : Evergreen.V279.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V279.Message.MessageState Evergreen.V279.Id.ChannelMessageId (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId))
    , visibleMessages : Evergreen.V279.VisibleMessages.VisibleMessages Evergreen.V279.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) (Evergreen.V279.Thread.LastTypedAt Evergreen.V279.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) Evergreen.V279.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V279.Id.Id Evergreen.V279.Id.UserId
    , name : Evergreen.V279.GuildName.GuildName
    , icon : Maybe Evergreen.V279.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V279.MembersAndOwner.MembersAndOwner
            (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V279.SecretId.SecretId Evergreen.V279.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V279.Id.Id Evergreen.V279.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V279.ChannelName.ChannelName
    , description : Evergreen.V279.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V279.Message.MessageState Evergreen.V279.Id.ChannelMessageId (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId))
    , visibleMessages : Evergreen.V279.VisibleMessages.VisibleMessages Evergreen.V279.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Evergreen.V279.Thread.LastTypedAt Evergreen.V279.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) Evergreen.V279.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V279.GuildName.GuildName
    , icon : Maybe Evergreen.V279.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V279.MembersAndOwner.MembersAndOwner
            (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V279.Id.Id Evergreen.V279.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V279.Id.Id Evergreen.V279.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V279.NonemptyDict.NonemptyDict (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) Evergreen.V279.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V279.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V279.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V279.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V279.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V279.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V279.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V279.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V279.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V279.SessionIdHash.SessionIdHash (Evergreen.V279.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V279.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V279.SessionIdHash.SessionIdHash Evergreen.V279.UserSession.UserSession
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) Evergreen.V279.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId) Evergreen.V279.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V279.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V279.SessionIdHash.SessionIdHash Evergreen.V279.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V279.TextEditor.LocalState
    , calls : Evergreen.V279.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V279.Id.Id Evergreen.V279.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V279.Id.Id Evergreen.V279.Id.UserId
    , name : Evergreen.V279.ChannelName.ChannelName
    , description : Evergreen.V279.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V279.Message.Message Evergreen.V279.Id.ChannelMessageId (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) (Evergreen.V279.Thread.LastTypedAt Evergreen.V279.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) Evergreen.V279.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V279.Id.Id Evergreen.V279.Id.UserId
    , name : Evergreen.V279.GuildName.GuildName
    , icon : Maybe Evergreen.V279.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V279.MembersAndOwner.MembersAndOwner
            (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V279.SecretId.SecretId Evergreen.V279.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V279.Id.Id Evergreen.V279.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V279.ChannelName.ChannelName
    , description : Evergreen.V279.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V279.Message.Message Evergreen.V279.Id.ChannelMessageId (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Evergreen.V279.Thread.LastTypedAt Evergreen.V279.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V279.OneToOne.OneToOne (Evergreen.V279.Discord.Id Evergreen.V279.Discord.MessageId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) Evergreen.V279.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V279.GuildName.GuildName
    , icon : Maybe Evergreen.V279.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V279.MembersAndOwner.MembersAndOwner
            (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V279.Id.Id Evergreen.V279.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V279.Id.Id Evergreen.V279.Id.CustomEmojiId)
    }
