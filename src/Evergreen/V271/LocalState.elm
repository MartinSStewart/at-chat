module Evergreen.V271.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V271.Call
import Evergreen.V271.ChannelDescription
import Evergreen.V271.ChannelName
import Evergreen.V271.Cloudflare
import Evergreen.V271.Discord
import Evergreen.V271.DiscordUserData
import Evergreen.V271.DmChannel
import Evergreen.V271.FileStatus
import Evergreen.V271.GuildName
import Evergreen.V271.Id
import Evergreen.V271.Log
import Evergreen.V271.MembersAndOwner
import Evergreen.V271.Message
import Evergreen.V271.NonemptyDict
import Evergreen.V271.OneToOne
import Evergreen.V271.Pagination
import Evergreen.V271.Postmark
import Evergreen.V271.SecretId
import Evergreen.V271.SessionIdHash
import Evergreen.V271.Slack
import Evergreen.V271.TextEditor
import Evergreen.V271.Thread
import Evergreen.V271.ToBackendLog
import Evergreen.V271.User
import Evergreen.V271.UserSession
import Evergreen.V271.VisibleMessages
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
        Evergreen.V271.NonemptyDict.NonemptyDict
            (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V271.Message.Message Evergreen.V271.Id.ChannelMessageId (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V271.Discord.PartialUser
        , icon : Maybe Evergreen.V271.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V271.Discord.User
        , linkedTo : Evergreen.V271.Id.Id Evergreen.V271.Id.UserId
        , icon : Maybe Evergreen.V271.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V271.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V271.Discord.User
        , linkedTo : Evergreen.V271.Id.Id Evergreen.V271.Id.UserId
        , icon : Maybe Evergreen.V271.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V271.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V271.Message.Message Evergreen.V271.Id.ChannelMessageId (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V271.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V271.MembersAndOwner.MembersAndOwner
            (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V271.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V271.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V271.Id.Id Evergreen.V271.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V271.GuildName.GuildName
    , owner : Evergreen.V271.Id.Id Evergreen.V271.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V271.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V271.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V271.Call.CallId
    | ConnectedToCall
        Evergreen.V271.Call.CallId
        { sessionId : Evergreen.V271.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V271.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V271.Id.Id Evergreen.V271.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V271.Id.Id Evergreen.V271.Id.UserId
    , name : Evergreen.V271.ChannelName.ChannelName
    , description : Evergreen.V271.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V271.Message.MessageState Evergreen.V271.Id.ChannelMessageId (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId))
    , visibleMessages : Evergreen.V271.VisibleMessages.VisibleMessages Evergreen.V271.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) (Evergreen.V271.Thread.LastTypedAt Evergreen.V271.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) Evergreen.V271.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V271.Id.Id Evergreen.V271.Id.UserId
    , name : Evergreen.V271.GuildName.GuildName
    , icon : Maybe Evergreen.V271.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V271.MembersAndOwner.MembersAndOwner
            (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V271.SecretId.SecretId Evergreen.V271.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V271.Id.Id Evergreen.V271.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V271.ChannelName.ChannelName
    , description : Evergreen.V271.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V271.Message.MessageState Evergreen.V271.Id.ChannelMessageId (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId))
    , visibleMessages : Evergreen.V271.VisibleMessages.VisibleMessages Evergreen.V271.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Evergreen.V271.Thread.LastTypedAt Evergreen.V271.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) Evergreen.V271.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V271.GuildName.GuildName
    , icon : Maybe Evergreen.V271.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V271.MembersAndOwner.MembersAndOwner
            (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V271.Id.Id Evergreen.V271.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V271.Id.Id Evergreen.V271.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V271.NonemptyDict.NonemptyDict (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) Evergreen.V271.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V271.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V271.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V271.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V271.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V271.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V271.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V271.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V271.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V271.SessionIdHash.SessionIdHash (Evergreen.V271.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V271.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V271.SessionIdHash.SessionIdHash Evergreen.V271.UserSession.UserSession
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) Evergreen.V271.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId) Evergreen.V271.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V271.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V271.SessionIdHash.SessionIdHash Evergreen.V271.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V271.TextEditor.LocalState
    , calls : Evergreen.V271.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V271.Id.Id Evergreen.V271.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V271.Id.Id Evergreen.V271.Id.UserId
    , name : Evergreen.V271.ChannelName.ChannelName
    , description : Evergreen.V271.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V271.Message.Message Evergreen.V271.Id.ChannelMessageId (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) (Evergreen.V271.Thread.LastTypedAt Evergreen.V271.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) Evergreen.V271.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V271.Id.Id Evergreen.V271.Id.UserId
    , name : Evergreen.V271.GuildName.GuildName
    , icon : Maybe Evergreen.V271.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V271.MembersAndOwner.MembersAndOwner
            (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V271.SecretId.SecretId Evergreen.V271.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V271.Id.Id Evergreen.V271.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V271.ChannelName.ChannelName
    , description : Evergreen.V271.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V271.Message.Message Evergreen.V271.Id.ChannelMessageId (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Evergreen.V271.Thread.LastTypedAt Evergreen.V271.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V271.OneToOne.OneToOne (Evergreen.V271.Discord.Id Evergreen.V271.Discord.MessageId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) Evergreen.V271.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V271.GuildName.GuildName
    , icon : Maybe Evergreen.V271.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V271.MembersAndOwner.MembersAndOwner
            (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V271.Id.Id Evergreen.V271.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V271.Id.Id Evergreen.V271.Id.CustomEmojiId)
    }
