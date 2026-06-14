module Evergreen.V289.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V289.Call
import Evergreen.V289.ChannelDescription
import Evergreen.V289.ChannelName
import Evergreen.V289.Cloudflare
import Evergreen.V289.Discord
import Evergreen.V289.DiscordUserData
import Evergreen.V289.DmChannel
import Evergreen.V289.Drawing
import Evergreen.V289.FileStatus
import Evergreen.V289.GuildName
import Evergreen.V289.Id
import Evergreen.V289.Log
import Evergreen.V289.MembersAndOwner
import Evergreen.V289.Message
import Evergreen.V289.NonemptyDict
import Evergreen.V289.OneToOne
import Evergreen.V289.Pagination
import Evergreen.V289.Postmark
import Evergreen.V289.SecretId
import Evergreen.V289.SessionIdHash
import Evergreen.V289.Slack
import Evergreen.V289.TextEditor
import Evergreen.V289.Thread
import Evergreen.V289.ToBackendLog
import Evergreen.V289.User
import Evergreen.V289.UserSession
import Evergreen.V289.VisibleMessages
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
        Evergreen.V289.NonemptyDict.NonemptyDict
            (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V289.Message.Message Evergreen.V289.Id.ChannelMessageId (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V289.Discord.PartialUser
        , icon : Maybe Evergreen.V289.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V289.Discord.User
        , linkedTo : Evergreen.V289.Id.Id Evergreen.V289.Id.UserId
        , icon : Maybe Evergreen.V289.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V289.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V289.Discord.User
        , linkedTo : Evergreen.V289.Id.Id Evergreen.V289.Id.UserId
        , icon : Maybe Evergreen.V289.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V289.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V289.Message.Message Evergreen.V289.Id.ChannelMessageId (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V289.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V289.MembersAndOwner.MembersAndOwner
            (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V289.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V289.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V289.Id.Id Evergreen.V289.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V289.GuildName.GuildName
    , owner : Evergreen.V289.Id.Id Evergreen.V289.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V289.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V289.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V289.Call.CallId
    | ConnectedToCall
        Evergreen.V289.Call.CallId
        { sessionId : Evergreen.V289.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V289.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V289.Call.RemoteCallData
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V289.Id.Id Evergreen.V289.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V289.Id.Id Evergreen.V289.Id.UserId
    , name : Evergreen.V289.ChannelName.ChannelName
    , description : Evergreen.V289.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V289.Message.MessageState Evergreen.V289.Id.ChannelMessageId (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId))
    , visibleMessages : Evergreen.V289.VisibleMessages.VisibleMessages Evergreen.V289.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) (Evergreen.V289.Thread.LastTypedAt Evergreen.V289.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) Evergreen.V289.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V289.Drawing.Drawing (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId))
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V289.Id.Id Evergreen.V289.Id.UserId
    , name : Evergreen.V289.GuildName.GuildName
    , icon : Maybe Evergreen.V289.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V289.MembersAndOwner.MembersAndOwner
            (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V289.SecretId.SecretId Evergreen.V289.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V289.Id.Id Evergreen.V289.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V289.ChannelName.ChannelName
    , description : Evergreen.V289.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V289.Message.MessageState Evergreen.V289.Id.ChannelMessageId (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId))
    , visibleMessages : Evergreen.V289.VisibleMessages.VisibleMessages Evergreen.V289.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Evergreen.V289.Thread.LastTypedAt Evergreen.V289.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) Evergreen.V289.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V289.Drawing.Drawing (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V289.GuildName.GuildName
    , icon : Maybe Evergreen.V289.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V289.MembersAndOwner.MembersAndOwner
            (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V289.Id.Id Evergreen.V289.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V289.Id.Id Evergreen.V289.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V289.NonemptyDict.NonemptyDict (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) Evergreen.V289.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V289.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V289.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V289.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V289.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V289.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V289.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V289.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V289.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V289.SessionIdHash.SessionIdHash (Evergreen.V289.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V289.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V289.SessionIdHash.SessionIdHash Evergreen.V289.UserSession.UserSession
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) Evergreen.V289.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId) Evergreen.V289.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V289.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V289.SessionIdHash.SessionIdHash Evergreen.V289.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V289.TextEditor.LocalState
    , calls : Evergreen.V289.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V289.Id.Id Evergreen.V289.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V289.Id.Id Evergreen.V289.Id.UserId
    , name : Evergreen.V289.ChannelName.ChannelName
    , description : Evergreen.V289.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V289.Message.Message Evergreen.V289.Id.ChannelMessageId (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) (Evergreen.V289.Thread.LastTypedAt Evergreen.V289.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) Evergreen.V289.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V289.Drawing.Drawing (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId))
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V289.Id.Id Evergreen.V289.Id.UserId
    , name : Evergreen.V289.GuildName.GuildName
    , icon : Maybe Evergreen.V289.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V289.MembersAndOwner.MembersAndOwner
            (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V289.SecretId.SecretId Evergreen.V289.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V289.Id.Id Evergreen.V289.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V289.ChannelName.ChannelName
    , description : Evergreen.V289.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V289.Message.Message Evergreen.V289.Id.ChannelMessageId (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Evergreen.V289.Thread.LastTypedAt Evergreen.V289.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V289.OneToOne.OneToOne (Evergreen.V289.Discord.Id Evergreen.V289.Discord.MessageId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) Evergreen.V289.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V289.Drawing.Drawing (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V289.GuildName.GuildName
    , icon : Maybe Evergreen.V289.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V289.MembersAndOwner.MembersAndOwner
            (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V289.Id.Id Evergreen.V289.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V289.Id.Id Evergreen.V289.Id.CustomEmojiId)
    }
