module Evergreen.V293.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V293.Call
import Evergreen.V293.ChannelDescription
import Evergreen.V293.ChannelName
import Evergreen.V293.Cloudflare
import Evergreen.V293.Discord
import Evergreen.V293.DiscordUserData
import Evergreen.V293.DmChannel
import Evergreen.V293.Drawing
import Evergreen.V293.FileStatus
import Evergreen.V293.GuildName
import Evergreen.V293.Id
import Evergreen.V293.Log
import Evergreen.V293.MembersAndOwner
import Evergreen.V293.Message
import Evergreen.V293.NonemptyDict
import Evergreen.V293.OneToOne
import Evergreen.V293.Pagination
import Evergreen.V293.Postmark
import Evergreen.V293.SecretId
import Evergreen.V293.SessionIdHash
import Evergreen.V293.Slack
import Evergreen.V293.TextEditor
import Evergreen.V293.Thread
import Evergreen.V293.ToBackendLog
import Evergreen.V293.User
import Evergreen.V293.UserSession
import Evergreen.V293.VisibleMessages
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
        Evergreen.V293.NonemptyDict.NonemptyDict
            (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V293.Message.Message Evergreen.V293.Id.ChannelMessageId (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V293.Discord.PartialUser
        , icon : Maybe Evergreen.V293.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V293.Discord.User
        , linkedTo : Evergreen.V293.Id.Id Evergreen.V293.Id.UserId
        , icon : Maybe Evergreen.V293.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V293.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V293.Discord.User
        , linkedTo : Evergreen.V293.Id.Id Evergreen.V293.Id.UserId
        , icon : Maybe Evergreen.V293.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V293.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V293.Message.Message Evergreen.V293.Id.ChannelMessageId (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V293.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V293.MembersAndOwner.MembersAndOwner
            (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V293.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V293.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V293.Id.Id Evergreen.V293.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V293.GuildName.GuildName
    , owner : Evergreen.V293.Id.Id Evergreen.V293.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V293.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V293.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V293.Call.CallId
    | ConnectedToCall
        Evergreen.V293.Call.CallId
        { sessionId : Evergreen.V293.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V293.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V293.Call.RemoteCallData
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V293.Id.Id Evergreen.V293.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V293.Id.Id Evergreen.V293.Id.UserId
    , name : Evergreen.V293.ChannelName.ChannelName
    , description : Evergreen.V293.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V293.Message.MessageState Evergreen.V293.Id.ChannelMessageId (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId))
    , visibleMessages : Evergreen.V293.VisibleMessages.VisibleMessages Evergreen.V293.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) (Evergreen.V293.Thread.LastTypedAt Evergreen.V293.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) Evergreen.V293.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V293.Drawing.Drawing (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId))
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V293.Id.Id Evergreen.V293.Id.UserId
    , name : Evergreen.V293.GuildName.GuildName
    , icon : Maybe Evergreen.V293.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V293.MembersAndOwner.MembersAndOwner
            (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V293.SecretId.SecretId Evergreen.V293.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V293.Id.Id Evergreen.V293.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V293.ChannelName.ChannelName
    , description : Evergreen.V293.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V293.Message.MessageState Evergreen.V293.Id.ChannelMessageId (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId))
    , visibleMessages : Evergreen.V293.VisibleMessages.VisibleMessages Evergreen.V293.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Evergreen.V293.Thread.LastTypedAt Evergreen.V293.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) Evergreen.V293.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V293.Drawing.Drawing (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V293.GuildName.GuildName
    , icon : Maybe Evergreen.V293.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V293.MembersAndOwner.MembersAndOwner
            (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V293.Id.Id Evergreen.V293.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V293.Id.Id Evergreen.V293.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V293.NonemptyDict.NonemptyDict (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) Evergreen.V293.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V293.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V293.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V293.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V293.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V293.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V293.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V293.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V293.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V293.SessionIdHash.SessionIdHash (Evergreen.V293.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V293.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V293.SessionIdHash.SessionIdHash Evergreen.V293.UserSession.UserSession
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) Evergreen.V293.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId) Evergreen.V293.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V293.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V293.SessionIdHash.SessionIdHash Evergreen.V293.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V293.TextEditor.LocalState
    , calls : Evergreen.V293.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V293.Id.Id Evergreen.V293.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V293.Id.Id Evergreen.V293.Id.UserId
    , name : Evergreen.V293.ChannelName.ChannelName
    , description : Evergreen.V293.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V293.Message.Message Evergreen.V293.Id.ChannelMessageId (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) (Evergreen.V293.Thread.LastTypedAt Evergreen.V293.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) Evergreen.V293.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V293.Drawing.Drawing (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId))
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V293.Id.Id Evergreen.V293.Id.UserId
    , name : Evergreen.V293.GuildName.GuildName
    , icon : Maybe Evergreen.V293.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V293.MembersAndOwner.MembersAndOwner
            (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V293.SecretId.SecretId Evergreen.V293.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V293.Id.Id Evergreen.V293.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V293.ChannelName.ChannelName
    , description : Evergreen.V293.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V293.Message.Message Evergreen.V293.Id.ChannelMessageId (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Evergreen.V293.Thread.LastTypedAt Evergreen.V293.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V293.OneToOne.OneToOne (Evergreen.V293.Discord.Id Evergreen.V293.Discord.MessageId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) Evergreen.V293.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V293.Drawing.Drawing (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V293.GuildName.GuildName
    , icon : Maybe Evergreen.V293.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V293.MembersAndOwner.MembersAndOwner
            (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V293.Id.Id Evergreen.V293.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V293.Id.Id Evergreen.V293.Id.CustomEmojiId)
    }
