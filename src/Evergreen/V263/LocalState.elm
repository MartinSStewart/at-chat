module Evergreen.V263.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V263.Call
import Evergreen.V263.ChannelDescription
import Evergreen.V263.ChannelName
import Evergreen.V263.Cloudflare
import Evergreen.V263.Discord
import Evergreen.V263.DiscordUserData
import Evergreen.V263.DmChannel
import Evergreen.V263.FileStatus
import Evergreen.V263.GuildName
import Evergreen.V263.Id
import Evergreen.V263.Log
import Evergreen.V263.MembersAndOwner
import Evergreen.V263.Message
import Evergreen.V263.NonemptyDict
import Evergreen.V263.OneToOne
import Evergreen.V263.Pagination
import Evergreen.V263.Postmark
import Evergreen.V263.SecretId
import Evergreen.V263.SessionIdHash
import Evergreen.V263.Slack
import Evergreen.V263.TextEditor
import Evergreen.V263.Thread
import Evergreen.V263.ToBackendLog
import Evergreen.V263.User
import Evergreen.V263.UserSession
import Evergreen.V263.VisibleMessages
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
        Evergreen.V263.NonemptyDict.NonemptyDict
            (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V263.Message.Message Evergreen.V263.Id.ChannelMessageId (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V263.Discord.PartialUser
        , icon : Maybe Evergreen.V263.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V263.Discord.User
        , linkedTo : Evergreen.V263.Id.Id Evergreen.V263.Id.UserId
        , icon : Maybe Evergreen.V263.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V263.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V263.Discord.User
        , linkedTo : Evergreen.V263.Id.Id Evergreen.V263.Id.UserId
        , icon : Maybe Evergreen.V263.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V263.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V263.Message.Message Evergreen.V263.Id.ChannelMessageId (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V263.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V263.MembersAndOwner.MembersAndOwner
            (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V263.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V263.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V263.Id.Id Evergreen.V263.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V263.GuildName.GuildName
    , owner : Evergreen.V263.Id.Id Evergreen.V263.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V263.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V263.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V263.Call.CallId
    | ConnectedToCall
        Evergreen.V263.Call.CallId
        { sessionId : Evergreen.V263.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V263.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V263.Id.Id Evergreen.V263.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V263.Id.Id Evergreen.V263.Id.UserId
    , name : Evergreen.V263.ChannelName.ChannelName
    , description : Evergreen.V263.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V263.Message.MessageState Evergreen.V263.Id.ChannelMessageId (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId))
    , visibleMessages : Evergreen.V263.VisibleMessages.VisibleMessages Evergreen.V263.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) (Evergreen.V263.Thread.LastTypedAt Evergreen.V263.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) Evergreen.V263.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V263.Id.Id Evergreen.V263.Id.UserId
    , name : Evergreen.V263.GuildName.GuildName
    , icon : Maybe Evergreen.V263.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V263.MembersAndOwner.MembersAndOwner
            (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V263.SecretId.SecretId Evergreen.V263.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V263.Id.Id Evergreen.V263.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V263.ChannelName.ChannelName
    , description : Evergreen.V263.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V263.Message.MessageState Evergreen.V263.Id.ChannelMessageId (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId))
    , visibleMessages : Evergreen.V263.VisibleMessages.VisibleMessages Evergreen.V263.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Evergreen.V263.Thread.LastTypedAt Evergreen.V263.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) Evergreen.V263.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V263.GuildName.GuildName
    , icon : Maybe Evergreen.V263.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V263.MembersAndOwner.MembersAndOwner
            (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V263.Id.Id Evergreen.V263.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V263.Id.Id Evergreen.V263.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V263.NonemptyDict.NonemptyDict (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) Evergreen.V263.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V263.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V263.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V263.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V263.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V263.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V263.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V263.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V263.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V263.SessionIdHash.SessionIdHash (Evergreen.V263.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V263.ToBackendLog.ToBackendLogData
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
    , guilds : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) Evergreen.V263.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId) Evergreen.V263.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V263.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V263.SessionIdHash.SessionIdHash Evergreen.V263.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V263.TextEditor.LocalState
    , calls : Evergreen.V263.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V263.Id.Id Evergreen.V263.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V263.Id.Id Evergreen.V263.Id.UserId
    , name : Evergreen.V263.ChannelName.ChannelName
    , description : Evergreen.V263.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V263.Message.Message Evergreen.V263.Id.ChannelMessageId (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) (Evergreen.V263.Thread.LastTypedAt Evergreen.V263.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) Evergreen.V263.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V263.Id.Id Evergreen.V263.Id.UserId
    , name : Evergreen.V263.GuildName.GuildName
    , icon : Maybe Evergreen.V263.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V263.MembersAndOwner.MembersAndOwner
            (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V263.SecretId.SecretId Evergreen.V263.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V263.Id.Id Evergreen.V263.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V263.ChannelName.ChannelName
    , description : Evergreen.V263.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V263.Message.Message Evergreen.V263.Id.ChannelMessageId (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Evergreen.V263.Thread.LastTypedAt Evergreen.V263.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V263.OneToOne.OneToOne (Evergreen.V263.Discord.Id Evergreen.V263.Discord.MessageId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) Evergreen.V263.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V263.GuildName.GuildName
    , icon : Maybe Evergreen.V263.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V263.MembersAndOwner.MembersAndOwner
            (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V263.Id.Id Evergreen.V263.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V263.Id.Id Evergreen.V263.Id.CustomEmojiId)
    }
