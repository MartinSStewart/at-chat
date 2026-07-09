module Evergreen.V308.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V308.Call
import Evergreen.V308.ChannelDescription
import Evergreen.V308.ChannelName
import Evergreen.V308.Cloudflare
import Evergreen.V308.Discord
import Evergreen.V308.DiscordUserData
import Evergreen.V308.DmChannel
import Evergreen.V308.DmChannelId
import Evergreen.V308.Drawing
import Evergreen.V308.FileStatus
import Evergreen.V308.Game
import Evergreen.V308.GuildName
import Evergreen.V308.Id
import Evergreen.V308.IdArray
import Evergreen.V308.Log
import Evergreen.V308.MembersAndOwner
import Evergreen.V308.Message
import Evergreen.V308.NonemptyDict
import Evergreen.V308.OneToOne
import Evergreen.V308.Pagination
import Evergreen.V308.Postmark
import Evergreen.V308.SecretId
import Evergreen.V308.SessionIdHash
import Evergreen.V308.Slack
import Evergreen.V308.TextEditor
import Evergreen.V308.Thread
import Evergreen.V308.ToBackendLog
import Evergreen.V308.User
import Evergreen.V308.UserSession
import Evergreen.V308.VisibleMessages
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
        Evergreen.V308.NonemptyDict.NonemptyDict
            (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V308.Message.Message Evergreen.V308.Id.ChannelMessageId (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V308.Discord.PartialUser
        , icon : Maybe Evergreen.V308.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V308.Discord.User
        , linkedTo : Evergreen.V308.Id.Id Evergreen.V308.Id.UserId
        , icon : Maybe Evergreen.V308.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V308.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V308.Discord.User
        , linkedTo : Evergreen.V308.Id.Id Evergreen.V308.Id.UserId
        , icon : Maybe Evergreen.V308.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V308.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V308.Message.Message Evergreen.V308.Id.ChannelMessageId (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V308.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V308.MembersAndOwner.MembersAndOwner
            (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V308.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V308.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V308.Id.Id Evergreen.V308.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V308.GuildName.GuildName
    , owner : Evergreen.V308.Id.Id Evergreen.V308.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V308.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V308.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V308.Call.CallId
    | ConnectedToCall
        Evergreen.V308.Call.CallId
        { sessionId : Evergreen.V308.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V308.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V308.Call.RemoteCallData
    , currentlyViewing : Maybe ( Evergreen.V308.Id.AnyGuildOrDmId, Evergreen.V308.Id.ThreadRoute )
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameSwedishStatus
    = WordSpellingGameSwedishStatus_NotLoaded
    | WordSpellingGameSwedishStatus_Loading
    | WordSpellingGameSwedishStatus_Error Effect.Http.Error
    | WordSpellingGameSwedishStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V308.Id.Id Evergreen.V308.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V308.Id.Id Evergreen.V308.Id.UserId
    , name : Evergreen.V308.ChannelName.ChannelName
    , description : Evergreen.V308.ChannelDescription.ChannelDescription
    , messages : Evergreen.V308.IdArray.IdArray Evergreen.V308.Id.ChannelMessageId (Evergreen.V308.Message.MessageState Evergreen.V308.Id.ChannelMessageId (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId))
    , visibleMessages : Evergreen.V308.VisibleMessages.VisibleMessages Evergreen.V308.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) (Evergreen.V308.Thread.LastTypedAt Evergreen.V308.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) Evergreen.V308.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V308.Drawing.Drawing (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) Evergreen.V308.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V308.Id.Id Evergreen.V308.Id.UserId
    , name : Evergreen.V308.GuildName.GuildName
    , icon : Maybe Evergreen.V308.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V308.MembersAndOwner.MembersAndOwner
            (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V308.SecretId.SecretId Evergreen.V308.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V308.Id.Id Evergreen.V308.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V308.ChannelName.ChannelName
    , description : Evergreen.V308.ChannelDescription.ChannelDescription
    , messages : Evergreen.V308.IdArray.IdArray Evergreen.V308.Id.ChannelMessageId (Evergreen.V308.Message.MessageState Evergreen.V308.Id.ChannelMessageId (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId))
    , visibleMessages : Evergreen.V308.VisibleMessages.VisibleMessages Evergreen.V308.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Evergreen.V308.Thread.LastTypedAt Evergreen.V308.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) Evergreen.V308.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V308.Drawing.Drawing (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V308.GuildName.GuildName
    , icon : Maybe Evergreen.V308.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V308.MembersAndOwner.MembersAndOwner
            (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V308.Id.Id Evergreen.V308.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V308.Id.Id Evergreen.V308.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V308.NonemptyDict.NonemptyDict (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) Evergreen.V308.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V308.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V308.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V308.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V308.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V308.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V308.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V308.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V308.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V308.SessionIdHash.SessionIdHash (Evergreen.V308.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V308.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V308.SessionIdHash.SessionIdHash Evergreen.V308.UserSession.UserSession
    , wordSpellingGameSwedish : WordSpellingGameSwedishStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) Evergreen.V308.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId) Evergreen.V308.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V308.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V308.SessionIdHash.SessionIdHash Evergreen.V308.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V308.TextEditor.LocalState
    , calls : Evergreen.V308.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V308.Id.Id Evergreen.V308.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V308.Id.Id Evergreen.V308.Id.UserId
    , name : Evergreen.V308.ChannelName.ChannelName
    , description : Evergreen.V308.ChannelDescription.ChannelDescription
    , messages : Evergreen.V308.IdArray.IdArray Evergreen.V308.Id.ChannelMessageId (Evergreen.V308.Message.Message Evergreen.V308.Id.ChannelMessageId (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) (Evergreen.V308.Thread.LastTypedAt Evergreen.V308.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) Evergreen.V308.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V308.Drawing.Drawing (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) Evergreen.V308.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V308.Id.Id Evergreen.V308.Id.UserId
    , name : Evergreen.V308.GuildName.GuildName
    , icon : Maybe Evergreen.V308.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V308.MembersAndOwner.MembersAndOwner
            (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V308.SecretId.SecretId Evergreen.V308.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V308.Id.Id Evergreen.V308.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V308.ChannelName.ChannelName
    , description : Evergreen.V308.ChannelDescription.ChannelDescription
    , messages : Evergreen.V308.IdArray.IdArray Evergreen.V308.Id.ChannelMessageId (Evergreen.V308.Message.Message Evergreen.V308.Id.ChannelMessageId (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Evergreen.V308.Thread.LastTypedAt Evergreen.V308.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V308.OneToOne.OneToOne (Evergreen.V308.Discord.Id Evergreen.V308.Discord.MessageId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) Evergreen.V308.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V308.Drawing.Drawing (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V308.GuildName.GuildName
    , icon : Maybe Evergreen.V308.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V308.MembersAndOwner.MembersAndOwner
            (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V308.Id.Id Evergreen.V308.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V308.Id.Id Evergreen.V308.Id.CustomEmojiId)
    }
