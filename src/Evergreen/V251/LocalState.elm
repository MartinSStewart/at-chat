module Evergreen.V251.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V251.Call
import Evergreen.V251.ChannelDescription
import Evergreen.V251.ChannelName
import Evergreen.V251.Cloudflare
import Evergreen.V251.Discord
import Evergreen.V251.DiscordUserData
import Evergreen.V251.DmChannel
import Evergreen.V251.FileStatus
import Evergreen.V251.GuildName
import Evergreen.V251.Id
import Evergreen.V251.Log
import Evergreen.V251.MembersAndOwner
import Evergreen.V251.Message
import Evergreen.V251.NonemptyDict
import Evergreen.V251.OneToOne
import Evergreen.V251.Pagination
import Evergreen.V251.Postmark
import Evergreen.V251.SecretId
import Evergreen.V251.SessionIdHash
import Evergreen.V251.Slack
import Evergreen.V251.TextEditor
import Evergreen.V251.Thread
import Evergreen.V251.ToBackendLog
import Evergreen.V251.User
import Evergreen.V251.UserSession
import Evergreen.V251.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V251.NonemptyDict.NonemptyDict
            (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V251.Message.Message Evergreen.V251.Id.ChannelMessageId (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V251.Discord.PartialUser
        , icon : Maybe Evergreen.V251.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V251.Discord.User
        , linkedTo : Evergreen.V251.Id.Id Evergreen.V251.Id.UserId
        , icon : Maybe Evergreen.V251.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V251.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V251.Discord.User
        , linkedTo : Evergreen.V251.Id.Id Evergreen.V251.Id.UserId
        , icon : Maybe Evergreen.V251.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V251.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V251.Message.Message Evergreen.V251.Id.ChannelMessageId (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V251.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V251.MembersAndOwner.MembersAndOwner
            (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V251.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V251.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V251.Id.Id Evergreen.V251.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V251.GuildName.GuildName
    , owner : Evergreen.V251.Id.Id Evergreen.V251.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V251.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V251.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : Maybe Evergreen.V251.Call.RoomId
    , callSfu :
        Maybe
            { sessionId : Evergreen.V251.Cloudflare.RealtimeSessionId
            , trackNames : List Evergreen.V251.Cloudflare.TrackName
            , connected : Bool
            }
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V251.Id.Id Evergreen.V251.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V251.Id.Id Evergreen.V251.Id.UserId
    , name : Evergreen.V251.ChannelName.ChannelName
    , description : Evergreen.V251.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V251.Message.MessageState Evergreen.V251.Id.ChannelMessageId (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId))
    , visibleMessages : Evergreen.V251.VisibleMessages.VisibleMessages Evergreen.V251.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) (Evergreen.V251.Thread.LastTypedAt Evergreen.V251.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) Evergreen.V251.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V251.Id.Id Evergreen.V251.Id.UserId
    , name : Evergreen.V251.GuildName.GuildName
    , icon : Maybe Evergreen.V251.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V251.MembersAndOwner.MembersAndOwner
            (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V251.SecretId.SecretId Evergreen.V251.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V251.Id.Id Evergreen.V251.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V251.ChannelName.ChannelName
    , description : Evergreen.V251.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V251.Message.MessageState Evergreen.V251.Id.ChannelMessageId (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId))
    , visibleMessages : Evergreen.V251.VisibleMessages.VisibleMessages Evergreen.V251.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Evergreen.V251.Thread.LastTypedAt Evergreen.V251.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) Evergreen.V251.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V251.GuildName.GuildName
    , icon : Maybe Evergreen.V251.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V251.MembersAndOwner.MembersAndOwner
            (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V251.Id.Id Evergreen.V251.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V251.Id.Id Evergreen.V251.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V251.NonemptyDict.NonemptyDict (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) Evergreen.V251.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V251.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V251.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V251.Cloudflare.AppId
    , postmarkKey : Evergreen.V251.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V251.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V251.SessionIdHash.SessionIdHash (Evergreen.V251.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V251.ToBackendLog.ToBackendLogData
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
    , guilds : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) Evergreen.V251.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId) Evergreen.V251.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V251.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V251.SessionIdHash.SessionIdHash Evergreen.V251.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V251.TextEditor.LocalState
    , calls : Evergreen.V251.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V251.Id.Id Evergreen.V251.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V251.Id.Id Evergreen.V251.Id.UserId
    , name : Evergreen.V251.ChannelName.ChannelName
    , description : Evergreen.V251.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V251.Message.Message Evergreen.V251.Id.ChannelMessageId (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) (Evergreen.V251.Thread.LastTypedAt Evergreen.V251.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) Evergreen.V251.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V251.Id.Id Evergreen.V251.Id.UserId
    , name : Evergreen.V251.GuildName.GuildName
    , icon : Maybe Evergreen.V251.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V251.MembersAndOwner.MembersAndOwner
            (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V251.SecretId.SecretId Evergreen.V251.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V251.Id.Id Evergreen.V251.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V251.ChannelName.ChannelName
    , description : Evergreen.V251.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V251.Message.Message Evergreen.V251.Id.ChannelMessageId (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Evergreen.V251.Thread.LastTypedAt Evergreen.V251.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V251.OneToOne.OneToOne (Evergreen.V251.Discord.Id Evergreen.V251.Discord.MessageId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) Evergreen.V251.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V251.GuildName.GuildName
    , icon : Maybe Evergreen.V251.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V251.MembersAndOwner.MembersAndOwner
            (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V251.Id.Id Evergreen.V251.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V251.Id.Id Evergreen.V251.Id.CustomEmojiId)
    }
