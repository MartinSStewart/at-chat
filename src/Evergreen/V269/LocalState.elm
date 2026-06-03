module Evergreen.V269.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V269.Call
import Evergreen.V269.ChannelDescription
import Evergreen.V269.ChannelName
import Evergreen.V269.Cloudflare
import Evergreen.V269.Discord
import Evergreen.V269.DiscordUserData
import Evergreen.V269.DmChannel
import Evergreen.V269.FileStatus
import Evergreen.V269.GuildName
import Evergreen.V269.Id
import Evergreen.V269.Log
import Evergreen.V269.MembersAndOwner
import Evergreen.V269.Message
import Evergreen.V269.NonemptyDict
import Evergreen.V269.OneToOne
import Evergreen.V269.Pagination
import Evergreen.V269.Postmark
import Evergreen.V269.SecretId
import Evergreen.V269.SessionIdHash
import Evergreen.V269.Slack
import Evergreen.V269.TextEditor
import Evergreen.V269.Thread
import Evergreen.V269.ToBackendLog
import Evergreen.V269.User
import Evergreen.V269.UserSession
import Evergreen.V269.VisibleMessages
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
        Evergreen.V269.NonemptyDict.NonemptyDict
            (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V269.Message.Message Evergreen.V269.Id.ChannelMessageId (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V269.Discord.PartialUser
        , icon : Maybe Evergreen.V269.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V269.Discord.User
        , linkedTo : Evergreen.V269.Id.Id Evergreen.V269.Id.UserId
        , icon : Maybe Evergreen.V269.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V269.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V269.Discord.User
        , linkedTo : Evergreen.V269.Id.Id Evergreen.V269.Id.UserId
        , icon : Maybe Evergreen.V269.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V269.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V269.Message.Message Evergreen.V269.Id.ChannelMessageId (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V269.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V269.MembersAndOwner.MembersAndOwner
            (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V269.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V269.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V269.Id.Id Evergreen.V269.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V269.GuildName.GuildName
    , owner : Evergreen.V269.Id.Id Evergreen.V269.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V269.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V269.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V269.Call.CallId
    | ConnectedToCall
        Evergreen.V269.Call.CallId
        { sessionId : Evergreen.V269.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V269.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V269.Id.Id Evergreen.V269.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V269.Id.Id Evergreen.V269.Id.UserId
    , name : Evergreen.V269.ChannelName.ChannelName
    , description : Evergreen.V269.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V269.Message.MessageState Evergreen.V269.Id.ChannelMessageId (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId))
    , visibleMessages : Evergreen.V269.VisibleMessages.VisibleMessages Evergreen.V269.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) (Evergreen.V269.Thread.LastTypedAt Evergreen.V269.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) Evergreen.V269.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V269.Id.Id Evergreen.V269.Id.UserId
    , name : Evergreen.V269.GuildName.GuildName
    , icon : Maybe Evergreen.V269.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V269.MembersAndOwner.MembersAndOwner
            (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V269.SecretId.SecretId Evergreen.V269.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V269.Id.Id Evergreen.V269.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V269.ChannelName.ChannelName
    , description : Evergreen.V269.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V269.Message.MessageState Evergreen.V269.Id.ChannelMessageId (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId))
    , visibleMessages : Evergreen.V269.VisibleMessages.VisibleMessages Evergreen.V269.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Evergreen.V269.Thread.LastTypedAt Evergreen.V269.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) Evergreen.V269.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V269.GuildName.GuildName
    , icon : Maybe Evergreen.V269.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V269.MembersAndOwner.MembersAndOwner
            (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V269.Id.Id Evergreen.V269.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V269.Id.Id Evergreen.V269.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V269.NonemptyDict.NonemptyDict (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) Evergreen.V269.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V269.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V269.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V269.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V269.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V269.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V269.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V269.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V269.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V269.SessionIdHash.SessionIdHash (Evergreen.V269.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V269.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V269.SessionIdHash.SessionIdHash Evergreen.V269.UserSession.UserSession
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) Evergreen.V269.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId) Evergreen.V269.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V269.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V269.SessionIdHash.SessionIdHash Evergreen.V269.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V269.TextEditor.LocalState
    , calls : Evergreen.V269.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V269.Id.Id Evergreen.V269.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V269.Id.Id Evergreen.V269.Id.UserId
    , name : Evergreen.V269.ChannelName.ChannelName
    , description : Evergreen.V269.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V269.Message.Message Evergreen.V269.Id.ChannelMessageId (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) (Evergreen.V269.Thread.LastTypedAt Evergreen.V269.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) Evergreen.V269.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V269.Id.Id Evergreen.V269.Id.UserId
    , name : Evergreen.V269.GuildName.GuildName
    , icon : Maybe Evergreen.V269.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V269.MembersAndOwner.MembersAndOwner
            (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V269.SecretId.SecretId Evergreen.V269.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V269.Id.Id Evergreen.V269.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V269.ChannelName.ChannelName
    , description : Evergreen.V269.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V269.Message.Message Evergreen.V269.Id.ChannelMessageId (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Evergreen.V269.Thread.LastTypedAt Evergreen.V269.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V269.OneToOne.OneToOne (Evergreen.V269.Discord.Id Evergreen.V269.Discord.MessageId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) Evergreen.V269.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V269.GuildName.GuildName
    , icon : Maybe Evergreen.V269.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V269.MembersAndOwner.MembersAndOwner
            (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V269.Id.Id Evergreen.V269.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V269.Id.Id Evergreen.V269.Id.CustomEmojiId)
    }
