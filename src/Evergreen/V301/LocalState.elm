module Evergreen.V301.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V301.Call
import Evergreen.V301.ChannelDescription
import Evergreen.V301.ChannelName
import Evergreen.V301.Cloudflare
import Evergreen.V301.Discord
import Evergreen.V301.DiscordUserData
import Evergreen.V301.DmChannel
import Evergreen.V301.Drawing
import Evergreen.V301.FileStatus
import Evergreen.V301.GuildName
import Evergreen.V301.Id
import Evergreen.V301.IdArray
import Evergreen.V301.Log
import Evergreen.V301.MembersAndOwner
import Evergreen.V301.Message
import Evergreen.V301.NonemptyDict
import Evergreen.V301.OneToOne
import Evergreen.V301.Pagination
import Evergreen.V301.Postmark
import Evergreen.V301.SecretId
import Evergreen.V301.SessionIdHash
import Evergreen.V301.Slack
import Evergreen.V301.TextEditor
import Evergreen.V301.Thread
import Evergreen.V301.ToBackendLog
import Evergreen.V301.User
import Evergreen.V301.UserSession
import Evergreen.V301.VisibleMessages
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
        Evergreen.V301.NonemptyDict.NonemptyDict
            (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V301.Message.Message Evergreen.V301.Id.ChannelMessageId (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V301.Discord.PartialUser
        , icon : Maybe Evergreen.V301.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V301.Discord.User
        , linkedTo : Evergreen.V301.Id.Id Evergreen.V301.Id.UserId
        , icon : Maybe Evergreen.V301.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V301.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V301.Discord.User
        , linkedTo : Evergreen.V301.Id.Id Evergreen.V301.Id.UserId
        , icon : Maybe Evergreen.V301.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V301.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V301.Message.Message Evergreen.V301.Id.ChannelMessageId (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V301.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V301.MembersAndOwner.MembersAndOwner
            (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V301.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V301.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V301.Id.Id Evergreen.V301.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V301.GuildName.GuildName
    , owner : Evergreen.V301.Id.Id Evergreen.V301.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V301.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V301.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V301.Call.CallId
    | ConnectedToCall
        Evergreen.V301.Call.CallId
        { sessionId : Evergreen.V301.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V301.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V301.Call.RemoteCallData
    , currentlyViewing : Maybe ( Evergreen.V301.Id.AnyGuildOrDmId, Evergreen.V301.Id.ThreadRoute )
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V301.Id.Id Evergreen.V301.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V301.Id.Id Evergreen.V301.Id.UserId
    , name : Evergreen.V301.ChannelName.ChannelName
    , description : Evergreen.V301.ChannelDescription.ChannelDescription
    , messages : Evergreen.V301.IdArray.IdArray Evergreen.V301.Id.ChannelMessageId (Evergreen.V301.Message.MessageState Evergreen.V301.Id.ChannelMessageId (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId))
    , visibleMessages : Evergreen.V301.VisibleMessages.VisibleMessages Evergreen.V301.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) (Evergreen.V301.Thread.LastTypedAt Evergreen.V301.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) Evergreen.V301.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V301.Drawing.Drawing (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId))
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V301.Id.Id Evergreen.V301.Id.UserId
    , name : Evergreen.V301.GuildName.GuildName
    , icon : Maybe Evergreen.V301.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V301.MembersAndOwner.MembersAndOwner
            (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V301.SecretId.SecretId Evergreen.V301.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V301.Id.Id Evergreen.V301.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V301.ChannelName.ChannelName
    , description : Evergreen.V301.ChannelDescription.ChannelDescription
    , messages : Evergreen.V301.IdArray.IdArray Evergreen.V301.Id.ChannelMessageId (Evergreen.V301.Message.MessageState Evergreen.V301.Id.ChannelMessageId (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId))
    , visibleMessages : Evergreen.V301.VisibleMessages.VisibleMessages Evergreen.V301.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Evergreen.V301.Thread.LastTypedAt Evergreen.V301.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) Evergreen.V301.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V301.Drawing.Drawing (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V301.GuildName.GuildName
    , icon : Maybe Evergreen.V301.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V301.MembersAndOwner.MembersAndOwner
            (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V301.Id.Id Evergreen.V301.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V301.Id.Id Evergreen.V301.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V301.NonemptyDict.NonemptyDict (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) Evergreen.V301.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V301.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V301.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V301.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V301.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V301.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V301.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V301.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V301.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V301.SessionIdHash.SessionIdHash (Evergreen.V301.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V301.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V301.SessionIdHash.SessionIdHash Evergreen.V301.UserSession.UserSession
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) Evergreen.V301.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId) Evergreen.V301.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V301.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V301.SessionIdHash.SessionIdHash Evergreen.V301.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V301.TextEditor.LocalState
    , calls : Evergreen.V301.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V301.Id.Id Evergreen.V301.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V301.Id.Id Evergreen.V301.Id.UserId
    , name : Evergreen.V301.ChannelName.ChannelName
    , description : Evergreen.V301.ChannelDescription.ChannelDescription
    , messages : Evergreen.V301.IdArray.IdArray Evergreen.V301.Id.ChannelMessageId (Evergreen.V301.Message.Message Evergreen.V301.Id.ChannelMessageId (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) (Evergreen.V301.Thread.LastTypedAt Evergreen.V301.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) Evergreen.V301.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V301.Drawing.Drawing (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId))
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V301.Id.Id Evergreen.V301.Id.UserId
    , name : Evergreen.V301.GuildName.GuildName
    , icon : Maybe Evergreen.V301.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V301.MembersAndOwner.MembersAndOwner
            (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V301.SecretId.SecretId Evergreen.V301.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V301.Id.Id Evergreen.V301.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V301.ChannelName.ChannelName
    , description : Evergreen.V301.ChannelDescription.ChannelDescription
    , messages : Evergreen.V301.IdArray.IdArray Evergreen.V301.Id.ChannelMessageId (Evergreen.V301.Message.Message Evergreen.V301.Id.ChannelMessageId (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Evergreen.V301.Thread.LastTypedAt Evergreen.V301.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V301.OneToOne.OneToOne (Evergreen.V301.Discord.Id Evergreen.V301.Discord.MessageId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) Evergreen.V301.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V301.Drawing.Drawing (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V301.GuildName.GuildName
    , icon : Maybe Evergreen.V301.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V301.MembersAndOwner.MembersAndOwner
            (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V301.Id.Id Evergreen.V301.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V301.Id.Id Evergreen.V301.Id.CustomEmojiId)
    }
