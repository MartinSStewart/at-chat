module Evergreen.V255.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V255.Call
import Evergreen.V255.ChannelDescription
import Evergreen.V255.ChannelName
import Evergreen.V255.Cloudflare
import Evergreen.V255.Discord
import Evergreen.V255.DiscordUserData
import Evergreen.V255.DmChannel
import Evergreen.V255.FileStatus
import Evergreen.V255.GuildName
import Evergreen.V255.Id
import Evergreen.V255.Log
import Evergreen.V255.MembersAndOwner
import Evergreen.V255.Message
import Evergreen.V255.NonemptyDict
import Evergreen.V255.OneToOne
import Evergreen.V255.Pagination
import Evergreen.V255.Postmark
import Evergreen.V255.SecretId
import Evergreen.V255.SessionIdHash
import Evergreen.V255.Slack
import Evergreen.V255.TextEditor
import Evergreen.V255.Thread
import Evergreen.V255.ToBackendLog
import Evergreen.V255.User
import Evergreen.V255.UserSession
import Evergreen.V255.VisibleMessages
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
        Evergreen.V255.NonemptyDict.NonemptyDict
            (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V255.Message.Message Evergreen.V255.Id.ChannelMessageId (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V255.Discord.PartialUser
        , icon : Maybe Evergreen.V255.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V255.Discord.User
        , linkedTo : Evergreen.V255.Id.Id Evergreen.V255.Id.UserId
        , icon : Maybe Evergreen.V255.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V255.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V255.Discord.User
        , linkedTo : Evergreen.V255.Id.Id Evergreen.V255.Id.UserId
        , icon : Maybe Evergreen.V255.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V255.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V255.Message.Message Evergreen.V255.Id.ChannelMessageId (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V255.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V255.MembersAndOwner.MembersAndOwner
            (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V255.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V255.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V255.Id.Id Evergreen.V255.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V255.GuildName.GuildName
    , owner : Evergreen.V255.Id.Id Evergreen.V255.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V255.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V255.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V255.Call.CallId
    | ConnectedToCall
        Evergreen.V255.Call.CallId
        { sessionId : Evergreen.V255.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V255.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V255.Id.Id Evergreen.V255.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V255.Id.Id Evergreen.V255.Id.UserId
    , name : Evergreen.V255.ChannelName.ChannelName
    , description : Evergreen.V255.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V255.Message.MessageState Evergreen.V255.Id.ChannelMessageId (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId))
    , visibleMessages : Evergreen.V255.VisibleMessages.VisibleMessages Evergreen.V255.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) (Evergreen.V255.Thread.LastTypedAt Evergreen.V255.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) Evergreen.V255.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V255.Id.Id Evergreen.V255.Id.UserId
    , name : Evergreen.V255.GuildName.GuildName
    , icon : Maybe Evergreen.V255.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V255.MembersAndOwner.MembersAndOwner
            (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V255.SecretId.SecretId Evergreen.V255.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V255.Id.Id Evergreen.V255.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V255.ChannelName.ChannelName
    , description : Evergreen.V255.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V255.Message.MessageState Evergreen.V255.Id.ChannelMessageId (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId))
    , visibleMessages : Evergreen.V255.VisibleMessages.VisibleMessages Evergreen.V255.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Evergreen.V255.Thread.LastTypedAt Evergreen.V255.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) Evergreen.V255.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V255.GuildName.GuildName
    , icon : Maybe Evergreen.V255.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V255.MembersAndOwner.MembersAndOwner
            (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V255.Id.Id Evergreen.V255.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V255.Id.Id Evergreen.V255.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V255.NonemptyDict.NonemptyDict (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) Evergreen.V255.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V255.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V255.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V255.Cloudflare.AppId
    , postmarkKey : Evergreen.V255.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V255.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V255.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V255.SessionIdHash.SessionIdHash (Evergreen.V255.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V255.ToBackendLog.ToBackendLogData
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
    , guilds : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) Evergreen.V255.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId) Evergreen.V255.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V255.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V255.SessionIdHash.SessionIdHash Evergreen.V255.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V255.TextEditor.LocalState
    , calls : Evergreen.V255.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V255.Id.Id Evergreen.V255.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V255.Id.Id Evergreen.V255.Id.UserId
    , name : Evergreen.V255.ChannelName.ChannelName
    , description : Evergreen.V255.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V255.Message.Message Evergreen.V255.Id.ChannelMessageId (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) (Evergreen.V255.Thread.LastTypedAt Evergreen.V255.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) Evergreen.V255.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V255.Id.Id Evergreen.V255.Id.UserId
    , name : Evergreen.V255.GuildName.GuildName
    , icon : Maybe Evergreen.V255.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V255.MembersAndOwner.MembersAndOwner
            (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V255.SecretId.SecretId Evergreen.V255.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V255.Id.Id Evergreen.V255.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V255.ChannelName.ChannelName
    , description : Evergreen.V255.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V255.Message.Message Evergreen.V255.Id.ChannelMessageId (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Evergreen.V255.Thread.LastTypedAt Evergreen.V255.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V255.OneToOne.OneToOne (Evergreen.V255.Discord.Id Evergreen.V255.Discord.MessageId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) Evergreen.V255.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V255.GuildName.GuildName
    , icon : Maybe Evergreen.V255.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V255.MembersAndOwner.MembersAndOwner
            (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V255.Id.Id Evergreen.V255.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V255.Id.Id Evergreen.V255.Id.CustomEmojiId)
    }
