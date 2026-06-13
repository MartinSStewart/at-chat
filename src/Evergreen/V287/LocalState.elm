module Evergreen.V287.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V287.Call
import Evergreen.V287.ChannelDescription
import Evergreen.V287.ChannelName
import Evergreen.V287.Cloudflare
import Evergreen.V287.Discord
import Evergreen.V287.DiscordUserData
import Evergreen.V287.DmChannel
import Evergreen.V287.Drawing
import Evergreen.V287.FileStatus
import Evergreen.V287.GuildName
import Evergreen.V287.Id
import Evergreen.V287.Log
import Evergreen.V287.MembersAndOwner
import Evergreen.V287.Message
import Evergreen.V287.NonemptyDict
import Evergreen.V287.OneToOne
import Evergreen.V287.Pagination
import Evergreen.V287.Postmark
import Evergreen.V287.SecretId
import Evergreen.V287.SessionIdHash
import Evergreen.V287.Slack
import Evergreen.V287.TextEditor
import Evergreen.V287.Thread
import Evergreen.V287.ToBackendLog
import Evergreen.V287.User
import Evergreen.V287.UserSession
import Evergreen.V287.VisibleMessages
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
        Evergreen.V287.NonemptyDict.NonemptyDict
            (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V287.Message.Message Evergreen.V287.Id.ChannelMessageId (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V287.Discord.PartialUser
        , icon : Maybe Evergreen.V287.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V287.Discord.User
        , linkedTo : Evergreen.V287.Id.Id Evergreen.V287.Id.UserId
        , icon : Maybe Evergreen.V287.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V287.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V287.Discord.User
        , linkedTo : Evergreen.V287.Id.Id Evergreen.V287.Id.UserId
        , icon : Maybe Evergreen.V287.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V287.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V287.Message.Message Evergreen.V287.Id.ChannelMessageId (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V287.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V287.MembersAndOwner.MembersAndOwner
            (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V287.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V287.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V287.Id.Id Evergreen.V287.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V287.GuildName.GuildName
    , owner : Evergreen.V287.Id.Id Evergreen.V287.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V287.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V287.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V287.Call.CallId
    | ConnectedToCall
        Evergreen.V287.Call.CallId
        { sessionId : Evergreen.V287.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V287.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V287.Call.RemoteCallData
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V287.Id.Id Evergreen.V287.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V287.Id.Id Evergreen.V287.Id.UserId
    , name : Evergreen.V287.ChannelName.ChannelName
    , description : Evergreen.V287.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V287.Message.MessageState Evergreen.V287.Id.ChannelMessageId (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId))
    , visibleMessages : Evergreen.V287.VisibleMessages.VisibleMessages Evergreen.V287.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) (Evergreen.V287.Thread.LastTypedAt Evergreen.V287.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) Evergreen.V287.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V287.Drawing.Drawing (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId))
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V287.Id.Id Evergreen.V287.Id.UserId
    , name : Evergreen.V287.GuildName.GuildName
    , icon : Maybe Evergreen.V287.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V287.MembersAndOwner.MembersAndOwner
            (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V287.SecretId.SecretId Evergreen.V287.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V287.Id.Id Evergreen.V287.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V287.ChannelName.ChannelName
    , description : Evergreen.V287.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V287.Message.MessageState Evergreen.V287.Id.ChannelMessageId (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId))
    , visibleMessages : Evergreen.V287.VisibleMessages.VisibleMessages Evergreen.V287.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Evergreen.V287.Thread.LastTypedAt Evergreen.V287.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) Evergreen.V287.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V287.Drawing.Drawing (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V287.GuildName.GuildName
    , icon : Maybe Evergreen.V287.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V287.MembersAndOwner.MembersAndOwner
            (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V287.Id.Id Evergreen.V287.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V287.Id.Id Evergreen.V287.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V287.NonemptyDict.NonemptyDict (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) Evergreen.V287.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V287.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V287.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V287.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V287.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V287.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V287.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V287.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V287.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V287.SessionIdHash.SessionIdHash (Evergreen.V287.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V287.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V287.SessionIdHash.SessionIdHash Evergreen.V287.UserSession.UserSession
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) Evergreen.V287.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId) Evergreen.V287.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V287.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V287.SessionIdHash.SessionIdHash Evergreen.V287.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V287.TextEditor.LocalState
    , calls : Evergreen.V287.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V287.Id.Id Evergreen.V287.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V287.Id.Id Evergreen.V287.Id.UserId
    , name : Evergreen.V287.ChannelName.ChannelName
    , description : Evergreen.V287.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V287.Message.Message Evergreen.V287.Id.ChannelMessageId (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) (Evergreen.V287.Thread.LastTypedAt Evergreen.V287.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) Evergreen.V287.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V287.Drawing.Drawing (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId))
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V287.Id.Id Evergreen.V287.Id.UserId
    , name : Evergreen.V287.GuildName.GuildName
    , icon : Maybe Evergreen.V287.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V287.MembersAndOwner.MembersAndOwner
            (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V287.SecretId.SecretId Evergreen.V287.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V287.Id.Id Evergreen.V287.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V287.ChannelName.ChannelName
    , description : Evergreen.V287.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V287.Message.Message Evergreen.V287.Id.ChannelMessageId (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Evergreen.V287.Thread.LastTypedAt Evergreen.V287.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V287.OneToOne.OneToOne (Evergreen.V287.Discord.Id Evergreen.V287.Discord.MessageId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) Evergreen.V287.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V287.Drawing.Drawing (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V287.GuildName.GuildName
    , icon : Maybe Evergreen.V287.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V287.MembersAndOwner.MembersAndOwner
            (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V287.Id.Id Evergreen.V287.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V287.Id.Id Evergreen.V287.Id.CustomEmojiId)
    }
