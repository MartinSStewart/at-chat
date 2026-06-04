module Evergreen.V273.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V273.Call
import Evergreen.V273.ChannelDescription
import Evergreen.V273.ChannelName
import Evergreen.V273.Cloudflare
import Evergreen.V273.Discord
import Evergreen.V273.DiscordUserData
import Evergreen.V273.DmChannel
import Evergreen.V273.FileStatus
import Evergreen.V273.GuildName
import Evergreen.V273.Id
import Evergreen.V273.Log
import Evergreen.V273.MembersAndOwner
import Evergreen.V273.Message
import Evergreen.V273.NonemptyDict
import Evergreen.V273.OneToOne
import Evergreen.V273.Pagination
import Evergreen.V273.Postmark
import Evergreen.V273.SecretId
import Evergreen.V273.SessionIdHash
import Evergreen.V273.Slack
import Evergreen.V273.TextEditor
import Evergreen.V273.Thread
import Evergreen.V273.ToBackendLog
import Evergreen.V273.User
import Evergreen.V273.UserSession
import Evergreen.V273.VisibleMessages
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
        Evergreen.V273.NonemptyDict.NonemptyDict
            (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V273.Message.Message Evergreen.V273.Id.ChannelMessageId (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V273.Discord.PartialUser
        , icon : Maybe Evergreen.V273.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V273.Discord.User
        , linkedTo : Evergreen.V273.Id.Id Evergreen.V273.Id.UserId
        , icon : Maybe Evergreen.V273.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V273.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V273.Discord.User
        , linkedTo : Evergreen.V273.Id.Id Evergreen.V273.Id.UserId
        , icon : Maybe Evergreen.V273.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V273.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V273.Message.Message Evergreen.V273.Id.ChannelMessageId (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V273.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V273.MembersAndOwner.MembersAndOwner
            (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V273.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V273.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V273.Id.Id Evergreen.V273.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V273.GuildName.GuildName
    , owner : Evergreen.V273.Id.Id Evergreen.V273.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V273.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V273.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V273.Call.CallId
    | ConnectedToCall
        Evergreen.V273.Call.CallId
        { sessionId : Evergreen.V273.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V273.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V273.Id.Id Evergreen.V273.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V273.Id.Id Evergreen.V273.Id.UserId
    , name : Evergreen.V273.ChannelName.ChannelName
    , description : Evergreen.V273.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V273.Message.MessageState Evergreen.V273.Id.ChannelMessageId (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId))
    , visibleMessages : Evergreen.V273.VisibleMessages.VisibleMessages Evergreen.V273.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) (Evergreen.V273.Thread.LastTypedAt Evergreen.V273.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) Evergreen.V273.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V273.Id.Id Evergreen.V273.Id.UserId
    , name : Evergreen.V273.GuildName.GuildName
    , icon : Maybe Evergreen.V273.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V273.MembersAndOwner.MembersAndOwner
            (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V273.SecretId.SecretId Evergreen.V273.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V273.Id.Id Evergreen.V273.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V273.ChannelName.ChannelName
    , description : Evergreen.V273.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V273.Message.MessageState Evergreen.V273.Id.ChannelMessageId (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId))
    , visibleMessages : Evergreen.V273.VisibleMessages.VisibleMessages Evergreen.V273.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Evergreen.V273.Thread.LastTypedAt Evergreen.V273.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) Evergreen.V273.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V273.GuildName.GuildName
    , icon : Maybe Evergreen.V273.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V273.MembersAndOwner.MembersAndOwner
            (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V273.Id.Id Evergreen.V273.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V273.Id.Id Evergreen.V273.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V273.NonemptyDict.NonemptyDict (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) Evergreen.V273.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V273.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V273.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V273.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V273.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V273.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V273.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V273.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V273.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V273.SessionIdHash.SessionIdHash (Evergreen.V273.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V273.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V273.SessionIdHash.SessionIdHash Evergreen.V273.UserSession.UserSession
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) Evergreen.V273.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId) Evergreen.V273.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V273.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V273.SessionIdHash.SessionIdHash Evergreen.V273.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V273.TextEditor.LocalState
    , calls : Evergreen.V273.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V273.Id.Id Evergreen.V273.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V273.Id.Id Evergreen.V273.Id.UserId
    , name : Evergreen.V273.ChannelName.ChannelName
    , description : Evergreen.V273.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V273.Message.Message Evergreen.V273.Id.ChannelMessageId (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) (Evergreen.V273.Thread.LastTypedAt Evergreen.V273.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) Evergreen.V273.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V273.Id.Id Evergreen.V273.Id.UserId
    , name : Evergreen.V273.GuildName.GuildName
    , icon : Maybe Evergreen.V273.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V273.MembersAndOwner.MembersAndOwner
            (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V273.SecretId.SecretId Evergreen.V273.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V273.Id.Id Evergreen.V273.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V273.ChannelName.ChannelName
    , description : Evergreen.V273.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V273.Message.Message Evergreen.V273.Id.ChannelMessageId (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Evergreen.V273.Thread.LastTypedAt Evergreen.V273.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V273.OneToOne.OneToOne (Evergreen.V273.Discord.Id Evergreen.V273.Discord.MessageId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) Evergreen.V273.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V273.GuildName.GuildName
    , icon : Maybe Evergreen.V273.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V273.MembersAndOwner.MembersAndOwner
            (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V273.Id.Id Evergreen.V273.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V273.Id.Id Evergreen.V273.Id.CustomEmojiId)
    }
