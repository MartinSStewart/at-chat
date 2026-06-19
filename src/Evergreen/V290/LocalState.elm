module Evergreen.V290.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V290.Call
import Evergreen.V290.ChannelDescription
import Evergreen.V290.ChannelName
import Evergreen.V290.Cloudflare
import Evergreen.V290.Discord
import Evergreen.V290.DiscordUserData
import Evergreen.V290.DmChannel
import Evergreen.V290.Drawing
import Evergreen.V290.FileStatus
import Evergreen.V290.GuildName
import Evergreen.V290.Id
import Evergreen.V290.Log
import Evergreen.V290.MembersAndOwner
import Evergreen.V290.Message
import Evergreen.V290.NonemptyDict
import Evergreen.V290.OneToOne
import Evergreen.V290.Pagination
import Evergreen.V290.Postmark
import Evergreen.V290.SecretId
import Evergreen.V290.SessionIdHash
import Evergreen.V290.Slack
import Evergreen.V290.TextEditor
import Evergreen.V290.Thread
import Evergreen.V290.ToBackendLog
import Evergreen.V290.User
import Evergreen.V290.UserSession
import Evergreen.V290.VisibleMessages
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
        Evergreen.V290.NonemptyDict.NonemptyDict
            (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V290.Message.Message Evergreen.V290.Id.ChannelMessageId (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V290.Discord.PartialUser
        , icon : Maybe Evergreen.V290.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V290.Discord.User
        , linkedTo : Evergreen.V290.Id.Id Evergreen.V290.Id.UserId
        , icon : Maybe Evergreen.V290.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V290.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V290.Discord.User
        , linkedTo : Evergreen.V290.Id.Id Evergreen.V290.Id.UserId
        , icon : Maybe Evergreen.V290.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V290.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V290.Message.Message Evergreen.V290.Id.ChannelMessageId (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V290.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V290.MembersAndOwner.MembersAndOwner
            (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V290.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V290.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V290.Id.Id Evergreen.V290.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V290.GuildName.GuildName
    , owner : Evergreen.V290.Id.Id Evergreen.V290.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V290.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V290.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V290.Call.CallId
    | ConnectedToCall
        Evergreen.V290.Call.CallId
        { sessionId : Evergreen.V290.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V290.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V290.Call.RemoteCallData
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V290.Id.Id Evergreen.V290.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V290.Id.Id Evergreen.V290.Id.UserId
    , name : Evergreen.V290.ChannelName.ChannelName
    , description : Evergreen.V290.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V290.Message.MessageState Evergreen.V290.Id.ChannelMessageId (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId))
    , visibleMessages : Evergreen.V290.VisibleMessages.VisibleMessages Evergreen.V290.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) (Evergreen.V290.Thread.LastTypedAt Evergreen.V290.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) Evergreen.V290.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V290.Drawing.Drawing (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId))
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V290.Id.Id Evergreen.V290.Id.UserId
    , name : Evergreen.V290.GuildName.GuildName
    , icon : Maybe Evergreen.V290.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V290.MembersAndOwner.MembersAndOwner
            (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V290.SecretId.SecretId Evergreen.V290.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V290.Id.Id Evergreen.V290.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V290.ChannelName.ChannelName
    , description : Evergreen.V290.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V290.Message.MessageState Evergreen.V290.Id.ChannelMessageId (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId))
    , visibleMessages : Evergreen.V290.VisibleMessages.VisibleMessages Evergreen.V290.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Evergreen.V290.Thread.LastTypedAt Evergreen.V290.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) Evergreen.V290.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V290.Drawing.Drawing (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V290.GuildName.GuildName
    , icon : Maybe Evergreen.V290.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V290.MembersAndOwner.MembersAndOwner
            (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V290.Id.Id Evergreen.V290.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V290.Id.Id Evergreen.V290.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V290.NonemptyDict.NonemptyDict (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) Evergreen.V290.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V290.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V290.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V290.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V290.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V290.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V290.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V290.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V290.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V290.SessionIdHash.SessionIdHash (Evergreen.V290.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V290.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V290.SessionIdHash.SessionIdHash Evergreen.V290.UserSession.UserSession
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) Evergreen.V290.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId) Evergreen.V290.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V290.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V290.SessionIdHash.SessionIdHash Evergreen.V290.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V290.TextEditor.LocalState
    , calls : Evergreen.V290.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V290.Id.Id Evergreen.V290.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V290.Id.Id Evergreen.V290.Id.UserId
    , name : Evergreen.V290.ChannelName.ChannelName
    , description : Evergreen.V290.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V290.Message.Message Evergreen.V290.Id.ChannelMessageId (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) (Evergreen.V290.Thread.LastTypedAt Evergreen.V290.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) Evergreen.V290.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V290.Drawing.Drawing (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId))
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V290.Id.Id Evergreen.V290.Id.UserId
    , name : Evergreen.V290.GuildName.GuildName
    , icon : Maybe Evergreen.V290.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V290.MembersAndOwner.MembersAndOwner
            (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V290.SecretId.SecretId Evergreen.V290.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V290.Id.Id Evergreen.V290.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V290.ChannelName.ChannelName
    , description : Evergreen.V290.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V290.Message.Message Evergreen.V290.Id.ChannelMessageId (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Evergreen.V290.Thread.LastTypedAt Evergreen.V290.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V290.OneToOne.OneToOne (Evergreen.V290.Discord.Id Evergreen.V290.Discord.MessageId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) Evergreen.V290.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V290.Drawing.Drawing (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V290.GuildName.GuildName
    , icon : Maybe Evergreen.V290.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V290.MembersAndOwner.MembersAndOwner
            (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V290.Id.Id Evergreen.V290.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V290.Id.Id Evergreen.V290.Id.CustomEmojiId)
    }
