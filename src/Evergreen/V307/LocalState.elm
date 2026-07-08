module Evergreen.V307.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V307.Call
import Evergreen.V307.ChannelDescription
import Evergreen.V307.ChannelName
import Evergreen.V307.Cloudflare
import Evergreen.V307.Discord
import Evergreen.V307.DiscordUserData
import Evergreen.V307.DmChannel
import Evergreen.V307.DmChannelId
import Evergreen.V307.Drawing
import Evergreen.V307.FileStatus
import Evergreen.V307.Game
import Evergreen.V307.GuildName
import Evergreen.V307.Id
import Evergreen.V307.IdArray
import Evergreen.V307.Log
import Evergreen.V307.MembersAndOwner
import Evergreen.V307.Message
import Evergreen.V307.NonemptyDict
import Evergreen.V307.OneToOne
import Evergreen.V307.Pagination
import Evergreen.V307.Postmark
import Evergreen.V307.SecretId
import Evergreen.V307.SessionIdHash
import Evergreen.V307.Slack
import Evergreen.V307.TextEditor
import Evergreen.V307.Thread
import Evergreen.V307.ToBackendLog
import Evergreen.V307.User
import Evergreen.V307.UserSession
import Evergreen.V307.VisibleMessages
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
        Evergreen.V307.NonemptyDict.NonemptyDict
            (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V307.Message.Message Evergreen.V307.Id.ChannelMessageId (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V307.Discord.PartialUser
        , icon : Maybe Evergreen.V307.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V307.Discord.User
        , linkedTo : Evergreen.V307.Id.Id Evergreen.V307.Id.UserId
        , icon : Maybe Evergreen.V307.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V307.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V307.Discord.User
        , linkedTo : Evergreen.V307.Id.Id Evergreen.V307.Id.UserId
        , icon : Maybe Evergreen.V307.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V307.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V307.Message.Message Evergreen.V307.Id.ChannelMessageId (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V307.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V307.MembersAndOwner.MembersAndOwner
            (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V307.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V307.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V307.Id.Id Evergreen.V307.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V307.GuildName.GuildName
    , owner : Evergreen.V307.Id.Id Evergreen.V307.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V307.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V307.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V307.Call.CallId
    | ConnectedToCall
        Evergreen.V307.Call.CallId
        { sessionId : Evergreen.V307.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V307.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V307.Call.RemoteCallData
    , currentlyViewing : Maybe ( Evergreen.V307.Id.AnyGuildOrDmId, Evergreen.V307.Id.ThreadRoute )
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameSwedishStatus
    = WordSpellingGameSwedishStatus_NotLoaded
    | WordSpellingGameSwedishStatus_Loading
    | WordSpellingGameSwedishStatus_Error Effect.Http.Error
    | WordSpellingGameSwedishStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V307.Id.Id Evergreen.V307.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V307.Id.Id Evergreen.V307.Id.UserId
    , name : Evergreen.V307.ChannelName.ChannelName
    , description : Evergreen.V307.ChannelDescription.ChannelDescription
    , messages : Evergreen.V307.IdArray.IdArray Evergreen.V307.Id.ChannelMessageId (Evergreen.V307.Message.MessageState Evergreen.V307.Id.ChannelMessageId (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId))
    , visibleMessages : Evergreen.V307.VisibleMessages.VisibleMessages Evergreen.V307.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) (Evergreen.V307.Thread.LastTypedAt Evergreen.V307.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) Evergreen.V307.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V307.Drawing.Drawing (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) Evergreen.V307.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V307.Id.Id Evergreen.V307.Id.UserId
    , name : Evergreen.V307.GuildName.GuildName
    , icon : Maybe Evergreen.V307.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V307.MembersAndOwner.MembersAndOwner
            (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V307.SecretId.SecretId Evergreen.V307.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V307.Id.Id Evergreen.V307.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V307.ChannelName.ChannelName
    , description : Evergreen.V307.ChannelDescription.ChannelDescription
    , messages : Evergreen.V307.IdArray.IdArray Evergreen.V307.Id.ChannelMessageId (Evergreen.V307.Message.MessageState Evergreen.V307.Id.ChannelMessageId (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId))
    , visibleMessages : Evergreen.V307.VisibleMessages.VisibleMessages Evergreen.V307.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Evergreen.V307.Thread.LastTypedAt Evergreen.V307.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) Evergreen.V307.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V307.Drawing.Drawing (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V307.GuildName.GuildName
    , icon : Maybe Evergreen.V307.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V307.MembersAndOwner.MembersAndOwner
            (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V307.Id.Id Evergreen.V307.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V307.Id.Id Evergreen.V307.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V307.NonemptyDict.NonemptyDict (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) Evergreen.V307.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V307.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V307.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V307.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V307.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V307.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V307.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V307.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V307.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V307.SessionIdHash.SessionIdHash (Evergreen.V307.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V307.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V307.SessionIdHash.SessionIdHash Evergreen.V307.UserSession.UserSession
    , wordSpellingGameSwedish : WordSpellingGameSwedishStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) Evergreen.V307.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId) Evergreen.V307.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V307.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V307.SessionIdHash.SessionIdHash Evergreen.V307.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V307.TextEditor.LocalState
    , calls : Evergreen.V307.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V307.Id.Id Evergreen.V307.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V307.Id.Id Evergreen.V307.Id.UserId
    , name : Evergreen.V307.ChannelName.ChannelName
    , description : Evergreen.V307.ChannelDescription.ChannelDescription
    , messages : Evergreen.V307.IdArray.IdArray Evergreen.V307.Id.ChannelMessageId (Evergreen.V307.Message.Message Evergreen.V307.Id.ChannelMessageId (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) (Evergreen.V307.Thread.LastTypedAt Evergreen.V307.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) Evergreen.V307.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V307.Drawing.Drawing (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) Evergreen.V307.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V307.Id.Id Evergreen.V307.Id.UserId
    , name : Evergreen.V307.GuildName.GuildName
    , icon : Maybe Evergreen.V307.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V307.MembersAndOwner.MembersAndOwner
            (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V307.SecretId.SecretId Evergreen.V307.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V307.Id.Id Evergreen.V307.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V307.ChannelName.ChannelName
    , description : Evergreen.V307.ChannelDescription.ChannelDescription
    , messages : Evergreen.V307.IdArray.IdArray Evergreen.V307.Id.ChannelMessageId (Evergreen.V307.Message.Message Evergreen.V307.Id.ChannelMessageId (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Evergreen.V307.Thread.LastTypedAt Evergreen.V307.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V307.OneToOne.OneToOne (Evergreen.V307.Discord.Id Evergreen.V307.Discord.MessageId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) Evergreen.V307.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V307.Drawing.Drawing (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V307.GuildName.GuildName
    , icon : Maybe Evergreen.V307.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V307.MembersAndOwner.MembersAndOwner
            (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V307.Id.Id Evergreen.V307.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V307.Id.Id Evergreen.V307.Id.CustomEmojiId)
    }
