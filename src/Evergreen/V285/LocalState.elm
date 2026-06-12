module Evergreen.V285.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V285.Call
import Evergreen.V285.ChannelDescription
import Evergreen.V285.ChannelName
import Evergreen.V285.Cloudflare
import Evergreen.V285.Discord
import Evergreen.V285.DiscordUserData
import Evergreen.V285.DmChannel
import Evergreen.V285.Drawing
import Evergreen.V285.FileStatus
import Evergreen.V285.GuildName
import Evergreen.V285.Id
import Evergreen.V285.Log
import Evergreen.V285.MembersAndOwner
import Evergreen.V285.Message
import Evergreen.V285.NonemptyDict
import Evergreen.V285.OneToOne
import Evergreen.V285.Pagination
import Evergreen.V285.Postmark
import Evergreen.V285.SecretId
import Evergreen.V285.SessionIdHash
import Evergreen.V285.Slack
import Evergreen.V285.TextEditor
import Evergreen.V285.Thread
import Evergreen.V285.ToBackendLog
import Evergreen.V285.User
import Evergreen.V285.UserSession
import Evergreen.V285.VisibleMessages
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
        Evergreen.V285.NonemptyDict.NonemptyDict
            (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V285.Message.Message Evergreen.V285.Id.ChannelMessageId (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V285.Discord.PartialUser
        , icon : Maybe Evergreen.V285.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V285.Discord.User
        , linkedTo : Evergreen.V285.Id.Id Evergreen.V285.Id.UserId
        , icon : Maybe Evergreen.V285.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V285.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V285.Discord.User
        , linkedTo : Evergreen.V285.Id.Id Evergreen.V285.Id.UserId
        , icon : Maybe Evergreen.V285.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V285.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V285.Message.Message Evergreen.V285.Id.ChannelMessageId (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V285.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V285.MembersAndOwner.MembersAndOwner
            (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V285.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V285.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V285.Id.Id Evergreen.V285.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V285.GuildName.GuildName
    , owner : Evergreen.V285.Id.Id Evergreen.V285.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V285.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V285.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V285.Call.CallId
    | ConnectedToCall
        Evergreen.V285.Call.CallId
        { sessionId : Evergreen.V285.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V285.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V285.Call.RemoteCallData
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V285.Id.Id Evergreen.V285.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V285.Id.Id Evergreen.V285.Id.UserId
    , name : Evergreen.V285.ChannelName.ChannelName
    , description : Evergreen.V285.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V285.Message.MessageState Evergreen.V285.Id.ChannelMessageId (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId))
    , visibleMessages : Evergreen.V285.VisibleMessages.VisibleMessages Evergreen.V285.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) (Evergreen.V285.Thread.LastTypedAt Evergreen.V285.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) Evergreen.V285.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V285.Drawing.Drawing (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId))
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V285.Id.Id Evergreen.V285.Id.UserId
    , name : Evergreen.V285.GuildName.GuildName
    , icon : Maybe Evergreen.V285.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V285.MembersAndOwner.MembersAndOwner
            (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V285.SecretId.SecretId Evergreen.V285.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V285.Id.Id Evergreen.V285.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V285.ChannelName.ChannelName
    , description : Evergreen.V285.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V285.Message.MessageState Evergreen.V285.Id.ChannelMessageId (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId))
    , visibleMessages : Evergreen.V285.VisibleMessages.VisibleMessages Evergreen.V285.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Evergreen.V285.Thread.LastTypedAt Evergreen.V285.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) Evergreen.V285.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V285.Drawing.Drawing (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V285.GuildName.GuildName
    , icon : Maybe Evergreen.V285.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V285.MembersAndOwner.MembersAndOwner
            (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V285.Id.Id Evergreen.V285.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V285.Id.Id Evergreen.V285.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V285.NonemptyDict.NonemptyDict (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) Evergreen.V285.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V285.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V285.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V285.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V285.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V285.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V285.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V285.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V285.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V285.SessionIdHash.SessionIdHash (Evergreen.V285.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V285.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V285.SessionIdHash.SessionIdHash Evergreen.V285.UserSession.UserSession
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) Evergreen.V285.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId) Evergreen.V285.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V285.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V285.SessionIdHash.SessionIdHash Evergreen.V285.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V285.TextEditor.LocalState
    , calls : Evergreen.V285.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V285.Id.Id Evergreen.V285.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V285.Id.Id Evergreen.V285.Id.UserId
    , name : Evergreen.V285.ChannelName.ChannelName
    , description : Evergreen.V285.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V285.Message.Message Evergreen.V285.Id.ChannelMessageId (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) (Evergreen.V285.Thread.LastTypedAt Evergreen.V285.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) Evergreen.V285.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V285.Drawing.Drawing (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId))
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V285.Id.Id Evergreen.V285.Id.UserId
    , name : Evergreen.V285.GuildName.GuildName
    , icon : Maybe Evergreen.V285.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V285.MembersAndOwner.MembersAndOwner
            (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V285.SecretId.SecretId Evergreen.V285.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V285.Id.Id Evergreen.V285.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V285.ChannelName.ChannelName
    , description : Evergreen.V285.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V285.Message.Message Evergreen.V285.Id.ChannelMessageId (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Evergreen.V285.Thread.LastTypedAt Evergreen.V285.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V285.OneToOne.OneToOne (Evergreen.V285.Discord.Id Evergreen.V285.Discord.MessageId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) Evergreen.V285.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V285.Drawing.Drawing (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V285.GuildName.GuildName
    , icon : Maybe Evergreen.V285.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V285.MembersAndOwner.MembersAndOwner
            (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V285.Id.Id Evergreen.V285.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V285.Id.Id Evergreen.V285.Id.CustomEmojiId)
    }
