module Evergreen.V262.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V262.Call
import Evergreen.V262.ChannelDescription
import Evergreen.V262.ChannelName
import Evergreen.V262.Cloudflare
import Evergreen.V262.Discord
import Evergreen.V262.DiscordUserData
import Evergreen.V262.DmChannel
import Evergreen.V262.FileStatus
import Evergreen.V262.GuildName
import Evergreen.V262.Id
import Evergreen.V262.Log
import Evergreen.V262.MembersAndOwner
import Evergreen.V262.Message
import Evergreen.V262.NonemptyDict
import Evergreen.V262.OneToOne
import Evergreen.V262.Pagination
import Evergreen.V262.Postmark
import Evergreen.V262.SecretId
import Evergreen.V262.SessionIdHash
import Evergreen.V262.Slack
import Evergreen.V262.TextEditor
import Evergreen.V262.Thread
import Evergreen.V262.ToBackendLog
import Evergreen.V262.User
import Evergreen.V262.UserSession
import Evergreen.V262.VisibleMessages
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
        Evergreen.V262.NonemptyDict.NonemptyDict
            (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V262.Message.Message Evergreen.V262.Id.ChannelMessageId (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V262.Discord.PartialUser
        , icon : Maybe Evergreen.V262.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V262.Discord.User
        , linkedTo : Evergreen.V262.Id.Id Evergreen.V262.Id.UserId
        , icon : Maybe Evergreen.V262.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V262.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V262.Discord.User
        , linkedTo : Evergreen.V262.Id.Id Evergreen.V262.Id.UserId
        , icon : Maybe Evergreen.V262.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V262.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V262.Message.Message Evergreen.V262.Id.ChannelMessageId (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V262.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V262.Discord.Id Evergreen.V262.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V262.MembersAndOwner.MembersAndOwner
            (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V262.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V262.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V262.Id.Id Evergreen.V262.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V262.GuildName.GuildName
    , owner : Evergreen.V262.Id.Id Evergreen.V262.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V262.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V262.Discord.Id Evergreen.V262.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V262.Discord.Id Evergreen.V262.Discord.GuildId) (Evergreen.V262.Discord.Id Evergreen.V262.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V262.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V262.Call.CallId
    | ConnectedToCall
        Evergreen.V262.Call.CallId
        { sessionId : Evergreen.V262.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V262.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V262.Id.Id Evergreen.V262.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V262.Id.Id Evergreen.V262.Id.UserId
    , name : Evergreen.V262.ChannelName.ChannelName
    , description : Evergreen.V262.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V262.Message.MessageState Evergreen.V262.Id.ChannelMessageId (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId))
    , visibleMessages : Evergreen.V262.VisibleMessages.VisibleMessages Evergreen.V262.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId) (Evergreen.V262.Thread.LastTypedAt Evergreen.V262.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelMessageId) Evergreen.V262.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V262.Id.Id Evergreen.V262.Id.UserId
    , name : Evergreen.V262.GuildName.GuildName
    , icon : Maybe Evergreen.V262.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V262.MembersAndOwner.MembersAndOwner
            (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V262.SecretId.SecretId Evergreen.V262.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V262.Id.Id Evergreen.V262.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V262.ChannelName.ChannelName
    , description : Evergreen.V262.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V262.Message.MessageState Evergreen.V262.Id.ChannelMessageId (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId))
    , visibleMessages : Evergreen.V262.VisibleMessages.VisibleMessages Evergreen.V262.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId) (Evergreen.V262.Thread.LastTypedAt Evergreen.V262.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelMessageId) Evergreen.V262.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V262.GuildName.GuildName
    , icon : Maybe Evergreen.V262.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V262.Discord.Id Evergreen.V262.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V262.MembersAndOwner.MembersAndOwner
            (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V262.Id.Id Evergreen.V262.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V262.Id.Id Evergreen.V262.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V262.NonemptyDict.NonemptyDict (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId) Evergreen.V262.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V262.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V262.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V262.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V262.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V262.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V262.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V262.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V262.Discord.Id Evergreen.V262.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V262.Discord.Id Evergreen.V262.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V262.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V262.SessionIdHash.SessionIdHash (Evergreen.V262.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V262.ToBackendLog.ToBackendLogData
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
    , guilds : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V262.Discord.Id Evergreen.V262.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId) Evergreen.V262.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V262.Discord.Id Evergreen.V262.Discord.PrivateChannelId) Evergreen.V262.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V262.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V262.SessionIdHash.SessionIdHash Evergreen.V262.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V262.TextEditor.LocalState
    , calls : Evergreen.V262.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V262.Id.Id Evergreen.V262.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V262.Id.Id Evergreen.V262.Id.UserId
    , name : Evergreen.V262.ChannelName.ChannelName
    , description : Evergreen.V262.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V262.Message.Message Evergreen.V262.Id.ChannelMessageId (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId) (Evergreen.V262.Thread.LastTypedAt Evergreen.V262.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelMessageId) Evergreen.V262.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V262.Id.Id Evergreen.V262.Id.UserId
    , name : Evergreen.V262.GuildName.GuildName
    , icon : Maybe Evergreen.V262.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V262.MembersAndOwner.MembersAndOwner
            (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V262.SecretId.SecretId Evergreen.V262.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V262.Id.Id Evergreen.V262.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V262.ChannelName.ChannelName
    , description : Evergreen.V262.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V262.Message.Message Evergreen.V262.Id.ChannelMessageId (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId) (Evergreen.V262.Thread.LastTypedAt Evergreen.V262.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V262.OneToOne.OneToOne (Evergreen.V262.Discord.Id Evergreen.V262.Discord.MessageId) (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelMessageId) Evergreen.V262.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V262.GuildName.GuildName
    , icon : Maybe Evergreen.V262.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V262.Discord.Id Evergreen.V262.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V262.MembersAndOwner.MembersAndOwner
            (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V262.Id.Id Evergreen.V262.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V262.Id.Id Evergreen.V262.Id.CustomEmojiId)
    }
