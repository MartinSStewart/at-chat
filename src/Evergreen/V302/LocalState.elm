module Evergreen.V302.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V302.Call
import Evergreen.V302.ChannelDescription
import Evergreen.V302.ChannelName
import Evergreen.V302.Cloudflare
import Evergreen.V302.Discord
import Evergreen.V302.DiscordUserData
import Evergreen.V302.DmChannel
import Evergreen.V302.Drawing
import Evergreen.V302.FileStatus
import Evergreen.V302.GuildName
import Evergreen.V302.Id
import Evergreen.V302.IdArray
import Evergreen.V302.Log
import Evergreen.V302.MembersAndOwner
import Evergreen.V302.Message
import Evergreen.V302.NonemptyDict
import Evergreen.V302.OneToOne
import Evergreen.V302.Pagination
import Evergreen.V302.Postmark
import Evergreen.V302.SecretId
import Evergreen.V302.SessionIdHash
import Evergreen.V302.Slack
import Evergreen.V302.TextEditor
import Evergreen.V302.Thread
import Evergreen.V302.ToBackendLog
import Evergreen.V302.User
import Evergreen.V302.UserSession
import Evergreen.V302.VisibleMessages
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
        Evergreen.V302.NonemptyDict.NonemptyDict
            (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V302.Message.Message Evergreen.V302.Id.ChannelMessageId (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V302.Discord.PartialUser
        , icon : Maybe Evergreen.V302.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V302.Discord.User
        , linkedTo : Evergreen.V302.Id.Id Evergreen.V302.Id.UserId
        , icon : Maybe Evergreen.V302.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V302.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V302.Discord.User
        , linkedTo : Evergreen.V302.Id.Id Evergreen.V302.Id.UserId
        , icon : Maybe Evergreen.V302.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V302.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V302.Message.Message Evergreen.V302.Id.ChannelMessageId (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V302.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V302.MembersAndOwner.MembersAndOwner
            (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V302.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V302.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V302.Id.Id Evergreen.V302.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V302.GuildName.GuildName
    , owner : Evergreen.V302.Id.Id Evergreen.V302.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V302.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V302.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V302.Call.CallId
    | ConnectedToCall
        Evergreen.V302.Call.CallId
        { sessionId : Evergreen.V302.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V302.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V302.Call.RemoteCallData
    , currentlyViewing : Maybe ( Evergreen.V302.Id.AnyGuildOrDmId, Evergreen.V302.Id.ThreadRoute )
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V302.Id.Id Evergreen.V302.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V302.Id.Id Evergreen.V302.Id.UserId
    , name : Evergreen.V302.ChannelName.ChannelName
    , description : Evergreen.V302.ChannelDescription.ChannelDescription
    , messages : Evergreen.V302.IdArray.IdArray Evergreen.V302.Id.ChannelMessageId (Evergreen.V302.Message.MessageState Evergreen.V302.Id.ChannelMessageId (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId))
    , visibleMessages : Evergreen.V302.VisibleMessages.VisibleMessages Evergreen.V302.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) (Evergreen.V302.Thread.LastTypedAt Evergreen.V302.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) Evergreen.V302.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V302.Drawing.Drawing (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId))
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V302.Id.Id Evergreen.V302.Id.UserId
    , name : Evergreen.V302.GuildName.GuildName
    , icon : Maybe Evergreen.V302.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V302.MembersAndOwner.MembersAndOwner
            (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V302.SecretId.SecretId Evergreen.V302.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V302.Id.Id Evergreen.V302.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V302.ChannelName.ChannelName
    , description : Evergreen.V302.ChannelDescription.ChannelDescription
    , messages : Evergreen.V302.IdArray.IdArray Evergreen.V302.Id.ChannelMessageId (Evergreen.V302.Message.MessageState Evergreen.V302.Id.ChannelMessageId (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId))
    , visibleMessages : Evergreen.V302.VisibleMessages.VisibleMessages Evergreen.V302.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Evergreen.V302.Thread.LastTypedAt Evergreen.V302.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) Evergreen.V302.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V302.Drawing.Drawing (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V302.GuildName.GuildName
    , icon : Maybe Evergreen.V302.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V302.MembersAndOwner.MembersAndOwner
            (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V302.Id.Id Evergreen.V302.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V302.Id.Id Evergreen.V302.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V302.NonemptyDict.NonemptyDict (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) Evergreen.V302.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V302.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V302.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V302.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V302.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V302.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V302.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V302.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V302.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V302.SessionIdHash.SessionIdHash (Evergreen.V302.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V302.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V302.SessionIdHash.SessionIdHash Evergreen.V302.UserSession.UserSession
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) Evergreen.V302.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId) Evergreen.V302.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V302.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V302.SessionIdHash.SessionIdHash Evergreen.V302.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V302.TextEditor.LocalState
    , calls : Evergreen.V302.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V302.Id.Id Evergreen.V302.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V302.Id.Id Evergreen.V302.Id.UserId
    , name : Evergreen.V302.ChannelName.ChannelName
    , description : Evergreen.V302.ChannelDescription.ChannelDescription
    , messages : Evergreen.V302.IdArray.IdArray Evergreen.V302.Id.ChannelMessageId (Evergreen.V302.Message.Message Evergreen.V302.Id.ChannelMessageId (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) (Evergreen.V302.Thread.LastTypedAt Evergreen.V302.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) Evergreen.V302.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V302.Drawing.Drawing (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId))
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V302.Id.Id Evergreen.V302.Id.UserId
    , name : Evergreen.V302.GuildName.GuildName
    , icon : Maybe Evergreen.V302.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V302.MembersAndOwner.MembersAndOwner
            (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V302.SecretId.SecretId Evergreen.V302.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V302.Id.Id Evergreen.V302.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V302.ChannelName.ChannelName
    , description : Evergreen.V302.ChannelDescription.ChannelDescription
    , messages : Evergreen.V302.IdArray.IdArray Evergreen.V302.Id.ChannelMessageId (Evergreen.V302.Message.Message Evergreen.V302.Id.ChannelMessageId (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Evergreen.V302.Thread.LastTypedAt Evergreen.V302.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V302.OneToOne.OneToOne (Evergreen.V302.Discord.Id Evergreen.V302.Discord.MessageId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) Evergreen.V302.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V302.Drawing.Drawing (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V302.GuildName.GuildName
    , icon : Maybe Evergreen.V302.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V302.MembersAndOwner.MembersAndOwner
            (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V302.Id.Id Evergreen.V302.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V302.Id.Id Evergreen.V302.Id.CustomEmojiId)
    }
