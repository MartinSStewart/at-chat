module Evergreen.V264.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V264.Call
import Evergreen.V264.ChannelDescription
import Evergreen.V264.ChannelName
import Evergreen.V264.Cloudflare
import Evergreen.V264.Discord
import Evergreen.V264.DiscordUserData
import Evergreen.V264.DmChannel
import Evergreen.V264.FileStatus
import Evergreen.V264.GuildName
import Evergreen.V264.Id
import Evergreen.V264.Log
import Evergreen.V264.MembersAndOwner
import Evergreen.V264.Message
import Evergreen.V264.NonemptyDict
import Evergreen.V264.OneToOne
import Evergreen.V264.Pagination
import Evergreen.V264.Postmark
import Evergreen.V264.SecretId
import Evergreen.V264.SessionIdHash
import Evergreen.V264.Slack
import Evergreen.V264.TextEditor
import Evergreen.V264.Thread
import Evergreen.V264.ToBackendLog
import Evergreen.V264.User
import Evergreen.V264.UserSession
import Evergreen.V264.VisibleMessages
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
        Evergreen.V264.NonemptyDict.NonemptyDict
            (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V264.Message.Message Evergreen.V264.Id.ChannelMessageId (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V264.Discord.PartialUser
        , icon : Maybe Evergreen.V264.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V264.Discord.User
        , linkedTo : Evergreen.V264.Id.Id Evergreen.V264.Id.UserId
        , icon : Maybe Evergreen.V264.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V264.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V264.Discord.User
        , linkedTo : Evergreen.V264.Id.Id Evergreen.V264.Id.UserId
        , icon : Maybe Evergreen.V264.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V264.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V264.Message.Message Evergreen.V264.Id.ChannelMessageId (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V264.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V264.MembersAndOwner.MembersAndOwner
            (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V264.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V264.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V264.Id.Id Evergreen.V264.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V264.GuildName.GuildName
    , owner : Evergreen.V264.Id.Id Evergreen.V264.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V264.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V264.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V264.Call.CallId
    | ConnectedToCall
        Evergreen.V264.Call.CallId
        { sessionId : Evergreen.V264.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V264.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V264.Id.Id Evergreen.V264.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V264.Id.Id Evergreen.V264.Id.UserId
    , name : Evergreen.V264.ChannelName.ChannelName
    , description : Evergreen.V264.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V264.Message.MessageState Evergreen.V264.Id.ChannelMessageId (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId))
    , visibleMessages : Evergreen.V264.VisibleMessages.VisibleMessages Evergreen.V264.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) (Evergreen.V264.Thread.LastTypedAt Evergreen.V264.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) Evergreen.V264.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V264.Id.Id Evergreen.V264.Id.UserId
    , name : Evergreen.V264.GuildName.GuildName
    , icon : Maybe Evergreen.V264.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V264.MembersAndOwner.MembersAndOwner
            (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V264.SecretId.SecretId Evergreen.V264.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V264.Id.Id Evergreen.V264.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V264.ChannelName.ChannelName
    , description : Evergreen.V264.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V264.Message.MessageState Evergreen.V264.Id.ChannelMessageId (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId))
    , visibleMessages : Evergreen.V264.VisibleMessages.VisibleMessages Evergreen.V264.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Evergreen.V264.Thread.LastTypedAt Evergreen.V264.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) Evergreen.V264.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V264.GuildName.GuildName
    , icon : Maybe Evergreen.V264.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V264.MembersAndOwner.MembersAndOwner
            (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V264.Id.Id Evergreen.V264.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V264.Id.Id Evergreen.V264.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V264.NonemptyDict.NonemptyDict (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) Evergreen.V264.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V264.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V264.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V264.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V264.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V264.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V264.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V264.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V264.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V264.SessionIdHash.SessionIdHash (Evergreen.V264.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V264.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V264.SessionIdHash.SessionIdHash Evergreen.V264.UserSession.UserSession
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) Evergreen.V264.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId) Evergreen.V264.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V264.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V264.SessionIdHash.SessionIdHash Evergreen.V264.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V264.TextEditor.LocalState
    , calls : Evergreen.V264.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V264.Id.Id Evergreen.V264.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V264.Id.Id Evergreen.V264.Id.UserId
    , name : Evergreen.V264.ChannelName.ChannelName
    , description : Evergreen.V264.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V264.Message.Message Evergreen.V264.Id.ChannelMessageId (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) (Evergreen.V264.Thread.LastTypedAt Evergreen.V264.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) Evergreen.V264.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V264.Id.Id Evergreen.V264.Id.UserId
    , name : Evergreen.V264.GuildName.GuildName
    , icon : Maybe Evergreen.V264.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V264.MembersAndOwner.MembersAndOwner
            (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V264.SecretId.SecretId Evergreen.V264.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V264.Id.Id Evergreen.V264.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V264.ChannelName.ChannelName
    , description : Evergreen.V264.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V264.Message.Message Evergreen.V264.Id.ChannelMessageId (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Evergreen.V264.Thread.LastTypedAt Evergreen.V264.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V264.OneToOne.OneToOne (Evergreen.V264.Discord.Id Evergreen.V264.Discord.MessageId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) Evergreen.V264.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V264.GuildName.GuildName
    , icon : Maybe Evergreen.V264.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V264.MembersAndOwner.MembersAndOwner
            (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V264.Id.Id Evergreen.V264.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V264.Id.Id Evergreen.V264.Id.CustomEmojiId)
    }
