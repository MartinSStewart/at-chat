module Evergreen.V296.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V296.Call
import Evergreen.V296.ChannelDescription
import Evergreen.V296.ChannelName
import Evergreen.V296.Cloudflare
import Evergreen.V296.Discord
import Evergreen.V296.DiscordUserData
import Evergreen.V296.DmChannel
import Evergreen.V296.Drawing
import Evergreen.V296.FileStatus
import Evergreen.V296.GuildName
import Evergreen.V296.Id
import Evergreen.V296.IdArray
import Evergreen.V296.Log
import Evergreen.V296.MembersAndOwner
import Evergreen.V296.Message
import Evergreen.V296.NonemptyDict
import Evergreen.V296.OneToOne
import Evergreen.V296.Pagination
import Evergreen.V296.Postmark
import Evergreen.V296.SecretId
import Evergreen.V296.SessionIdHash
import Evergreen.V296.Slack
import Evergreen.V296.TextEditor
import Evergreen.V296.Thread
import Evergreen.V296.ToBackendLog
import Evergreen.V296.User
import Evergreen.V296.UserSession
import Evergreen.V296.VisibleMessages
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
        Evergreen.V296.NonemptyDict.NonemptyDict
            (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V296.Message.Message Evergreen.V296.Id.ChannelMessageId (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V296.Discord.PartialUser
        , icon : Maybe Evergreen.V296.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V296.Discord.User
        , linkedTo : Evergreen.V296.Id.Id Evergreen.V296.Id.UserId
        , icon : Maybe Evergreen.V296.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V296.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V296.Discord.User
        , linkedTo : Evergreen.V296.Id.Id Evergreen.V296.Id.UserId
        , icon : Maybe Evergreen.V296.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V296.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V296.Message.Message Evergreen.V296.Id.ChannelMessageId (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V296.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V296.MembersAndOwner.MembersAndOwner
            (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V296.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V296.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V296.Id.Id Evergreen.V296.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V296.GuildName.GuildName
    , owner : Evergreen.V296.Id.Id Evergreen.V296.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V296.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V296.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V296.Call.CallId
    | ConnectedToCall
        Evergreen.V296.Call.CallId
        { sessionId : Evergreen.V296.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V296.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V296.Call.RemoteCallData
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V296.Id.Id Evergreen.V296.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V296.Id.Id Evergreen.V296.Id.UserId
    , name : Evergreen.V296.ChannelName.ChannelName
    , description : Evergreen.V296.ChannelDescription.ChannelDescription
    , messages : Evergreen.V296.IdArray.IdArray Evergreen.V296.Id.ChannelMessageId (Evergreen.V296.Message.MessageState Evergreen.V296.Id.ChannelMessageId (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId))
    , visibleMessages : Evergreen.V296.VisibleMessages.VisibleMessages Evergreen.V296.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) (Evergreen.V296.Thread.LastTypedAt Evergreen.V296.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) Evergreen.V296.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V296.Drawing.Drawing (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId))
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V296.Id.Id Evergreen.V296.Id.UserId
    , name : Evergreen.V296.GuildName.GuildName
    , icon : Maybe Evergreen.V296.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V296.MembersAndOwner.MembersAndOwner
            (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V296.SecretId.SecretId Evergreen.V296.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V296.Id.Id Evergreen.V296.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V296.ChannelName.ChannelName
    , description : Evergreen.V296.ChannelDescription.ChannelDescription
    , messages : Evergreen.V296.IdArray.IdArray Evergreen.V296.Id.ChannelMessageId (Evergreen.V296.Message.MessageState Evergreen.V296.Id.ChannelMessageId (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId))
    , visibleMessages : Evergreen.V296.VisibleMessages.VisibleMessages Evergreen.V296.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Evergreen.V296.Thread.LastTypedAt Evergreen.V296.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) Evergreen.V296.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V296.Drawing.Drawing (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V296.GuildName.GuildName
    , icon : Maybe Evergreen.V296.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V296.MembersAndOwner.MembersAndOwner
            (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V296.Id.Id Evergreen.V296.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V296.Id.Id Evergreen.V296.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V296.NonemptyDict.NonemptyDict (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) Evergreen.V296.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V296.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V296.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V296.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V296.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V296.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V296.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V296.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V296.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V296.SessionIdHash.SessionIdHash (Evergreen.V296.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V296.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V296.SessionIdHash.SessionIdHash Evergreen.V296.UserSession.UserSession
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) Evergreen.V296.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId) Evergreen.V296.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V296.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V296.SessionIdHash.SessionIdHash Evergreen.V296.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V296.TextEditor.LocalState
    , calls : Evergreen.V296.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V296.Id.Id Evergreen.V296.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V296.Id.Id Evergreen.V296.Id.UserId
    , name : Evergreen.V296.ChannelName.ChannelName
    , description : Evergreen.V296.ChannelDescription.ChannelDescription
    , messages : Evergreen.V296.IdArray.IdArray Evergreen.V296.Id.ChannelMessageId (Evergreen.V296.Message.Message Evergreen.V296.Id.ChannelMessageId (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) (Evergreen.V296.Thread.LastTypedAt Evergreen.V296.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) Evergreen.V296.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V296.Drawing.Drawing (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId))
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V296.Id.Id Evergreen.V296.Id.UserId
    , name : Evergreen.V296.GuildName.GuildName
    , icon : Maybe Evergreen.V296.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V296.MembersAndOwner.MembersAndOwner
            (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V296.SecretId.SecretId Evergreen.V296.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V296.Id.Id Evergreen.V296.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V296.ChannelName.ChannelName
    , description : Evergreen.V296.ChannelDescription.ChannelDescription
    , messages : Evergreen.V296.IdArray.IdArray Evergreen.V296.Id.ChannelMessageId (Evergreen.V296.Message.Message Evergreen.V296.Id.ChannelMessageId (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Evergreen.V296.Thread.LastTypedAt Evergreen.V296.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V296.OneToOne.OneToOne (Evergreen.V296.Discord.Id Evergreen.V296.Discord.MessageId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) Evergreen.V296.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V296.Drawing.Drawing (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V296.GuildName.GuildName
    , icon : Maybe Evergreen.V296.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V296.MembersAndOwner.MembersAndOwner
            (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V296.Id.Id Evergreen.V296.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V296.Id.Id Evergreen.V296.Id.CustomEmojiId)
    }
