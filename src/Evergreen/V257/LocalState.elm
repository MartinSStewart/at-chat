module Evergreen.V257.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V257.Call
import Evergreen.V257.ChannelDescription
import Evergreen.V257.ChannelName
import Evergreen.V257.Cloudflare
import Evergreen.V257.Discord
import Evergreen.V257.DiscordUserData
import Evergreen.V257.DmChannel
import Evergreen.V257.FileStatus
import Evergreen.V257.GuildName
import Evergreen.V257.Id
import Evergreen.V257.Log
import Evergreen.V257.MembersAndOwner
import Evergreen.V257.Message
import Evergreen.V257.NonemptyDict
import Evergreen.V257.OneToOne
import Evergreen.V257.Pagination
import Evergreen.V257.Postmark
import Evergreen.V257.SecretId
import Evergreen.V257.SessionIdHash
import Evergreen.V257.Slack
import Evergreen.V257.TextEditor
import Evergreen.V257.Thread
import Evergreen.V257.ToBackendLog
import Evergreen.V257.User
import Evergreen.V257.UserSession
import Evergreen.V257.VisibleMessages
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
        Evergreen.V257.NonemptyDict.NonemptyDict
            (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V257.Message.Message Evergreen.V257.Id.ChannelMessageId (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V257.Discord.PartialUser
        , icon : Maybe Evergreen.V257.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V257.Discord.User
        , linkedTo : Evergreen.V257.Id.Id Evergreen.V257.Id.UserId
        , icon : Maybe Evergreen.V257.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V257.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V257.Discord.User
        , linkedTo : Evergreen.V257.Id.Id Evergreen.V257.Id.UserId
        , icon : Maybe Evergreen.V257.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V257.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V257.Message.Message Evergreen.V257.Id.ChannelMessageId (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V257.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V257.MembersAndOwner.MembersAndOwner
            (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V257.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V257.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V257.Id.Id Evergreen.V257.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V257.GuildName.GuildName
    , owner : Evergreen.V257.Id.Id Evergreen.V257.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V257.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V257.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V257.Call.CallId
    | ConnectedToCall
        Evergreen.V257.Call.CallId
        { sessionId : Evergreen.V257.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V257.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V257.Id.Id Evergreen.V257.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V257.Id.Id Evergreen.V257.Id.UserId
    , name : Evergreen.V257.ChannelName.ChannelName
    , description : Evergreen.V257.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V257.Message.MessageState Evergreen.V257.Id.ChannelMessageId (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId))
    , visibleMessages : Evergreen.V257.VisibleMessages.VisibleMessages Evergreen.V257.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) (Evergreen.V257.Thread.LastTypedAt Evergreen.V257.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) Evergreen.V257.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V257.Id.Id Evergreen.V257.Id.UserId
    , name : Evergreen.V257.GuildName.GuildName
    , icon : Maybe Evergreen.V257.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V257.MembersAndOwner.MembersAndOwner
            (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V257.SecretId.SecretId Evergreen.V257.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V257.Id.Id Evergreen.V257.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V257.ChannelName.ChannelName
    , description : Evergreen.V257.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V257.Message.MessageState Evergreen.V257.Id.ChannelMessageId (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId))
    , visibleMessages : Evergreen.V257.VisibleMessages.VisibleMessages Evergreen.V257.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Evergreen.V257.Thread.LastTypedAt Evergreen.V257.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) Evergreen.V257.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V257.GuildName.GuildName
    , icon : Maybe Evergreen.V257.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V257.MembersAndOwner.MembersAndOwner
            (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V257.Id.Id Evergreen.V257.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V257.Id.Id Evergreen.V257.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V257.NonemptyDict.NonemptyDict (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) Evergreen.V257.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V257.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V257.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V257.Cloudflare.AppId
    , postmarkKey : Evergreen.V257.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V257.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V257.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V257.SessionIdHash.SessionIdHash (Evergreen.V257.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V257.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) Evergreen.V257.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId) Evergreen.V257.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V257.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V257.SessionIdHash.SessionIdHash Evergreen.V257.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V257.TextEditor.LocalState
    , calls : Evergreen.V257.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V257.Id.Id Evergreen.V257.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V257.Id.Id Evergreen.V257.Id.UserId
    , name : Evergreen.V257.ChannelName.ChannelName
    , description : Evergreen.V257.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V257.Message.Message Evergreen.V257.Id.ChannelMessageId (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) (Evergreen.V257.Thread.LastTypedAt Evergreen.V257.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) Evergreen.V257.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V257.Id.Id Evergreen.V257.Id.UserId
    , name : Evergreen.V257.GuildName.GuildName
    , icon : Maybe Evergreen.V257.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V257.MembersAndOwner.MembersAndOwner
            (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V257.SecretId.SecretId Evergreen.V257.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V257.Id.Id Evergreen.V257.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V257.ChannelName.ChannelName
    , description : Evergreen.V257.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V257.Message.Message Evergreen.V257.Id.ChannelMessageId (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Evergreen.V257.Thread.LastTypedAt Evergreen.V257.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V257.OneToOne.OneToOne (Evergreen.V257.Discord.Id Evergreen.V257.Discord.MessageId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) Evergreen.V257.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V257.GuildName.GuildName
    , icon : Maybe Evergreen.V257.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V257.MembersAndOwner.MembersAndOwner
            (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V257.Id.Id Evergreen.V257.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V257.Id.Id Evergreen.V257.Id.CustomEmojiId)
    }
