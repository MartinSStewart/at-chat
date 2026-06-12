module Evergreen.V286.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V286.Call
import Evergreen.V286.ChannelDescription
import Evergreen.V286.ChannelName
import Evergreen.V286.Cloudflare
import Evergreen.V286.Discord
import Evergreen.V286.DiscordUserData
import Evergreen.V286.DmChannel
import Evergreen.V286.Drawing
import Evergreen.V286.FileStatus
import Evergreen.V286.GuildName
import Evergreen.V286.Id
import Evergreen.V286.Log
import Evergreen.V286.MembersAndOwner
import Evergreen.V286.Message
import Evergreen.V286.NonemptyDict
import Evergreen.V286.OneToOne
import Evergreen.V286.Pagination
import Evergreen.V286.Postmark
import Evergreen.V286.SecretId
import Evergreen.V286.SessionIdHash
import Evergreen.V286.Slack
import Evergreen.V286.TextEditor
import Evergreen.V286.Thread
import Evergreen.V286.ToBackendLog
import Evergreen.V286.User
import Evergreen.V286.UserSession
import Evergreen.V286.VisibleMessages
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
        Evergreen.V286.NonemptyDict.NonemptyDict
            (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V286.Message.Message Evergreen.V286.Id.ChannelMessageId (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V286.Discord.PartialUser
        , icon : Maybe Evergreen.V286.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V286.Discord.User
        , linkedTo : Evergreen.V286.Id.Id Evergreen.V286.Id.UserId
        , icon : Maybe Evergreen.V286.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V286.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V286.Discord.User
        , linkedTo : Evergreen.V286.Id.Id Evergreen.V286.Id.UserId
        , icon : Maybe Evergreen.V286.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V286.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V286.Message.Message Evergreen.V286.Id.ChannelMessageId (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V286.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V286.MembersAndOwner.MembersAndOwner
            (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V286.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V286.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V286.Id.Id Evergreen.V286.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V286.GuildName.GuildName
    , owner : Evergreen.V286.Id.Id Evergreen.V286.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V286.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V286.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V286.Call.CallId
    | ConnectedToCall
        Evergreen.V286.Call.CallId
        { sessionId : Evergreen.V286.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V286.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V286.Call.RemoteCallData
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V286.Id.Id Evergreen.V286.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V286.Id.Id Evergreen.V286.Id.UserId
    , name : Evergreen.V286.ChannelName.ChannelName
    , description : Evergreen.V286.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V286.Message.MessageState Evergreen.V286.Id.ChannelMessageId (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId))
    , visibleMessages : Evergreen.V286.VisibleMessages.VisibleMessages Evergreen.V286.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) (Evergreen.V286.Thread.LastTypedAt Evergreen.V286.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) Evergreen.V286.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V286.Drawing.Drawing (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId))
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V286.Id.Id Evergreen.V286.Id.UserId
    , name : Evergreen.V286.GuildName.GuildName
    , icon : Maybe Evergreen.V286.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V286.MembersAndOwner.MembersAndOwner
            (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V286.SecretId.SecretId Evergreen.V286.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V286.Id.Id Evergreen.V286.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V286.ChannelName.ChannelName
    , description : Evergreen.V286.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V286.Message.MessageState Evergreen.V286.Id.ChannelMessageId (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId))
    , visibleMessages : Evergreen.V286.VisibleMessages.VisibleMessages Evergreen.V286.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Evergreen.V286.Thread.LastTypedAt Evergreen.V286.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) Evergreen.V286.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V286.Drawing.Drawing (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V286.GuildName.GuildName
    , icon : Maybe Evergreen.V286.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V286.MembersAndOwner.MembersAndOwner
            (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V286.Id.Id Evergreen.V286.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V286.Id.Id Evergreen.V286.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V286.NonemptyDict.NonemptyDict (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) Evergreen.V286.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V286.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V286.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V286.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V286.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V286.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V286.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V286.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V286.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V286.SessionIdHash.SessionIdHash (Evergreen.V286.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V286.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V286.SessionIdHash.SessionIdHash Evergreen.V286.UserSession.UserSession
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) Evergreen.V286.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId) Evergreen.V286.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V286.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V286.SessionIdHash.SessionIdHash Evergreen.V286.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V286.TextEditor.LocalState
    , calls : Evergreen.V286.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V286.Id.Id Evergreen.V286.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V286.Id.Id Evergreen.V286.Id.UserId
    , name : Evergreen.V286.ChannelName.ChannelName
    , description : Evergreen.V286.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V286.Message.Message Evergreen.V286.Id.ChannelMessageId (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) (Evergreen.V286.Thread.LastTypedAt Evergreen.V286.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) Evergreen.V286.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V286.Drawing.Drawing (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId))
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V286.Id.Id Evergreen.V286.Id.UserId
    , name : Evergreen.V286.GuildName.GuildName
    , icon : Maybe Evergreen.V286.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V286.MembersAndOwner.MembersAndOwner
            (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V286.SecretId.SecretId Evergreen.V286.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V286.Id.Id Evergreen.V286.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V286.ChannelName.ChannelName
    , description : Evergreen.V286.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V286.Message.Message Evergreen.V286.Id.ChannelMessageId (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Evergreen.V286.Thread.LastTypedAt Evergreen.V286.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V286.OneToOne.OneToOne (Evergreen.V286.Discord.Id Evergreen.V286.Discord.MessageId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) Evergreen.V286.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V286.Drawing.Drawing (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V286.GuildName.GuildName
    , icon : Maybe Evergreen.V286.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V286.MembersAndOwner.MembersAndOwner
            (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V286.Id.Id Evergreen.V286.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V286.Id.Id Evergreen.V286.Id.CustomEmojiId)
    }
