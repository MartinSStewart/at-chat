module Evergreen.V253.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V253.Call
import Evergreen.V253.ChannelDescription
import Evergreen.V253.ChannelName
import Evergreen.V253.Cloudflare
import Evergreen.V253.Discord
import Evergreen.V253.DiscordUserData
import Evergreen.V253.DmChannel
import Evergreen.V253.FileStatus
import Evergreen.V253.GuildName
import Evergreen.V253.Id
import Evergreen.V253.Log
import Evergreen.V253.MembersAndOwner
import Evergreen.V253.Message
import Evergreen.V253.NonemptyDict
import Evergreen.V253.OneToOne
import Evergreen.V253.Pagination
import Evergreen.V253.Postmark
import Evergreen.V253.SecretId
import Evergreen.V253.SessionIdHash
import Evergreen.V253.Slack
import Evergreen.V253.TextEditor
import Evergreen.V253.Thread
import Evergreen.V253.ToBackendLog
import Evergreen.V253.User
import Evergreen.V253.UserSession
import Evergreen.V253.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V253.NonemptyDict.NonemptyDict
            (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V253.Message.Message Evergreen.V253.Id.ChannelMessageId (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V253.Discord.PartialUser
        , icon : Maybe Evergreen.V253.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V253.Discord.User
        , linkedTo : Evergreen.V253.Id.Id Evergreen.V253.Id.UserId
        , icon : Maybe Evergreen.V253.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V253.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V253.Discord.User
        , linkedTo : Evergreen.V253.Id.Id Evergreen.V253.Id.UserId
        , icon : Maybe Evergreen.V253.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V253.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V253.Message.Message Evergreen.V253.Id.ChannelMessageId (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V253.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V253.MembersAndOwner.MembersAndOwner
            (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V253.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V253.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V253.Id.Id Evergreen.V253.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V253.GuildName.GuildName
    , owner : Evergreen.V253.Id.Id Evergreen.V253.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V253.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V253.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : Maybe Evergreen.V253.Call.RoomId
    , callSfu :
        Maybe
            { sessionId : Evergreen.V253.Cloudflare.RealtimeSessionId
            , trackNames : List Evergreen.V253.Cloudflare.TrackName
            , connected : Bool
            }
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V253.Id.Id Evergreen.V253.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V253.Id.Id Evergreen.V253.Id.UserId
    , name : Evergreen.V253.ChannelName.ChannelName
    , description : Evergreen.V253.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V253.Message.MessageState Evergreen.V253.Id.ChannelMessageId (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId))
    , visibleMessages : Evergreen.V253.VisibleMessages.VisibleMessages Evergreen.V253.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) (Evergreen.V253.Thread.LastTypedAt Evergreen.V253.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) Evergreen.V253.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V253.Id.Id Evergreen.V253.Id.UserId
    , name : Evergreen.V253.GuildName.GuildName
    , icon : Maybe Evergreen.V253.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V253.MembersAndOwner.MembersAndOwner
            (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V253.SecretId.SecretId Evergreen.V253.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V253.Id.Id Evergreen.V253.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V253.ChannelName.ChannelName
    , description : Evergreen.V253.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V253.Message.MessageState Evergreen.V253.Id.ChannelMessageId (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId))
    , visibleMessages : Evergreen.V253.VisibleMessages.VisibleMessages Evergreen.V253.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Evergreen.V253.Thread.LastTypedAt Evergreen.V253.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) Evergreen.V253.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V253.GuildName.GuildName
    , icon : Maybe Evergreen.V253.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V253.MembersAndOwner.MembersAndOwner
            (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V253.Id.Id Evergreen.V253.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V253.Id.Id Evergreen.V253.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V253.NonemptyDict.NonemptyDict (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) Evergreen.V253.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V253.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V253.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V253.Cloudflare.AppId
    , postmarkKey : Evergreen.V253.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V253.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V253.SessionIdHash.SessionIdHash (Evergreen.V253.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V253.ToBackendLog.ToBackendLogData
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
    , guilds : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) Evergreen.V253.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId) Evergreen.V253.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V253.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V253.SessionIdHash.SessionIdHash Evergreen.V253.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V253.TextEditor.LocalState
    , calls : Evergreen.V253.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V253.Id.Id Evergreen.V253.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V253.Id.Id Evergreen.V253.Id.UserId
    , name : Evergreen.V253.ChannelName.ChannelName
    , description : Evergreen.V253.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V253.Message.Message Evergreen.V253.Id.ChannelMessageId (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) (Evergreen.V253.Thread.LastTypedAt Evergreen.V253.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) Evergreen.V253.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V253.Id.Id Evergreen.V253.Id.UserId
    , name : Evergreen.V253.GuildName.GuildName
    , icon : Maybe Evergreen.V253.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V253.MembersAndOwner.MembersAndOwner
            (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V253.SecretId.SecretId Evergreen.V253.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V253.Id.Id Evergreen.V253.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V253.ChannelName.ChannelName
    , description : Evergreen.V253.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V253.Message.Message Evergreen.V253.Id.ChannelMessageId (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Evergreen.V253.Thread.LastTypedAt Evergreen.V253.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V253.OneToOne.OneToOne (Evergreen.V253.Discord.Id Evergreen.V253.Discord.MessageId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) Evergreen.V253.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V253.GuildName.GuildName
    , icon : Maybe Evergreen.V253.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V253.MembersAndOwner.MembersAndOwner
            (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V253.Id.Id Evergreen.V253.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V253.Id.Id Evergreen.V253.Id.CustomEmojiId)
    }
