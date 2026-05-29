module Evergreen.V261.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V261.Call
import Evergreen.V261.ChannelDescription
import Evergreen.V261.ChannelName
import Evergreen.V261.Cloudflare
import Evergreen.V261.Discord
import Evergreen.V261.DiscordUserData
import Evergreen.V261.DmChannel
import Evergreen.V261.FileStatus
import Evergreen.V261.GuildName
import Evergreen.V261.Id
import Evergreen.V261.Log
import Evergreen.V261.MembersAndOwner
import Evergreen.V261.Message
import Evergreen.V261.NonemptyDict
import Evergreen.V261.OneToOne
import Evergreen.V261.Pagination
import Evergreen.V261.Postmark
import Evergreen.V261.SecretId
import Evergreen.V261.SessionIdHash
import Evergreen.V261.Slack
import Evergreen.V261.TextEditor
import Evergreen.V261.Thread
import Evergreen.V261.ToBackendLog
import Evergreen.V261.User
import Evergreen.V261.UserSession
import Evergreen.V261.VisibleMessages
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
        Evergreen.V261.NonemptyDict.NonemptyDict
            (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V261.Message.Message Evergreen.V261.Id.ChannelMessageId (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V261.Discord.PartialUser
        , icon : Maybe Evergreen.V261.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V261.Discord.User
        , linkedTo : Evergreen.V261.Id.Id Evergreen.V261.Id.UserId
        , icon : Maybe Evergreen.V261.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V261.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V261.Discord.User
        , linkedTo : Evergreen.V261.Id.Id Evergreen.V261.Id.UserId
        , icon : Maybe Evergreen.V261.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V261.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V261.Message.Message Evergreen.V261.Id.ChannelMessageId (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V261.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V261.MembersAndOwner.MembersAndOwner
            (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V261.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V261.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V261.Id.Id Evergreen.V261.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V261.GuildName.GuildName
    , owner : Evergreen.V261.Id.Id Evergreen.V261.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V261.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V261.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V261.Call.CallId
    | ConnectedToCall
        Evergreen.V261.Call.CallId
        { sessionId : Evergreen.V261.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V261.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V261.Id.Id Evergreen.V261.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V261.Id.Id Evergreen.V261.Id.UserId
    , name : Evergreen.V261.ChannelName.ChannelName
    , description : Evergreen.V261.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V261.Message.MessageState Evergreen.V261.Id.ChannelMessageId (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId))
    , visibleMessages : Evergreen.V261.VisibleMessages.VisibleMessages Evergreen.V261.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) (Evergreen.V261.Thread.LastTypedAt Evergreen.V261.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) Evergreen.V261.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V261.Id.Id Evergreen.V261.Id.UserId
    , name : Evergreen.V261.GuildName.GuildName
    , icon : Maybe Evergreen.V261.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V261.MembersAndOwner.MembersAndOwner
            (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V261.SecretId.SecretId Evergreen.V261.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V261.Id.Id Evergreen.V261.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V261.ChannelName.ChannelName
    , description : Evergreen.V261.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V261.Message.MessageState Evergreen.V261.Id.ChannelMessageId (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId))
    , visibleMessages : Evergreen.V261.VisibleMessages.VisibleMessages Evergreen.V261.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Evergreen.V261.Thread.LastTypedAt Evergreen.V261.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) Evergreen.V261.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V261.GuildName.GuildName
    , icon : Maybe Evergreen.V261.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V261.MembersAndOwner.MembersAndOwner
            (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V261.Id.Id Evergreen.V261.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V261.Id.Id Evergreen.V261.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V261.NonemptyDict.NonemptyDict (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) Evergreen.V261.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V261.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V261.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V261.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V261.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V261.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V261.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V261.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V261.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V261.SessionIdHash.SessionIdHash (Evergreen.V261.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V261.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) Evergreen.V261.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId) Evergreen.V261.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V261.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V261.SessionIdHash.SessionIdHash Evergreen.V261.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V261.TextEditor.LocalState
    , calls : Evergreen.V261.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V261.Id.Id Evergreen.V261.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V261.Id.Id Evergreen.V261.Id.UserId
    , name : Evergreen.V261.ChannelName.ChannelName
    , description : Evergreen.V261.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V261.Message.Message Evergreen.V261.Id.ChannelMessageId (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) (Evergreen.V261.Thread.LastTypedAt Evergreen.V261.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) Evergreen.V261.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V261.Id.Id Evergreen.V261.Id.UserId
    , name : Evergreen.V261.GuildName.GuildName
    , icon : Maybe Evergreen.V261.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V261.MembersAndOwner.MembersAndOwner
            (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V261.SecretId.SecretId Evergreen.V261.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V261.Id.Id Evergreen.V261.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V261.ChannelName.ChannelName
    , description : Evergreen.V261.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V261.Message.Message Evergreen.V261.Id.ChannelMessageId (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Evergreen.V261.Thread.LastTypedAt Evergreen.V261.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V261.OneToOne.OneToOne (Evergreen.V261.Discord.Id Evergreen.V261.Discord.MessageId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) Evergreen.V261.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V261.GuildName.GuildName
    , icon : Maybe Evergreen.V261.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V261.MembersAndOwner.MembersAndOwner
            (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V261.Id.Id Evergreen.V261.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V261.Id.Id Evergreen.V261.Id.CustomEmojiId)
    }
