module Evergreen.V327.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V327.Call
import Evergreen.V327.ChannelDescription
import Evergreen.V327.ChannelName
import Evergreen.V327.Cloudflare
import Evergreen.V327.Discord
import Evergreen.V327.DiscordUserData
import Evergreen.V327.DmChannel
import Evergreen.V327.DmChannelId
import Evergreen.V327.Drawing
import Evergreen.V327.FileStatus
import Evergreen.V327.Game
import Evergreen.V327.GuildName
import Evergreen.V327.Id
import Evergreen.V327.IdArray
import Evergreen.V327.Log
import Evergreen.V327.MembersAndOwner
import Evergreen.V327.Message
import Evergreen.V327.NonemptyDict
import Evergreen.V327.OneToOne
import Evergreen.V327.Pagination
import Evergreen.V327.Postmark
import Evergreen.V327.SecretId
import Evergreen.V327.SessionIdHash
import Evergreen.V327.Slack
import Evergreen.V327.TextEditor
import Evergreen.V327.Thread
import Evergreen.V327.ToBackendLog
import Evergreen.V327.User
import Evergreen.V327.UserSession
import Evergreen.V327.VisibleMessages
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
        Evergreen.V327.NonemptyDict.NonemptyDict
            (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V327.Message.Message Evergreen.V327.Id.ChannelMessageId (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V327.Discord.PartialUser
        , icon : Maybe Evergreen.V327.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V327.Discord.User
        , linkedTo : Evergreen.V327.Id.Id Evergreen.V327.Id.UserId
        , icon : Maybe Evergreen.V327.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V327.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V327.Discord.User
        , linkedTo : Evergreen.V327.Id.Id Evergreen.V327.Id.UserId
        , icon : Maybe Evergreen.V327.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V327.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V327.Message.Message Evergreen.V327.Id.ChannelMessageId (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V327.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V327.MembersAndOwner.MembersAndOwner
            (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V327.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V327.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V327.Id.Id Evergreen.V327.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V327.GuildName.GuildName
    , owner : Evergreen.V327.Id.Id Evergreen.V327.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V327.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V327.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V327.Call.CallId
    | ConnectedToCall
        Evergreen.V327.Call.CallId
        { sessionId : Evergreen.V327.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V327.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V327.Call.RemoteCallData
    , currentlyViewing : Maybe ( Evergreen.V327.Id.AnyGuildOrDmId, Evergreen.V327.Id.ThreadRoute )
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V327.Id.Id Evergreen.V327.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V327.Id.Id Evergreen.V327.Id.UserId
    , name : Evergreen.V327.ChannelName.ChannelName
    , description : Evergreen.V327.ChannelDescription.ChannelDescription
    , messages : Evergreen.V327.IdArray.IdArray Evergreen.V327.Id.ChannelMessageId (Evergreen.V327.Message.MessageState Evergreen.V327.Id.ChannelMessageId (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId))
    , visibleMessages : Evergreen.V327.VisibleMessages.VisibleMessages Evergreen.V327.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) (Evergreen.V327.Thread.LastTypedAt Evergreen.V327.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) Evergreen.V327.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V327.Drawing.Drawing (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) Evergreen.V327.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V327.Id.Id Evergreen.V327.Id.UserId
    , name : Evergreen.V327.GuildName.GuildName
    , icon : Maybe Evergreen.V327.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V327.MembersAndOwner.MembersAndOwner
            (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V327.SecretId.SecretId Evergreen.V327.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V327.Id.Id Evergreen.V327.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V327.ChannelName.ChannelName
    , description : Evergreen.V327.ChannelDescription.ChannelDescription
    , messages : Evergreen.V327.IdArray.IdArray Evergreen.V327.Id.ChannelMessageId (Evergreen.V327.Message.MessageState Evergreen.V327.Id.ChannelMessageId (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId))
    , visibleMessages : Evergreen.V327.VisibleMessages.VisibleMessages Evergreen.V327.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Evergreen.V327.Thread.LastTypedAt Evergreen.V327.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) Evergreen.V327.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V327.Drawing.Drawing (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V327.GuildName.GuildName
    , icon : Maybe Evergreen.V327.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V327.MembersAndOwner.MembersAndOwner
            (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V327.Id.Id Evergreen.V327.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V327.Id.Id Evergreen.V327.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V327.NonemptyDict.NonemptyDict (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) Evergreen.V327.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V327.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V327.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V327.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V327.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V327.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V327.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V327.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V327.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V327.SessionIdHash.SessionIdHash (Evergreen.V327.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V327.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V327.SessionIdHash.SessionIdHash Evergreen.V327.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) Evergreen.V327.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId) Evergreen.V327.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V327.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V327.SessionIdHash.SessionIdHash Evergreen.V327.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V327.TextEditor.LocalState
    , calls : Evergreen.V327.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V327.Id.Id Evergreen.V327.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V327.Id.Id Evergreen.V327.Id.UserId
    , name : Evergreen.V327.ChannelName.ChannelName
    , description : Evergreen.V327.ChannelDescription.ChannelDescription
    , messages : Evergreen.V327.IdArray.IdArray Evergreen.V327.Id.ChannelMessageId (Evergreen.V327.Message.Message Evergreen.V327.Id.ChannelMessageId (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) (Evergreen.V327.Thread.LastTypedAt Evergreen.V327.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) Evergreen.V327.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V327.Drawing.Drawing (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) Evergreen.V327.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V327.Id.Id Evergreen.V327.Id.UserId
    , name : Evergreen.V327.GuildName.GuildName
    , icon : Maybe Evergreen.V327.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V327.MembersAndOwner.MembersAndOwner
            (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V327.SecretId.SecretId Evergreen.V327.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V327.Id.Id Evergreen.V327.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V327.ChannelName.ChannelName
    , description : Evergreen.V327.ChannelDescription.ChannelDescription
    , messages : Evergreen.V327.IdArray.IdArray Evergreen.V327.Id.ChannelMessageId (Evergreen.V327.Message.Message Evergreen.V327.Id.ChannelMessageId (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Evergreen.V327.Thread.LastTypedAt Evergreen.V327.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V327.OneToOne.OneToOne (Evergreen.V327.Discord.Id Evergreen.V327.Discord.MessageId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) Evergreen.V327.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V327.Drawing.Drawing (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V327.GuildName.GuildName
    , icon : Maybe Evergreen.V327.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V327.MembersAndOwner.MembersAndOwner
            (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V327.Id.Id Evergreen.V327.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V327.Id.Id Evergreen.V327.Id.CustomEmojiId)
    }
