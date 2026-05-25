module Evergreen.V254.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V254.Call
import Evergreen.V254.ChannelDescription
import Evergreen.V254.ChannelName
import Evergreen.V254.Cloudflare
import Evergreen.V254.Discord
import Evergreen.V254.DiscordUserData
import Evergreen.V254.DmChannel
import Evergreen.V254.FileStatus
import Evergreen.V254.GuildName
import Evergreen.V254.Id
import Evergreen.V254.Log
import Evergreen.V254.MembersAndOwner
import Evergreen.V254.Message
import Evergreen.V254.NonemptyDict
import Evergreen.V254.OneToOne
import Evergreen.V254.Pagination
import Evergreen.V254.Postmark
import Evergreen.V254.SecretId
import Evergreen.V254.SessionIdHash
import Evergreen.V254.Slack
import Evergreen.V254.TextEditor
import Evergreen.V254.Thread
import Evergreen.V254.ToBackendLog
import Evergreen.V254.User
import Evergreen.V254.UserSession
import Evergreen.V254.VisibleMessages
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
        Evergreen.V254.NonemptyDict.NonemptyDict
            (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V254.Message.Message Evergreen.V254.Id.ChannelMessageId (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V254.Discord.PartialUser
        , icon : Maybe Evergreen.V254.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V254.Discord.User
        , linkedTo : Evergreen.V254.Id.Id Evergreen.V254.Id.UserId
        , icon : Maybe Evergreen.V254.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V254.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V254.Discord.User
        , linkedTo : Evergreen.V254.Id.Id Evergreen.V254.Id.UserId
        , icon : Maybe Evergreen.V254.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V254.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V254.Message.Message Evergreen.V254.Id.ChannelMessageId (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V254.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V254.Discord.Id Evergreen.V254.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V254.MembersAndOwner.MembersAndOwner
            (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V254.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V254.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V254.Id.Id Evergreen.V254.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V254.GuildName.GuildName
    , owner : Evergreen.V254.Id.Id Evergreen.V254.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V254.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V254.Discord.Id Evergreen.V254.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V254.Discord.Id Evergreen.V254.Discord.GuildId) (Evergreen.V254.Discord.Id Evergreen.V254.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V254.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : Maybe Evergreen.V254.Call.RoomId
    , callSfu :
        Maybe
            { sessionId : Evergreen.V254.Cloudflare.RealtimeSessionId
            , trackNames : List Evergreen.V254.Cloudflare.TrackName
            , connected : Bool
            }
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V254.Id.Id Evergreen.V254.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V254.Id.Id Evergreen.V254.Id.UserId
    , name : Evergreen.V254.ChannelName.ChannelName
    , description : Evergreen.V254.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V254.Message.MessageState Evergreen.V254.Id.ChannelMessageId (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId))
    , visibleMessages : Evergreen.V254.VisibleMessages.VisibleMessages Evergreen.V254.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId) (Evergreen.V254.Thread.LastTypedAt Evergreen.V254.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelMessageId) Evergreen.V254.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V254.Id.Id Evergreen.V254.Id.UserId
    , name : Evergreen.V254.GuildName.GuildName
    , icon : Maybe Evergreen.V254.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V254.MembersAndOwner.MembersAndOwner
            (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V254.SecretId.SecretId Evergreen.V254.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V254.Id.Id Evergreen.V254.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V254.ChannelName.ChannelName
    , description : Evergreen.V254.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V254.Message.MessageState Evergreen.V254.Id.ChannelMessageId (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId))
    , visibleMessages : Evergreen.V254.VisibleMessages.VisibleMessages Evergreen.V254.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId) (Evergreen.V254.Thread.LastTypedAt Evergreen.V254.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelMessageId) Evergreen.V254.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V254.GuildName.GuildName
    , icon : Maybe Evergreen.V254.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V254.Discord.Id Evergreen.V254.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V254.MembersAndOwner.MembersAndOwner
            (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V254.Id.Id Evergreen.V254.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V254.Id.Id Evergreen.V254.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V254.NonemptyDict.NonemptyDict (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId) Evergreen.V254.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V254.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V254.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V254.Cloudflare.AppId
    , postmarkKey : Evergreen.V254.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V254.DmChannel.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V254.Discord.Id Evergreen.V254.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V254.Discord.Id Evergreen.V254.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V254.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V254.SessionIdHash.SessionIdHash (Evergreen.V254.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V254.ToBackendLog.ToBackendLogData
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
    , guilds : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V254.Discord.Id Evergreen.V254.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId) Evergreen.V254.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V254.Discord.Id Evergreen.V254.Discord.PrivateChannelId) Evergreen.V254.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V254.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V254.SessionIdHash.SessionIdHash Evergreen.V254.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V254.TextEditor.LocalState
    , calls : Evergreen.V254.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V254.Id.Id Evergreen.V254.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V254.Id.Id Evergreen.V254.Id.UserId
    , name : Evergreen.V254.ChannelName.ChannelName
    , description : Evergreen.V254.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V254.Message.Message Evergreen.V254.Id.ChannelMessageId (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId) (Evergreen.V254.Thread.LastTypedAt Evergreen.V254.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelMessageId) Evergreen.V254.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V254.Id.Id Evergreen.V254.Id.UserId
    , name : Evergreen.V254.GuildName.GuildName
    , icon : Maybe Evergreen.V254.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V254.MembersAndOwner.MembersAndOwner
            (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V254.SecretId.SecretId Evergreen.V254.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V254.Id.Id Evergreen.V254.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V254.ChannelName.ChannelName
    , description : Evergreen.V254.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V254.Message.Message Evergreen.V254.Id.ChannelMessageId (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId) (Evergreen.V254.Thread.LastTypedAt Evergreen.V254.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V254.OneToOne.OneToOne (Evergreen.V254.Discord.Id Evergreen.V254.Discord.MessageId) (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelMessageId) Evergreen.V254.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V254.GuildName.GuildName
    , icon : Maybe Evergreen.V254.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V254.Discord.Id Evergreen.V254.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V254.MembersAndOwner.MembersAndOwner
            (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V254.Id.Id Evergreen.V254.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V254.Id.Id Evergreen.V254.Id.CustomEmojiId)
    }
