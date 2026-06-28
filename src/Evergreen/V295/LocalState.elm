module Evergreen.V295.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V295.Call
import Evergreen.V295.ChannelDescription
import Evergreen.V295.ChannelName
import Evergreen.V295.Cloudflare
import Evergreen.V295.Discord
import Evergreen.V295.DiscordUserData
import Evergreen.V295.DmChannel
import Evergreen.V295.Drawing
import Evergreen.V295.FileStatus
import Evergreen.V295.GuildName
import Evergreen.V295.Id
import Evergreen.V295.IdArray
import Evergreen.V295.Log
import Evergreen.V295.MembersAndOwner
import Evergreen.V295.Message
import Evergreen.V295.NonemptyDict
import Evergreen.V295.OneToOne
import Evergreen.V295.Pagination
import Evergreen.V295.Postmark
import Evergreen.V295.SecretId
import Evergreen.V295.SessionIdHash
import Evergreen.V295.Slack
import Evergreen.V295.TextEditor
import Evergreen.V295.Thread
import Evergreen.V295.ToBackendLog
import Evergreen.V295.User
import Evergreen.V295.UserSession
import Evergreen.V295.VisibleMessages
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
        Evergreen.V295.NonemptyDict.NonemptyDict
            (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V295.Message.Message Evergreen.V295.Id.ChannelMessageId (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V295.Discord.PartialUser
        , icon : Maybe Evergreen.V295.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V295.Discord.User
        , linkedTo : Evergreen.V295.Id.Id Evergreen.V295.Id.UserId
        , icon : Maybe Evergreen.V295.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V295.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V295.Discord.User
        , linkedTo : Evergreen.V295.Id.Id Evergreen.V295.Id.UserId
        , icon : Maybe Evergreen.V295.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V295.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V295.Message.Message Evergreen.V295.Id.ChannelMessageId (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V295.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V295.MembersAndOwner.MembersAndOwner
            (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V295.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V295.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V295.Id.Id Evergreen.V295.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V295.GuildName.GuildName
    , owner : Evergreen.V295.Id.Id Evergreen.V295.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V295.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V295.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V295.Call.CallId
    | ConnectedToCall
        Evergreen.V295.Call.CallId
        { sessionId : Evergreen.V295.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V295.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V295.Call.RemoteCallData
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V295.Id.Id Evergreen.V295.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V295.Id.Id Evergreen.V295.Id.UserId
    , name : Evergreen.V295.ChannelName.ChannelName
    , description : Evergreen.V295.ChannelDescription.ChannelDescription
    , messages : Evergreen.V295.IdArray.IdArray Evergreen.V295.Id.ChannelMessageId (Evergreen.V295.Message.MessageState Evergreen.V295.Id.ChannelMessageId (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId))
    , visibleMessages : Evergreen.V295.VisibleMessages.VisibleMessages Evergreen.V295.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) (Evergreen.V295.Thread.LastTypedAt Evergreen.V295.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) Evergreen.V295.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V295.Drawing.Drawing (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId))
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V295.Id.Id Evergreen.V295.Id.UserId
    , name : Evergreen.V295.GuildName.GuildName
    , icon : Maybe Evergreen.V295.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V295.MembersAndOwner.MembersAndOwner
            (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V295.SecretId.SecretId Evergreen.V295.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V295.Id.Id Evergreen.V295.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V295.ChannelName.ChannelName
    , description : Evergreen.V295.ChannelDescription.ChannelDescription
    , messages : Evergreen.V295.IdArray.IdArray Evergreen.V295.Id.ChannelMessageId (Evergreen.V295.Message.MessageState Evergreen.V295.Id.ChannelMessageId (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId))
    , visibleMessages : Evergreen.V295.VisibleMessages.VisibleMessages Evergreen.V295.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Evergreen.V295.Thread.LastTypedAt Evergreen.V295.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) Evergreen.V295.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V295.Drawing.Drawing (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V295.GuildName.GuildName
    , icon : Maybe Evergreen.V295.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V295.MembersAndOwner.MembersAndOwner
            (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V295.Id.Id Evergreen.V295.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V295.Id.Id Evergreen.V295.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V295.NonemptyDict.NonemptyDict (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) Evergreen.V295.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V295.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V295.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V295.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V295.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V295.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V295.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V295.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V295.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V295.SessionIdHash.SessionIdHash (Evergreen.V295.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V295.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V295.SessionIdHash.SessionIdHash Evergreen.V295.UserSession.UserSession
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) Evergreen.V295.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId) Evergreen.V295.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V295.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V295.SessionIdHash.SessionIdHash Evergreen.V295.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V295.TextEditor.LocalState
    , calls : Evergreen.V295.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V295.Id.Id Evergreen.V295.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V295.Id.Id Evergreen.V295.Id.UserId
    , name : Evergreen.V295.ChannelName.ChannelName
    , description : Evergreen.V295.ChannelDescription.ChannelDescription
    , messages : Evergreen.V295.IdArray.IdArray Evergreen.V295.Id.ChannelMessageId (Evergreen.V295.Message.Message Evergreen.V295.Id.ChannelMessageId (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) (Evergreen.V295.Thread.LastTypedAt Evergreen.V295.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) Evergreen.V295.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V295.Drawing.Drawing (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId))
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V295.Id.Id Evergreen.V295.Id.UserId
    , name : Evergreen.V295.GuildName.GuildName
    , icon : Maybe Evergreen.V295.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V295.MembersAndOwner.MembersAndOwner
            (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V295.SecretId.SecretId Evergreen.V295.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V295.Id.Id Evergreen.V295.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V295.ChannelName.ChannelName
    , description : Evergreen.V295.ChannelDescription.ChannelDescription
    , messages : Evergreen.V295.IdArray.IdArray Evergreen.V295.Id.ChannelMessageId (Evergreen.V295.Message.Message Evergreen.V295.Id.ChannelMessageId (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Evergreen.V295.Thread.LastTypedAt Evergreen.V295.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V295.OneToOne.OneToOne (Evergreen.V295.Discord.Id Evergreen.V295.Discord.MessageId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) Evergreen.V295.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V295.Drawing.Drawing (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V295.GuildName.GuildName
    , icon : Maybe Evergreen.V295.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V295.MembersAndOwner.MembersAndOwner
            (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V295.Id.Id Evergreen.V295.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V295.Id.Id Evergreen.V295.Id.CustomEmojiId)
    }
