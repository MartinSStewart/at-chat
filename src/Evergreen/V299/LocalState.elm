module Evergreen.V299.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V299.Call
import Evergreen.V299.ChannelDescription
import Evergreen.V299.ChannelName
import Evergreen.V299.Cloudflare
import Evergreen.V299.Discord
import Evergreen.V299.DiscordUserData
import Evergreen.V299.DmChannel
import Evergreen.V299.Drawing
import Evergreen.V299.FileStatus
import Evergreen.V299.GuildName
import Evergreen.V299.Id
import Evergreen.V299.IdArray
import Evergreen.V299.Log
import Evergreen.V299.MembersAndOwner
import Evergreen.V299.Message
import Evergreen.V299.NonemptyDict
import Evergreen.V299.OneToOne
import Evergreen.V299.Pagination
import Evergreen.V299.Postmark
import Evergreen.V299.SecretId
import Evergreen.V299.SessionIdHash
import Evergreen.V299.Slack
import Evergreen.V299.TextEditor
import Evergreen.V299.Thread
import Evergreen.V299.ToBackendLog
import Evergreen.V299.User
import Evergreen.V299.UserSession
import Evergreen.V299.VisibleMessages
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
        Evergreen.V299.NonemptyDict.NonemptyDict
            (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V299.Message.Message Evergreen.V299.Id.ChannelMessageId (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V299.Discord.PartialUser
        , icon : Maybe Evergreen.V299.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V299.Discord.User
        , linkedTo : Evergreen.V299.Id.Id Evergreen.V299.Id.UserId
        , icon : Maybe Evergreen.V299.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V299.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V299.Discord.User
        , linkedTo : Evergreen.V299.Id.Id Evergreen.V299.Id.UserId
        , icon : Maybe Evergreen.V299.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V299.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V299.Message.Message Evergreen.V299.Id.ChannelMessageId (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V299.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V299.MembersAndOwner.MembersAndOwner
            (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V299.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V299.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V299.Id.Id Evergreen.V299.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V299.GuildName.GuildName
    , owner : Evergreen.V299.Id.Id Evergreen.V299.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V299.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V299.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V299.Call.CallId
    | ConnectedToCall
        Evergreen.V299.Call.CallId
        { sessionId : Evergreen.V299.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V299.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V299.Call.RemoteCallData
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V299.Id.Id Evergreen.V299.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V299.Id.Id Evergreen.V299.Id.UserId
    , name : Evergreen.V299.ChannelName.ChannelName
    , description : Evergreen.V299.ChannelDescription.ChannelDescription
    , messages : Evergreen.V299.IdArray.IdArray Evergreen.V299.Id.ChannelMessageId (Evergreen.V299.Message.MessageState Evergreen.V299.Id.ChannelMessageId (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId))
    , visibleMessages : Evergreen.V299.VisibleMessages.VisibleMessages Evergreen.V299.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) (Evergreen.V299.Thread.LastTypedAt Evergreen.V299.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) Evergreen.V299.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V299.Drawing.Drawing (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId))
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V299.Id.Id Evergreen.V299.Id.UserId
    , name : Evergreen.V299.GuildName.GuildName
    , icon : Maybe Evergreen.V299.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V299.MembersAndOwner.MembersAndOwner
            (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V299.SecretId.SecretId Evergreen.V299.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V299.Id.Id Evergreen.V299.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V299.ChannelName.ChannelName
    , description : Evergreen.V299.ChannelDescription.ChannelDescription
    , messages : Evergreen.V299.IdArray.IdArray Evergreen.V299.Id.ChannelMessageId (Evergreen.V299.Message.MessageState Evergreen.V299.Id.ChannelMessageId (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId))
    , visibleMessages : Evergreen.V299.VisibleMessages.VisibleMessages Evergreen.V299.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Evergreen.V299.Thread.LastTypedAt Evergreen.V299.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) Evergreen.V299.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V299.Drawing.Drawing (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V299.GuildName.GuildName
    , icon : Maybe Evergreen.V299.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V299.MembersAndOwner.MembersAndOwner
            (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V299.Id.Id Evergreen.V299.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V299.Id.Id Evergreen.V299.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V299.NonemptyDict.NonemptyDict (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) Evergreen.V299.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V299.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V299.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V299.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V299.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V299.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V299.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V299.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V299.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V299.SessionIdHash.SessionIdHash (Evergreen.V299.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V299.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V299.SessionIdHash.SessionIdHash Evergreen.V299.UserSession.UserSession
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) Evergreen.V299.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId) Evergreen.V299.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V299.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V299.SessionIdHash.SessionIdHash Evergreen.V299.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V299.TextEditor.LocalState
    , calls : Evergreen.V299.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V299.Id.Id Evergreen.V299.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V299.Id.Id Evergreen.V299.Id.UserId
    , name : Evergreen.V299.ChannelName.ChannelName
    , description : Evergreen.V299.ChannelDescription.ChannelDescription
    , messages : Evergreen.V299.IdArray.IdArray Evergreen.V299.Id.ChannelMessageId (Evergreen.V299.Message.Message Evergreen.V299.Id.ChannelMessageId (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) (Evergreen.V299.Thread.LastTypedAt Evergreen.V299.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) Evergreen.V299.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V299.Drawing.Drawing (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId))
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V299.Id.Id Evergreen.V299.Id.UserId
    , name : Evergreen.V299.GuildName.GuildName
    , icon : Maybe Evergreen.V299.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V299.MembersAndOwner.MembersAndOwner
            (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V299.SecretId.SecretId Evergreen.V299.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V299.Id.Id Evergreen.V299.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V299.ChannelName.ChannelName
    , description : Evergreen.V299.ChannelDescription.ChannelDescription
    , messages : Evergreen.V299.IdArray.IdArray Evergreen.V299.Id.ChannelMessageId (Evergreen.V299.Message.Message Evergreen.V299.Id.ChannelMessageId (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Evergreen.V299.Thread.LastTypedAt Evergreen.V299.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V299.OneToOne.OneToOne (Evergreen.V299.Discord.Id Evergreen.V299.Discord.MessageId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) Evergreen.V299.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V299.Drawing.Drawing (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V299.GuildName.GuildName
    , icon : Maybe Evergreen.V299.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V299.MembersAndOwner.MembersAndOwner
            (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V299.Id.Id Evergreen.V299.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V299.Id.Id Evergreen.V299.Id.CustomEmojiId)
    }
