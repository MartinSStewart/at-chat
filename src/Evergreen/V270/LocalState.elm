module Evergreen.V270.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V270.Call
import Evergreen.V270.ChannelDescription
import Evergreen.V270.ChannelName
import Evergreen.V270.Cloudflare
import Evergreen.V270.Discord
import Evergreen.V270.DiscordUserData
import Evergreen.V270.DmChannel
import Evergreen.V270.FileStatus
import Evergreen.V270.GuildName
import Evergreen.V270.Id
import Evergreen.V270.Log
import Evergreen.V270.MembersAndOwner
import Evergreen.V270.Message
import Evergreen.V270.NonemptyDict
import Evergreen.V270.OneToOne
import Evergreen.V270.Pagination
import Evergreen.V270.Postmark
import Evergreen.V270.SecretId
import Evergreen.V270.SessionIdHash
import Evergreen.V270.Slack
import Evergreen.V270.TextEditor
import Evergreen.V270.Thread
import Evergreen.V270.ToBackendLog
import Evergreen.V270.User
import Evergreen.V270.UserSession
import Evergreen.V270.VisibleMessages
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
        Evergreen.V270.NonemptyDict.NonemptyDict
            (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V270.Message.Message Evergreen.V270.Id.ChannelMessageId (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V270.Discord.PartialUser
        , icon : Maybe Evergreen.V270.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V270.Discord.User
        , linkedTo : Evergreen.V270.Id.Id Evergreen.V270.Id.UserId
        , icon : Maybe Evergreen.V270.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V270.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V270.Discord.User
        , linkedTo : Evergreen.V270.Id.Id Evergreen.V270.Id.UserId
        , icon : Maybe Evergreen.V270.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V270.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V270.Message.Message Evergreen.V270.Id.ChannelMessageId (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V270.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V270.MembersAndOwner.MembersAndOwner
            (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V270.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V270.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V270.Id.Id Evergreen.V270.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V270.GuildName.GuildName
    , owner : Evergreen.V270.Id.Id Evergreen.V270.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V270.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V270.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V270.Call.CallId
    | ConnectedToCall
        Evergreen.V270.Call.CallId
        { sessionId : Evergreen.V270.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V270.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V270.Id.Id Evergreen.V270.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V270.Id.Id Evergreen.V270.Id.UserId
    , name : Evergreen.V270.ChannelName.ChannelName
    , description : Evergreen.V270.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V270.Message.MessageState Evergreen.V270.Id.ChannelMessageId (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId))
    , visibleMessages : Evergreen.V270.VisibleMessages.VisibleMessages Evergreen.V270.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) (Evergreen.V270.Thread.LastTypedAt Evergreen.V270.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) Evergreen.V270.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V270.Id.Id Evergreen.V270.Id.UserId
    , name : Evergreen.V270.GuildName.GuildName
    , icon : Maybe Evergreen.V270.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V270.MembersAndOwner.MembersAndOwner
            (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V270.SecretId.SecretId Evergreen.V270.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V270.Id.Id Evergreen.V270.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V270.ChannelName.ChannelName
    , description : Evergreen.V270.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V270.Message.MessageState Evergreen.V270.Id.ChannelMessageId (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId))
    , visibleMessages : Evergreen.V270.VisibleMessages.VisibleMessages Evergreen.V270.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Evergreen.V270.Thread.LastTypedAt Evergreen.V270.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) Evergreen.V270.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V270.GuildName.GuildName
    , icon : Maybe Evergreen.V270.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V270.MembersAndOwner.MembersAndOwner
            (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V270.Id.Id Evergreen.V270.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V270.Id.Id Evergreen.V270.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V270.NonemptyDict.NonemptyDict (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) Evergreen.V270.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V270.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V270.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V270.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V270.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V270.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V270.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V270.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V270.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V270.SessionIdHash.SessionIdHash (Evergreen.V270.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V270.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V270.SessionIdHash.SessionIdHash Evergreen.V270.UserSession.UserSession
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) Evergreen.V270.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId) Evergreen.V270.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V270.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V270.SessionIdHash.SessionIdHash Evergreen.V270.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V270.TextEditor.LocalState
    , calls : Evergreen.V270.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V270.Id.Id Evergreen.V270.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V270.Id.Id Evergreen.V270.Id.UserId
    , name : Evergreen.V270.ChannelName.ChannelName
    , description : Evergreen.V270.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V270.Message.Message Evergreen.V270.Id.ChannelMessageId (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) (Evergreen.V270.Thread.LastTypedAt Evergreen.V270.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) Evergreen.V270.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V270.Id.Id Evergreen.V270.Id.UserId
    , name : Evergreen.V270.GuildName.GuildName
    , icon : Maybe Evergreen.V270.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V270.MembersAndOwner.MembersAndOwner
            (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V270.SecretId.SecretId Evergreen.V270.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V270.Id.Id Evergreen.V270.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V270.ChannelName.ChannelName
    , description : Evergreen.V270.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V270.Message.Message Evergreen.V270.Id.ChannelMessageId (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Evergreen.V270.Thread.LastTypedAt Evergreen.V270.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V270.OneToOne.OneToOne (Evergreen.V270.Discord.Id Evergreen.V270.Discord.MessageId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) Evergreen.V270.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V270.GuildName.GuildName
    , icon : Maybe Evergreen.V270.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V270.MembersAndOwner.MembersAndOwner
            (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V270.Id.Id Evergreen.V270.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V270.Id.Id Evergreen.V270.Id.CustomEmojiId)
    }
