module Evergreen.V252.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V252.Call
import Evergreen.V252.ChannelDescription
import Evergreen.V252.ChannelName
import Evergreen.V252.Cloudflare
import Evergreen.V252.Discord
import Evergreen.V252.DiscordUserData
import Evergreen.V252.DmChannel
import Evergreen.V252.FileStatus
import Evergreen.V252.GuildName
import Evergreen.V252.Id
import Evergreen.V252.Log
import Evergreen.V252.MembersAndOwner
import Evergreen.V252.Message
import Evergreen.V252.NonemptyDict
import Evergreen.V252.OneToOne
import Evergreen.V252.Pagination
import Evergreen.V252.Postmark
import Evergreen.V252.SecretId
import Evergreen.V252.SessionIdHash
import Evergreen.V252.Slack
import Evergreen.V252.TextEditor
import Evergreen.V252.Thread
import Evergreen.V252.ToBackendLog
import Evergreen.V252.User
import Evergreen.V252.UserSession
import Evergreen.V252.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V252.NonemptyDict.NonemptyDict
            (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V252.Message.Message Evergreen.V252.Id.ChannelMessageId (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V252.Discord.PartialUser
        , icon : Maybe Evergreen.V252.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V252.Discord.User
        , linkedTo : Evergreen.V252.Id.Id Evergreen.V252.Id.UserId
        , icon : Maybe Evergreen.V252.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V252.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V252.Discord.User
        , linkedTo : Evergreen.V252.Id.Id Evergreen.V252.Id.UserId
        , icon : Maybe Evergreen.V252.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V252.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V252.Message.Message Evergreen.V252.Id.ChannelMessageId (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V252.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V252.MembersAndOwner.MembersAndOwner
            (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V252.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V252.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V252.Id.Id Evergreen.V252.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V252.GuildName.GuildName
    , owner : Evergreen.V252.Id.Id Evergreen.V252.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V252.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V252.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : Maybe Evergreen.V252.Call.RoomId
    , callSfu :
        Maybe
            { sessionId : Evergreen.V252.Cloudflare.RealtimeSessionId
            , trackNames : List Evergreen.V252.Cloudflare.TrackName
            , connected : Bool
            }
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V252.Id.Id Evergreen.V252.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V252.Id.Id Evergreen.V252.Id.UserId
    , name : Evergreen.V252.ChannelName.ChannelName
    , description : Evergreen.V252.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V252.Message.MessageState Evergreen.V252.Id.ChannelMessageId (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId))
    , visibleMessages : Evergreen.V252.VisibleMessages.VisibleMessages Evergreen.V252.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) (Evergreen.V252.Thread.LastTypedAt Evergreen.V252.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) Evergreen.V252.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V252.Id.Id Evergreen.V252.Id.UserId
    , name : Evergreen.V252.GuildName.GuildName
    , icon : Maybe Evergreen.V252.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V252.MembersAndOwner.MembersAndOwner
            (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V252.SecretId.SecretId Evergreen.V252.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V252.Id.Id Evergreen.V252.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V252.ChannelName.ChannelName
    , description : Evergreen.V252.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V252.Message.MessageState Evergreen.V252.Id.ChannelMessageId (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId))
    , visibleMessages : Evergreen.V252.VisibleMessages.VisibleMessages Evergreen.V252.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Evergreen.V252.Thread.LastTypedAt Evergreen.V252.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) Evergreen.V252.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V252.GuildName.GuildName
    , icon : Maybe Evergreen.V252.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V252.MembersAndOwner.MembersAndOwner
            (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V252.Id.Id Evergreen.V252.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V252.Id.Id Evergreen.V252.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V252.NonemptyDict.NonemptyDict (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) Evergreen.V252.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V252.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V252.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V252.Cloudflare.AppId
    , postmarkKey : Evergreen.V252.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V252.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V252.SessionIdHash.SessionIdHash (Evergreen.V252.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V252.ToBackendLog.ToBackendLogData
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
    , guilds : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) Evergreen.V252.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId) Evergreen.V252.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V252.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V252.SessionIdHash.SessionIdHash Evergreen.V252.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V252.TextEditor.LocalState
    , calls : Evergreen.V252.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V252.Id.Id Evergreen.V252.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V252.Id.Id Evergreen.V252.Id.UserId
    , name : Evergreen.V252.ChannelName.ChannelName
    , description : Evergreen.V252.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V252.Message.Message Evergreen.V252.Id.ChannelMessageId (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) (Evergreen.V252.Thread.LastTypedAt Evergreen.V252.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) Evergreen.V252.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V252.Id.Id Evergreen.V252.Id.UserId
    , name : Evergreen.V252.GuildName.GuildName
    , icon : Maybe Evergreen.V252.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V252.MembersAndOwner.MembersAndOwner
            (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V252.SecretId.SecretId Evergreen.V252.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V252.Id.Id Evergreen.V252.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V252.ChannelName.ChannelName
    , description : Evergreen.V252.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V252.Message.Message Evergreen.V252.Id.ChannelMessageId (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Evergreen.V252.Thread.LastTypedAt Evergreen.V252.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V252.OneToOne.OneToOne (Evergreen.V252.Discord.Id Evergreen.V252.Discord.MessageId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) Evergreen.V252.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V252.GuildName.GuildName
    , icon : Maybe Evergreen.V252.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V252.MembersAndOwner.MembersAndOwner
            (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V252.Id.Id Evergreen.V252.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V252.Id.Id Evergreen.V252.Id.CustomEmojiId)
    }
