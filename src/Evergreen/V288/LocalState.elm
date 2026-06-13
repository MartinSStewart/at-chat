module Evergreen.V288.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V288.Call
import Evergreen.V288.ChannelDescription
import Evergreen.V288.ChannelName
import Evergreen.V288.Cloudflare
import Evergreen.V288.Discord
import Evergreen.V288.DiscordUserData
import Evergreen.V288.DmChannel
import Evergreen.V288.Drawing
import Evergreen.V288.FileStatus
import Evergreen.V288.GuildName
import Evergreen.V288.Id
import Evergreen.V288.Log
import Evergreen.V288.MembersAndOwner
import Evergreen.V288.Message
import Evergreen.V288.NonemptyDict
import Evergreen.V288.OneToOne
import Evergreen.V288.Pagination
import Evergreen.V288.Postmark
import Evergreen.V288.SecretId
import Evergreen.V288.SessionIdHash
import Evergreen.V288.Slack
import Evergreen.V288.TextEditor
import Evergreen.V288.Thread
import Evergreen.V288.ToBackendLog
import Evergreen.V288.User
import Evergreen.V288.UserSession
import Evergreen.V288.VisibleMessages
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
        Evergreen.V288.NonemptyDict.NonemptyDict
            (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V288.Message.Message Evergreen.V288.Id.ChannelMessageId (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V288.Discord.PartialUser
        , icon : Maybe Evergreen.V288.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V288.Discord.User
        , linkedTo : Evergreen.V288.Id.Id Evergreen.V288.Id.UserId
        , icon : Maybe Evergreen.V288.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V288.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V288.Discord.User
        , linkedTo : Evergreen.V288.Id.Id Evergreen.V288.Id.UserId
        , icon : Maybe Evergreen.V288.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V288.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V288.Message.Message Evergreen.V288.Id.ChannelMessageId (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V288.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V288.MembersAndOwner.MembersAndOwner
            (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V288.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V288.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V288.Id.Id Evergreen.V288.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V288.GuildName.GuildName
    , owner : Evergreen.V288.Id.Id Evergreen.V288.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V288.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V288.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V288.Call.CallId
    | ConnectedToCall
        Evergreen.V288.Call.CallId
        { sessionId : Evergreen.V288.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V288.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V288.Call.RemoteCallData
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V288.Id.Id Evergreen.V288.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V288.Id.Id Evergreen.V288.Id.UserId
    , name : Evergreen.V288.ChannelName.ChannelName
    , description : Evergreen.V288.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V288.Message.MessageState Evergreen.V288.Id.ChannelMessageId (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId))
    , visibleMessages : Evergreen.V288.VisibleMessages.VisibleMessages Evergreen.V288.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) (Evergreen.V288.Thread.LastTypedAt Evergreen.V288.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) Evergreen.V288.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V288.Drawing.Drawing (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId))
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V288.Id.Id Evergreen.V288.Id.UserId
    , name : Evergreen.V288.GuildName.GuildName
    , icon : Maybe Evergreen.V288.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V288.MembersAndOwner.MembersAndOwner
            (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V288.SecretId.SecretId Evergreen.V288.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V288.Id.Id Evergreen.V288.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V288.ChannelName.ChannelName
    , description : Evergreen.V288.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V288.Message.MessageState Evergreen.V288.Id.ChannelMessageId (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId))
    , visibleMessages : Evergreen.V288.VisibleMessages.VisibleMessages Evergreen.V288.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Evergreen.V288.Thread.LastTypedAt Evergreen.V288.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) Evergreen.V288.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V288.Drawing.Drawing (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V288.GuildName.GuildName
    , icon : Maybe Evergreen.V288.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V288.MembersAndOwner.MembersAndOwner
            (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V288.Id.Id Evergreen.V288.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V288.Id.Id Evergreen.V288.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V288.NonemptyDict.NonemptyDict (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) Evergreen.V288.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V288.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V288.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V288.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V288.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V288.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V288.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V288.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V288.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V288.SessionIdHash.SessionIdHash (Evergreen.V288.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V288.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V288.SessionIdHash.SessionIdHash Evergreen.V288.UserSession.UserSession
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) Evergreen.V288.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId) Evergreen.V288.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V288.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V288.SessionIdHash.SessionIdHash Evergreen.V288.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V288.TextEditor.LocalState
    , calls : Evergreen.V288.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V288.Id.Id Evergreen.V288.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V288.Id.Id Evergreen.V288.Id.UserId
    , name : Evergreen.V288.ChannelName.ChannelName
    , description : Evergreen.V288.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V288.Message.Message Evergreen.V288.Id.ChannelMessageId (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) (Evergreen.V288.Thread.LastTypedAt Evergreen.V288.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) Evergreen.V288.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V288.Drawing.Drawing (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId))
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V288.Id.Id Evergreen.V288.Id.UserId
    , name : Evergreen.V288.GuildName.GuildName
    , icon : Maybe Evergreen.V288.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V288.MembersAndOwner.MembersAndOwner
            (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V288.SecretId.SecretId Evergreen.V288.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V288.Id.Id Evergreen.V288.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V288.ChannelName.ChannelName
    , description : Evergreen.V288.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V288.Message.Message Evergreen.V288.Id.ChannelMessageId (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Evergreen.V288.Thread.LastTypedAt Evergreen.V288.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V288.OneToOne.OneToOne (Evergreen.V288.Discord.Id Evergreen.V288.Discord.MessageId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) Evergreen.V288.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V288.Drawing.Drawing (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V288.GuildName.GuildName
    , icon : Maybe Evergreen.V288.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V288.MembersAndOwner.MembersAndOwner
            (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V288.Id.Id Evergreen.V288.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V288.Id.Id Evergreen.V288.Id.CustomEmojiId)
    }
