module Evergreen.V294.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V294.Call
import Evergreen.V294.ChannelDescription
import Evergreen.V294.ChannelName
import Evergreen.V294.Cloudflare
import Evergreen.V294.Discord
import Evergreen.V294.DiscordUserData
import Evergreen.V294.DmChannel
import Evergreen.V294.Drawing
import Evergreen.V294.FileStatus
import Evergreen.V294.GuildName
import Evergreen.V294.Id
import Evergreen.V294.Log
import Evergreen.V294.MembersAndOwner
import Evergreen.V294.Message
import Evergreen.V294.NonemptyDict
import Evergreen.V294.OneToOne
import Evergreen.V294.Pagination
import Evergreen.V294.Postmark
import Evergreen.V294.SecretId
import Evergreen.V294.SessionIdHash
import Evergreen.V294.Slack
import Evergreen.V294.TextEditor
import Evergreen.V294.Thread
import Evergreen.V294.ToBackendLog
import Evergreen.V294.User
import Evergreen.V294.UserSession
import Evergreen.V294.VisibleMessages
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
        Evergreen.V294.NonemptyDict.NonemptyDict
            (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V294.Message.Message Evergreen.V294.Id.ChannelMessageId (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V294.Discord.PartialUser
        , icon : Maybe Evergreen.V294.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V294.Discord.User
        , linkedTo : Evergreen.V294.Id.Id Evergreen.V294.Id.UserId
        , icon : Maybe Evergreen.V294.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V294.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V294.Discord.User
        , linkedTo : Evergreen.V294.Id.Id Evergreen.V294.Id.UserId
        , icon : Maybe Evergreen.V294.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V294.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V294.Message.Message Evergreen.V294.Id.ChannelMessageId (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V294.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V294.MembersAndOwner.MembersAndOwner
            (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V294.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V294.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V294.Id.Id Evergreen.V294.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V294.GuildName.GuildName
    , owner : Evergreen.V294.Id.Id Evergreen.V294.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V294.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V294.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V294.Call.CallId
    | ConnectedToCall
        Evergreen.V294.Call.CallId
        { sessionId : Evergreen.V294.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V294.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V294.Call.RemoteCallData
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V294.Id.Id Evergreen.V294.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V294.Id.Id Evergreen.V294.Id.UserId
    , name : Evergreen.V294.ChannelName.ChannelName
    , description : Evergreen.V294.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V294.Message.MessageState Evergreen.V294.Id.ChannelMessageId (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId))
    , visibleMessages : Evergreen.V294.VisibleMessages.VisibleMessages Evergreen.V294.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) (Evergreen.V294.Thread.LastTypedAt Evergreen.V294.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) Evergreen.V294.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V294.Drawing.Drawing (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId))
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V294.Id.Id Evergreen.V294.Id.UserId
    , name : Evergreen.V294.GuildName.GuildName
    , icon : Maybe Evergreen.V294.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V294.MembersAndOwner.MembersAndOwner
            (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V294.SecretId.SecretId Evergreen.V294.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V294.Id.Id Evergreen.V294.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V294.ChannelName.ChannelName
    , description : Evergreen.V294.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V294.Message.MessageState Evergreen.V294.Id.ChannelMessageId (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId))
    , visibleMessages : Evergreen.V294.VisibleMessages.VisibleMessages Evergreen.V294.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Evergreen.V294.Thread.LastTypedAt Evergreen.V294.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) Evergreen.V294.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V294.Drawing.Drawing (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V294.GuildName.GuildName
    , icon : Maybe Evergreen.V294.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V294.MembersAndOwner.MembersAndOwner
            (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V294.Id.Id Evergreen.V294.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V294.Id.Id Evergreen.V294.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V294.NonemptyDict.NonemptyDict (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) Evergreen.V294.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V294.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V294.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V294.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V294.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V294.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V294.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V294.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V294.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V294.SessionIdHash.SessionIdHash (Evergreen.V294.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V294.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V294.SessionIdHash.SessionIdHash Evergreen.V294.UserSession.UserSession
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) Evergreen.V294.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId) Evergreen.V294.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V294.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V294.SessionIdHash.SessionIdHash Evergreen.V294.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V294.TextEditor.LocalState
    , calls : Evergreen.V294.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V294.Id.Id Evergreen.V294.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V294.Id.Id Evergreen.V294.Id.UserId
    , name : Evergreen.V294.ChannelName.ChannelName
    , description : Evergreen.V294.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V294.Message.Message Evergreen.V294.Id.ChannelMessageId (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) (Evergreen.V294.Thread.LastTypedAt Evergreen.V294.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) Evergreen.V294.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V294.Drawing.Drawing (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId))
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V294.Id.Id Evergreen.V294.Id.UserId
    , name : Evergreen.V294.GuildName.GuildName
    , icon : Maybe Evergreen.V294.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V294.MembersAndOwner.MembersAndOwner
            (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V294.SecretId.SecretId Evergreen.V294.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V294.Id.Id Evergreen.V294.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V294.ChannelName.ChannelName
    , description : Evergreen.V294.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V294.Message.Message Evergreen.V294.Id.ChannelMessageId (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Evergreen.V294.Thread.LastTypedAt Evergreen.V294.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V294.OneToOne.OneToOne (Evergreen.V294.Discord.Id Evergreen.V294.Discord.MessageId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) Evergreen.V294.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V294.Drawing.Drawing (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V294.GuildName.GuildName
    , icon : Maybe Evergreen.V294.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V294.MembersAndOwner.MembersAndOwner
            (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V294.Id.Id Evergreen.V294.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V294.Id.Id Evergreen.V294.Id.CustomEmojiId)
    }
