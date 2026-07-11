module Evergreen.V315.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V315.Call
import Evergreen.V315.ChannelDescription
import Evergreen.V315.ChannelName
import Evergreen.V315.Cloudflare
import Evergreen.V315.Discord
import Evergreen.V315.DiscordUserData
import Evergreen.V315.DmChannel
import Evergreen.V315.DmChannelId
import Evergreen.V315.Drawing
import Evergreen.V315.FileStatus
import Evergreen.V315.Game
import Evergreen.V315.GuildName
import Evergreen.V315.Id
import Evergreen.V315.IdArray
import Evergreen.V315.Log
import Evergreen.V315.MembersAndOwner
import Evergreen.V315.Message
import Evergreen.V315.NonemptyDict
import Evergreen.V315.OneToOne
import Evergreen.V315.Pagination
import Evergreen.V315.Postmark
import Evergreen.V315.SecretId
import Evergreen.V315.SessionIdHash
import Evergreen.V315.Slack
import Evergreen.V315.TextEditor
import Evergreen.V315.Thread
import Evergreen.V315.ToBackendLog
import Evergreen.V315.User
import Evergreen.V315.UserSession
import Evergreen.V315.VisibleMessages
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
        Evergreen.V315.NonemptyDict.NonemptyDict
            (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V315.Message.Message Evergreen.V315.Id.ChannelMessageId (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V315.Discord.PartialUser
        , icon : Maybe Evergreen.V315.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V315.Discord.User
        , linkedTo : Evergreen.V315.Id.Id Evergreen.V315.Id.UserId
        , icon : Maybe Evergreen.V315.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V315.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V315.Discord.User
        , linkedTo : Evergreen.V315.Id.Id Evergreen.V315.Id.UserId
        , icon : Maybe Evergreen.V315.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V315.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V315.Message.Message Evergreen.V315.Id.ChannelMessageId (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V315.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V315.MembersAndOwner.MembersAndOwner
            (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V315.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V315.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V315.Id.Id Evergreen.V315.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V315.GuildName.GuildName
    , owner : Evergreen.V315.Id.Id Evergreen.V315.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V315.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V315.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V315.Call.CallId
    | ConnectedToCall
        Evergreen.V315.Call.CallId
        { sessionId : Evergreen.V315.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V315.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V315.Call.RemoteCallData
    , currentlyViewing : Maybe ( Evergreen.V315.Id.AnyGuildOrDmId, Evergreen.V315.Id.ThreadRoute )
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameSwedishStatus
    = WordSpellingGameSwedishStatus_NotLoaded
    | WordSpellingGameSwedishStatus_Loading
    | WordSpellingGameSwedishStatus_Error Effect.Http.Error
    | WordSpellingGameSwedishStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V315.Id.Id Evergreen.V315.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V315.Id.Id Evergreen.V315.Id.UserId
    , name : Evergreen.V315.ChannelName.ChannelName
    , description : Evergreen.V315.ChannelDescription.ChannelDescription
    , messages : Evergreen.V315.IdArray.IdArray Evergreen.V315.Id.ChannelMessageId (Evergreen.V315.Message.MessageState Evergreen.V315.Id.ChannelMessageId (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId))
    , visibleMessages : Evergreen.V315.VisibleMessages.VisibleMessages Evergreen.V315.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) (Evergreen.V315.Thread.LastTypedAt Evergreen.V315.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) Evergreen.V315.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V315.Drawing.Drawing (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) Evergreen.V315.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V315.Id.Id Evergreen.V315.Id.UserId
    , name : Evergreen.V315.GuildName.GuildName
    , icon : Maybe Evergreen.V315.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V315.MembersAndOwner.MembersAndOwner
            (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V315.SecretId.SecretId Evergreen.V315.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V315.Id.Id Evergreen.V315.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V315.ChannelName.ChannelName
    , description : Evergreen.V315.ChannelDescription.ChannelDescription
    , messages : Evergreen.V315.IdArray.IdArray Evergreen.V315.Id.ChannelMessageId (Evergreen.V315.Message.MessageState Evergreen.V315.Id.ChannelMessageId (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId))
    , visibleMessages : Evergreen.V315.VisibleMessages.VisibleMessages Evergreen.V315.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Evergreen.V315.Thread.LastTypedAt Evergreen.V315.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) Evergreen.V315.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V315.Drawing.Drawing (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V315.GuildName.GuildName
    , icon : Maybe Evergreen.V315.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V315.MembersAndOwner.MembersAndOwner
            (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V315.Id.Id Evergreen.V315.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V315.Id.Id Evergreen.V315.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V315.NonemptyDict.NonemptyDict (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) Evergreen.V315.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V315.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V315.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V315.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V315.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V315.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V315.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V315.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V315.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V315.SessionIdHash.SessionIdHash (Evergreen.V315.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V315.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V315.SessionIdHash.SessionIdHash Evergreen.V315.UserSession.UserSession
    , wordSpellingGameSwedish : WordSpellingGameSwedishStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) Evergreen.V315.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId) Evergreen.V315.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V315.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V315.SessionIdHash.SessionIdHash Evergreen.V315.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V315.TextEditor.LocalState
    , calls : Evergreen.V315.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V315.Id.Id Evergreen.V315.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V315.Id.Id Evergreen.V315.Id.UserId
    , name : Evergreen.V315.ChannelName.ChannelName
    , description : Evergreen.V315.ChannelDescription.ChannelDescription
    , messages : Evergreen.V315.IdArray.IdArray Evergreen.V315.Id.ChannelMessageId (Evergreen.V315.Message.Message Evergreen.V315.Id.ChannelMessageId (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) (Evergreen.V315.Thread.LastTypedAt Evergreen.V315.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) Evergreen.V315.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V315.Drawing.Drawing (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) Evergreen.V315.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V315.Id.Id Evergreen.V315.Id.UserId
    , name : Evergreen.V315.GuildName.GuildName
    , icon : Maybe Evergreen.V315.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V315.MembersAndOwner.MembersAndOwner
            (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V315.SecretId.SecretId Evergreen.V315.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V315.Id.Id Evergreen.V315.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V315.ChannelName.ChannelName
    , description : Evergreen.V315.ChannelDescription.ChannelDescription
    , messages : Evergreen.V315.IdArray.IdArray Evergreen.V315.Id.ChannelMessageId (Evergreen.V315.Message.Message Evergreen.V315.Id.ChannelMessageId (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Evergreen.V315.Thread.LastTypedAt Evergreen.V315.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V315.OneToOne.OneToOne (Evergreen.V315.Discord.Id Evergreen.V315.Discord.MessageId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) Evergreen.V315.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V315.Drawing.Drawing (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V315.GuildName.GuildName
    , icon : Maybe Evergreen.V315.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V315.MembersAndOwner.MembersAndOwner
            (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V315.Id.Id Evergreen.V315.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V315.Id.Id Evergreen.V315.Id.CustomEmojiId)
    }
