module Evergreen.V311.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V311.Call
import Evergreen.V311.ChannelDescription
import Evergreen.V311.ChannelName
import Evergreen.V311.Cloudflare
import Evergreen.V311.Discord
import Evergreen.V311.DiscordUserData
import Evergreen.V311.DmChannel
import Evergreen.V311.DmChannelId
import Evergreen.V311.Drawing
import Evergreen.V311.FileStatus
import Evergreen.V311.Game
import Evergreen.V311.GuildName
import Evergreen.V311.Id
import Evergreen.V311.IdArray
import Evergreen.V311.Log
import Evergreen.V311.MembersAndOwner
import Evergreen.V311.Message
import Evergreen.V311.NonemptyDict
import Evergreen.V311.OneToOne
import Evergreen.V311.Pagination
import Evergreen.V311.Postmark
import Evergreen.V311.SecretId
import Evergreen.V311.SessionIdHash
import Evergreen.V311.Slack
import Evergreen.V311.TextEditor
import Evergreen.V311.Thread
import Evergreen.V311.ToBackendLog
import Evergreen.V311.User
import Evergreen.V311.UserSession
import Evergreen.V311.VisibleMessages
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
        Evergreen.V311.NonemptyDict.NonemptyDict
            (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V311.Message.Message Evergreen.V311.Id.ChannelMessageId (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V311.Discord.PartialUser
        , icon : Maybe Evergreen.V311.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V311.Discord.User
        , linkedTo : Evergreen.V311.Id.Id Evergreen.V311.Id.UserId
        , icon : Maybe Evergreen.V311.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V311.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V311.Discord.User
        , linkedTo : Evergreen.V311.Id.Id Evergreen.V311.Id.UserId
        , icon : Maybe Evergreen.V311.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V311.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V311.Message.Message Evergreen.V311.Id.ChannelMessageId (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V311.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V311.MembersAndOwner.MembersAndOwner
            (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V311.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V311.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V311.Id.Id Evergreen.V311.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V311.GuildName.GuildName
    , owner : Evergreen.V311.Id.Id Evergreen.V311.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V311.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V311.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V311.Call.CallId
    | ConnectedToCall
        Evergreen.V311.Call.CallId
        { sessionId : Evergreen.V311.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V311.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V311.Call.RemoteCallData
    , currentlyViewing : Maybe ( Evergreen.V311.Id.AnyGuildOrDmId, Evergreen.V311.Id.ThreadRoute )
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameSwedishStatus
    = WordSpellingGameSwedishStatus_NotLoaded
    | WordSpellingGameSwedishStatus_Loading
    | WordSpellingGameSwedishStatus_Error Effect.Http.Error
    | WordSpellingGameSwedishStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V311.Id.Id Evergreen.V311.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V311.Id.Id Evergreen.V311.Id.UserId
    , name : Evergreen.V311.ChannelName.ChannelName
    , description : Evergreen.V311.ChannelDescription.ChannelDescription
    , messages : Evergreen.V311.IdArray.IdArray Evergreen.V311.Id.ChannelMessageId (Evergreen.V311.Message.MessageState Evergreen.V311.Id.ChannelMessageId (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId))
    , visibleMessages : Evergreen.V311.VisibleMessages.VisibleMessages Evergreen.V311.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) (Evergreen.V311.Thread.LastTypedAt Evergreen.V311.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) Evergreen.V311.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V311.Drawing.Drawing (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) Evergreen.V311.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V311.Id.Id Evergreen.V311.Id.UserId
    , name : Evergreen.V311.GuildName.GuildName
    , icon : Maybe Evergreen.V311.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V311.MembersAndOwner.MembersAndOwner
            (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V311.SecretId.SecretId Evergreen.V311.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V311.Id.Id Evergreen.V311.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V311.ChannelName.ChannelName
    , description : Evergreen.V311.ChannelDescription.ChannelDescription
    , messages : Evergreen.V311.IdArray.IdArray Evergreen.V311.Id.ChannelMessageId (Evergreen.V311.Message.MessageState Evergreen.V311.Id.ChannelMessageId (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId))
    , visibleMessages : Evergreen.V311.VisibleMessages.VisibleMessages Evergreen.V311.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Evergreen.V311.Thread.LastTypedAt Evergreen.V311.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) Evergreen.V311.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V311.Drawing.Drawing (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V311.GuildName.GuildName
    , icon : Maybe Evergreen.V311.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V311.MembersAndOwner.MembersAndOwner
            (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V311.Id.Id Evergreen.V311.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V311.Id.Id Evergreen.V311.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V311.NonemptyDict.NonemptyDict (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) Evergreen.V311.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V311.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V311.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V311.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V311.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V311.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V311.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V311.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V311.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V311.SessionIdHash.SessionIdHash (Evergreen.V311.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V311.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V311.SessionIdHash.SessionIdHash Evergreen.V311.UserSession.UserSession
    , wordSpellingGameSwedish : WordSpellingGameSwedishStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) Evergreen.V311.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId) Evergreen.V311.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V311.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V311.SessionIdHash.SessionIdHash Evergreen.V311.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V311.TextEditor.LocalState
    , calls : Evergreen.V311.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V311.Id.Id Evergreen.V311.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V311.Id.Id Evergreen.V311.Id.UserId
    , name : Evergreen.V311.ChannelName.ChannelName
    , description : Evergreen.V311.ChannelDescription.ChannelDescription
    , messages : Evergreen.V311.IdArray.IdArray Evergreen.V311.Id.ChannelMessageId (Evergreen.V311.Message.Message Evergreen.V311.Id.ChannelMessageId (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) (Evergreen.V311.Thread.LastTypedAt Evergreen.V311.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) Evergreen.V311.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V311.Drawing.Drawing (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) Evergreen.V311.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V311.Id.Id Evergreen.V311.Id.UserId
    , name : Evergreen.V311.GuildName.GuildName
    , icon : Maybe Evergreen.V311.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V311.MembersAndOwner.MembersAndOwner
            (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V311.SecretId.SecretId Evergreen.V311.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V311.Id.Id Evergreen.V311.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V311.ChannelName.ChannelName
    , description : Evergreen.V311.ChannelDescription.ChannelDescription
    , messages : Evergreen.V311.IdArray.IdArray Evergreen.V311.Id.ChannelMessageId (Evergreen.V311.Message.Message Evergreen.V311.Id.ChannelMessageId (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Evergreen.V311.Thread.LastTypedAt Evergreen.V311.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V311.OneToOne.OneToOne (Evergreen.V311.Discord.Id Evergreen.V311.Discord.MessageId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) Evergreen.V311.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V311.Drawing.Drawing (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V311.GuildName.GuildName
    , icon : Maybe Evergreen.V311.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V311.MembersAndOwner.MembersAndOwner
            (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V311.Id.Id Evergreen.V311.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V311.Id.Id Evergreen.V311.Id.CustomEmojiId)
    }
