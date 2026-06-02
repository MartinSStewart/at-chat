module Evergreen.V267.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V267.Call
import Evergreen.V267.ChannelDescription
import Evergreen.V267.ChannelName
import Evergreen.V267.Cloudflare
import Evergreen.V267.Discord
import Evergreen.V267.DiscordUserData
import Evergreen.V267.DmChannel
import Evergreen.V267.FileStatus
import Evergreen.V267.GuildName
import Evergreen.V267.Id
import Evergreen.V267.Log
import Evergreen.V267.MembersAndOwner
import Evergreen.V267.Message
import Evergreen.V267.NonemptyDict
import Evergreen.V267.OneToOne
import Evergreen.V267.Pagination
import Evergreen.V267.Postmark
import Evergreen.V267.SecretId
import Evergreen.V267.SessionIdHash
import Evergreen.V267.Slack
import Evergreen.V267.TextEditor
import Evergreen.V267.Thread
import Evergreen.V267.ToBackendLog
import Evergreen.V267.User
import Evergreen.V267.UserSession
import Evergreen.V267.VisibleMessages
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
        Evergreen.V267.NonemptyDict.NonemptyDict
            (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V267.Message.Message Evergreen.V267.Id.ChannelMessageId (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V267.Discord.PartialUser
        , icon : Maybe Evergreen.V267.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V267.Discord.User
        , linkedTo : Evergreen.V267.Id.Id Evergreen.V267.Id.UserId
        , icon : Maybe Evergreen.V267.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V267.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V267.Discord.User
        , linkedTo : Evergreen.V267.Id.Id Evergreen.V267.Id.UserId
        , icon : Maybe Evergreen.V267.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V267.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V267.Message.Message Evergreen.V267.Id.ChannelMessageId (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V267.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V267.MembersAndOwner.MembersAndOwner
            (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V267.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V267.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V267.Id.Id Evergreen.V267.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V267.GuildName.GuildName
    , owner : Evergreen.V267.Id.Id Evergreen.V267.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V267.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V267.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V267.Call.CallId
    | ConnectedToCall
        Evergreen.V267.Call.CallId
        { sessionId : Evergreen.V267.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V267.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V267.Id.Id Evergreen.V267.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V267.Id.Id Evergreen.V267.Id.UserId
    , name : Evergreen.V267.ChannelName.ChannelName
    , description : Evergreen.V267.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V267.Message.MessageState Evergreen.V267.Id.ChannelMessageId (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId))
    , visibleMessages : Evergreen.V267.VisibleMessages.VisibleMessages Evergreen.V267.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) (Evergreen.V267.Thread.LastTypedAt Evergreen.V267.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) Evergreen.V267.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V267.Id.Id Evergreen.V267.Id.UserId
    , name : Evergreen.V267.GuildName.GuildName
    , icon : Maybe Evergreen.V267.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V267.MembersAndOwner.MembersAndOwner
            (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V267.SecretId.SecretId Evergreen.V267.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V267.Id.Id Evergreen.V267.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V267.ChannelName.ChannelName
    , description : Evergreen.V267.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V267.Message.MessageState Evergreen.V267.Id.ChannelMessageId (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId))
    , visibleMessages : Evergreen.V267.VisibleMessages.VisibleMessages Evergreen.V267.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Evergreen.V267.Thread.LastTypedAt Evergreen.V267.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) Evergreen.V267.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V267.GuildName.GuildName
    , icon : Maybe Evergreen.V267.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V267.MembersAndOwner.MembersAndOwner
            (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V267.Id.Id Evergreen.V267.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V267.Id.Id Evergreen.V267.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V267.NonemptyDict.NonemptyDict (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) Evergreen.V267.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V267.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V267.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V267.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V267.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V267.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V267.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V267.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V267.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V267.SessionIdHash.SessionIdHash (Evergreen.V267.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V267.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V267.SessionIdHash.SessionIdHash Evergreen.V267.UserSession.UserSession
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) Evergreen.V267.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId) Evergreen.V267.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V267.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V267.SessionIdHash.SessionIdHash Evergreen.V267.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V267.TextEditor.LocalState
    , calls : Evergreen.V267.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V267.Id.Id Evergreen.V267.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V267.Id.Id Evergreen.V267.Id.UserId
    , name : Evergreen.V267.ChannelName.ChannelName
    , description : Evergreen.V267.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V267.Message.Message Evergreen.V267.Id.ChannelMessageId (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) (Evergreen.V267.Thread.LastTypedAt Evergreen.V267.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) Evergreen.V267.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V267.Id.Id Evergreen.V267.Id.UserId
    , name : Evergreen.V267.GuildName.GuildName
    , icon : Maybe Evergreen.V267.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V267.MembersAndOwner.MembersAndOwner
            (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V267.SecretId.SecretId Evergreen.V267.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V267.Id.Id Evergreen.V267.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V267.ChannelName.ChannelName
    , description : Evergreen.V267.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V267.Message.Message Evergreen.V267.Id.ChannelMessageId (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Evergreen.V267.Thread.LastTypedAt Evergreen.V267.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V267.OneToOne.OneToOne (Evergreen.V267.Discord.Id Evergreen.V267.Discord.MessageId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) Evergreen.V267.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V267.GuildName.GuildName
    , icon : Maybe Evergreen.V267.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V267.MembersAndOwner.MembersAndOwner
            (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V267.Id.Id Evergreen.V267.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V267.Id.Id Evergreen.V267.Id.CustomEmojiId)
    }
