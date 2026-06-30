module Evergreen.V297.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V297.Call
import Evergreen.V297.ChannelDescription
import Evergreen.V297.ChannelName
import Evergreen.V297.Cloudflare
import Evergreen.V297.Discord
import Evergreen.V297.DiscordUserData
import Evergreen.V297.DmChannel
import Evergreen.V297.Drawing
import Evergreen.V297.FileStatus
import Evergreen.V297.GuildName
import Evergreen.V297.Id
import Evergreen.V297.IdArray
import Evergreen.V297.Log
import Evergreen.V297.MembersAndOwner
import Evergreen.V297.Message
import Evergreen.V297.NonemptyDict
import Evergreen.V297.OneToOne
import Evergreen.V297.Pagination
import Evergreen.V297.Postmark
import Evergreen.V297.SecretId
import Evergreen.V297.SessionIdHash
import Evergreen.V297.Slack
import Evergreen.V297.TextEditor
import Evergreen.V297.Thread
import Evergreen.V297.ToBackendLog
import Evergreen.V297.User
import Evergreen.V297.UserSession
import Evergreen.V297.VisibleMessages
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
        Evergreen.V297.NonemptyDict.NonemptyDict
            (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V297.Message.Message Evergreen.V297.Id.ChannelMessageId (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V297.Discord.PartialUser
        , icon : Maybe Evergreen.V297.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V297.Discord.User
        , linkedTo : Evergreen.V297.Id.Id Evergreen.V297.Id.UserId
        , icon : Maybe Evergreen.V297.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V297.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V297.Discord.User
        , linkedTo : Evergreen.V297.Id.Id Evergreen.V297.Id.UserId
        , icon : Maybe Evergreen.V297.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V297.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V297.Message.Message Evergreen.V297.Id.ChannelMessageId (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V297.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V297.MembersAndOwner.MembersAndOwner
            (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V297.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V297.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V297.Id.Id Evergreen.V297.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V297.GuildName.GuildName
    , owner : Evergreen.V297.Id.Id Evergreen.V297.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V297.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V297.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V297.Call.CallId
    | ConnectedToCall
        Evergreen.V297.Call.CallId
        { sessionId : Evergreen.V297.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V297.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V297.Call.RemoteCallData
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V297.Id.Id Evergreen.V297.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V297.Id.Id Evergreen.V297.Id.UserId
    , name : Evergreen.V297.ChannelName.ChannelName
    , description : Evergreen.V297.ChannelDescription.ChannelDescription
    , messages : Evergreen.V297.IdArray.IdArray Evergreen.V297.Id.ChannelMessageId (Evergreen.V297.Message.MessageState Evergreen.V297.Id.ChannelMessageId (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId))
    , visibleMessages : Evergreen.V297.VisibleMessages.VisibleMessages Evergreen.V297.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) (Evergreen.V297.Thread.LastTypedAt Evergreen.V297.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) Evergreen.V297.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V297.Drawing.Drawing (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId))
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V297.Id.Id Evergreen.V297.Id.UserId
    , name : Evergreen.V297.GuildName.GuildName
    , icon : Maybe Evergreen.V297.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V297.MembersAndOwner.MembersAndOwner
            (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V297.SecretId.SecretId Evergreen.V297.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V297.Id.Id Evergreen.V297.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V297.ChannelName.ChannelName
    , description : Evergreen.V297.ChannelDescription.ChannelDescription
    , messages : Evergreen.V297.IdArray.IdArray Evergreen.V297.Id.ChannelMessageId (Evergreen.V297.Message.MessageState Evergreen.V297.Id.ChannelMessageId (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId))
    , visibleMessages : Evergreen.V297.VisibleMessages.VisibleMessages Evergreen.V297.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Evergreen.V297.Thread.LastTypedAt Evergreen.V297.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) Evergreen.V297.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V297.Drawing.Drawing (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V297.GuildName.GuildName
    , icon : Maybe Evergreen.V297.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V297.MembersAndOwner.MembersAndOwner
            (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V297.Id.Id Evergreen.V297.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V297.Id.Id Evergreen.V297.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V297.NonemptyDict.NonemptyDict (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) Evergreen.V297.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V297.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V297.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V297.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V297.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V297.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V297.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V297.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V297.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V297.SessionIdHash.SessionIdHash (Evergreen.V297.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V297.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V297.SessionIdHash.SessionIdHash Evergreen.V297.UserSession.UserSession
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) Evergreen.V297.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId) Evergreen.V297.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V297.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V297.SessionIdHash.SessionIdHash Evergreen.V297.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V297.TextEditor.LocalState
    , calls : Evergreen.V297.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V297.Id.Id Evergreen.V297.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V297.Id.Id Evergreen.V297.Id.UserId
    , name : Evergreen.V297.ChannelName.ChannelName
    , description : Evergreen.V297.ChannelDescription.ChannelDescription
    , messages : Evergreen.V297.IdArray.IdArray Evergreen.V297.Id.ChannelMessageId (Evergreen.V297.Message.Message Evergreen.V297.Id.ChannelMessageId (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) (Evergreen.V297.Thread.LastTypedAt Evergreen.V297.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) Evergreen.V297.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V297.Drawing.Drawing (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId))
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V297.Id.Id Evergreen.V297.Id.UserId
    , name : Evergreen.V297.GuildName.GuildName
    , icon : Maybe Evergreen.V297.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V297.MembersAndOwner.MembersAndOwner
            (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V297.SecretId.SecretId Evergreen.V297.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V297.Id.Id Evergreen.V297.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V297.ChannelName.ChannelName
    , description : Evergreen.V297.ChannelDescription.ChannelDescription
    , messages : Evergreen.V297.IdArray.IdArray Evergreen.V297.Id.ChannelMessageId (Evergreen.V297.Message.Message Evergreen.V297.Id.ChannelMessageId (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Evergreen.V297.Thread.LastTypedAt Evergreen.V297.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V297.OneToOne.OneToOne (Evergreen.V297.Discord.Id Evergreen.V297.Discord.MessageId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) Evergreen.V297.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V297.Drawing.Drawing (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V297.GuildName.GuildName
    , icon : Maybe Evergreen.V297.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V297.MembersAndOwner.MembersAndOwner
            (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V297.Id.Id Evergreen.V297.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V297.Id.Id Evergreen.V297.Id.CustomEmojiId)
    }
