module Evergreen.V312.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V312.Call
import Evergreen.V312.ChannelDescription
import Evergreen.V312.ChannelName
import Evergreen.V312.Cloudflare
import Evergreen.V312.Discord
import Evergreen.V312.DiscordUserData
import Evergreen.V312.DmChannel
import Evergreen.V312.DmChannelId
import Evergreen.V312.Drawing
import Evergreen.V312.FileStatus
import Evergreen.V312.Game
import Evergreen.V312.GuildName
import Evergreen.V312.Id
import Evergreen.V312.IdArray
import Evergreen.V312.Log
import Evergreen.V312.MembersAndOwner
import Evergreen.V312.Message
import Evergreen.V312.NonemptyDict
import Evergreen.V312.OneToOne
import Evergreen.V312.Pagination
import Evergreen.V312.Postmark
import Evergreen.V312.SecretId
import Evergreen.V312.SessionIdHash
import Evergreen.V312.Slack
import Evergreen.V312.TextEditor
import Evergreen.V312.Thread
import Evergreen.V312.ToBackendLog
import Evergreen.V312.User
import Evergreen.V312.UserSession
import Evergreen.V312.VisibleMessages
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
        Evergreen.V312.NonemptyDict.NonemptyDict
            (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V312.Message.Message Evergreen.V312.Id.ChannelMessageId (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V312.Discord.PartialUser
        , icon : Maybe Evergreen.V312.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V312.Discord.User
        , linkedTo : Evergreen.V312.Id.Id Evergreen.V312.Id.UserId
        , icon : Maybe Evergreen.V312.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V312.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V312.Discord.User
        , linkedTo : Evergreen.V312.Id.Id Evergreen.V312.Id.UserId
        , icon : Maybe Evergreen.V312.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V312.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V312.Message.Message Evergreen.V312.Id.ChannelMessageId (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V312.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V312.MembersAndOwner.MembersAndOwner
            (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V312.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V312.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V312.Id.Id Evergreen.V312.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V312.GuildName.GuildName
    , owner : Evergreen.V312.Id.Id Evergreen.V312.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V312.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V312.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V312.Call.CallId
    | ConnectedToCall
        Evergreen.V312.Call.CallId
        { sessionId : Evergreen.V312.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V312.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V312.Call.RemoteCallData
    , currentlyViewing : Maybe ( Evergreen.V312.Id.AnyGuildOrDmId, Evergreen.V312.Id.ThreadRoute )
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameSwedishStatus
    = WordSpellingGameSwedishStatus_NotLoaded
    | WordSpellingGameSwedishStatus_Loading
    | WordSpellingGameSwedishStatus_Error Effect.Http.Error
    | WordSpellingGameSwedishStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V312.Id.Id Evergreen.V312.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V312.Id.Id Evergreen.V312.Id.UserId
    , name : Evergreen.V312.ChannelName.ChannelName
    , description : Evergreen.V312.ChannelDescription.ChannelDescription
    , messages : Evergreen.V312.IdArray.IdArray Evergreen.V312.Id.ChannelMessageId (Evergreen.V312.Message.MessageState Evergreen.V312.Id.ChannelMessageId (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId))
    , visibleMessages : Evergreen.V312.VisibleMessages.VisibleMessages Evergreen.V312.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) (Evergreen.V312.Thread.LastTypedAt Evergreen.V312.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) Evergreen.V312.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V312.Drawing.Drawing (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) Evergreen.V312.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V312.Id.Id Evergreen.V312.Id.UserId
    , name : Evergreen.V312.GuildName.GuildName
    , icon : Maybe Evergreen.V312.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V312.MembersAndOwner.MembersAndOwner
            (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V312.SecretId.SecretId Evergreen.V312.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V312.Id.Id Evergreen.V312.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V312.ChannelName.ChannelName
    , description : Evergreen.V312.ChannelDescription.ChannelDescription
    , messages : Evergreen.V312.IdArray.IdArray Evergreen.V312.Id.ChannelMessageId (Evergreen.V312.Message.MessageState Evergreen.V312.Id.ChannelMessageId (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId))
    , visibleMessages : Evergreen.V312.VisibleMessages.VisibleMessages Evergreen.V312.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Evergreen.V312.Thread.LastTypedAt Evergreen.V312.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) Evergreen.V312.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V312.Drawing.Drawing (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V312.GuildName.GuildName
    , icon : Maybe Evergreen.V312.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V312.MembersAndOwner.MembersAndOwner
            (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V312.Id.Id Evergreen.V312.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V312.Id.Id Evergreen.V312.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V312.NonemptyDict.NonemptyDict (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) Evergreen.V312.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V312.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V312.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V312.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V312.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V312.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V312.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V312.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V312.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V312.SessionIdHash.SessionIdHash (Evergreen.V312.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V312.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V312.SessionIdHash.SessionIdHash Evergreen.V312.UserSession.UserSession
    , wordSpellingGameSwedish : WordSpellingGameSwedishStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) Evergreen.V312.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId) Evergreen.V312.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V312.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V312.SessionIdHash.SessionIdHash Evergreen.V312.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V312.TextEditor.LocalState
    , calls : Evergreen.V312.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V312.Id.Id Evergreen.V312.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V312.Id.Id Evergreen.V312.Id.UserId
    , name : Evergreen.V312.ChannelName.ChannelName
    , description : Evergreen.V312.ChannelDescription.ChannelDescription
    , messages : Evergreen.V312.IdArray.IdArray Evergreen.V312.Id.ChannelMessageId (Evergreen.V312.Message.Message Evergreen.V312.Id.ChannelMessageId (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) (Evergreen.V312.Thread.LastTypedAt Evergreen.V312.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) Evergreen.V312.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V312.Drawing.Drawing (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) Evergreen.V312.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V312.Id.Id Evergreen.V312.Id.UserId
    , name : Evergreen.V312.GuildName.GuildName
    , icon : Maybe Evergreen.V312.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V312.MembersAndOwner.MembersAndOwner
            (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V312.SecretId.SecretId Evergreen.V312.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V312.Id.Id Evergreen.V312.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V312.ChannelName.ChannelName
    , description : Evergreen.V312.ChannelDescription.ChannelDescription
    , messages : Evergreen.V312.IdArray.IdArray Evergreen.V312.Id.ChannelMessageId (Evergreen.V312.Message.Message Evergreen.V312.Id.ChannelMessageId (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Evergreen.V312.Thread.LastTypedAt Evergreen.V312.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V312.OneToOne.OneToOne (Evergreen.V312.Discord.Id Evergreen.V312.Discord.MessageId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) Evergreen.V312.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V312.Drawing.Drawing (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V312.GuildName.GuildName
    , icon : Maybe Evergreen.V312.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V312.MembersAndOwner.MembersAndOwner
            (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V312.Id.Id Evergreen.V312.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V312.Id.Id Evergreen.V312.Id.CustomEmojiId)
    }
