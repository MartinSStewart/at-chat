module Evergreen.V316.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V316.Call
import Evergreen.V316.ChannelDescription
import Evergreen.V316.ChannelName
import Evergreen.V316.Cloudflare
import Evergreen.V316.Discord
import Evergreen.V316.DiscordUserData
import Evergreen.V316.DmChannel
import Evergreen.V316.DmChannelId
import Evergreen.V316.Drawing
import Evergreen.V316.FileStatus
import Evergreen.V316.Game
import Evergreen.V316.GuildName
import Evergreen.V316.Id
import Evergreen.V316.IdArray
import Evergreen.V316.Log
import Evergreen.V316.MembersAndOwner
import Evergreen.V316.Message
import Evergreen.V316.NonemptyDict
import Evergreen.V316.OneToOne
import Evergreen.V316.Pagination
import Evergreen.V316.Postmark
import Evergreen.V316.SecretId
import Evergreen.V316.SessionIdHash
import Evergreen.V316.Slack
import Evergreen.V316.TextEditor
import Evergreen.V316.Thread
import Evergreen.V316.ToBackendLog
import Evergreen.V316.User
import Evergreen.V316.UserSession
import Evergreen.V316.VisibleMessages
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
        Evergreen.V316.NonemptyDict.NonemptyDict
            (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V316.Message.Message Evergreen.V316.Id.ChannelMessageId (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V316.Discord.PartialUser
        , icon : Maybe Evergreen.V316.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V316.Discord.User
        , linkedTo : Evergreen.V316.Id.Id Evergreen.V316.Id.UserId
        , icon : Maybe Evergreen.V316.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V316.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V316.Discord.User
        , linkedTo : Evergreen.V316.Id.Id Evergreen.V316.Id.UserId
        , icon : Maybe Evergreen.V316.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V316.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V316.Message.Message Evergreen.V316.Id.ChannelMessageId (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V316.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V316.MembersAndOwner.MembersAndOwner
            (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V316.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V316.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V316.Id.Id Evergreen.V316.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V316.GuildName.GuildName
    , owner : Evergreen.V316.Id.Id Evergreen.V316.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V316.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V316.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V316.Call.CallId
    | ConnectedToCall
        Evergreen.V316.Call.CallId
        { sessionId : Evergreen.V316.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V316.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V316.Call.RemoteCallData
    , currentlyViewing : Maybe ( Evergreen.V316.Id.AnyGuildOrDmId, Evergreen.V316.Id.ThreadRoute )
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameSwedishStatus
    = WordSpellingGameSwedishStatus_NotLoaded
    | WordSpellingGameSwedishStatus_Loading
    | WordSpellingGameSwedishStatus_Error Effect.Http.Error
    | WordSpellingGameSwedishStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V316.Id.Id Evergreen.V316.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V316.Id.Id Evergreen.V316.Id.UserId
    , name : Evergreen.V316.ChannelName.ChannelName
    , description : Evergreen.V316.ChannelDescription.ChannelDescription
    , messages : Evergreen.V316.IdArray.IdArray Evergreen.V316.Id.ChannelMessageId (Evergreen.V316.Message.MessageState Evergreen.V316.Id.ChannelMessageId (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId))
    , visibleMessages : Evergreen.V316.VisibleMessages.VisibleMessages Evergreen.V316.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) (Evergreen.V316.Thread.LastTypedAt Evergreen.V316.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) Evergreen.V316.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V316.Drawing.Drawing (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) Evergreen.V316.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V316.Id.Id Evergreen.V316.Id.UserId
    , name : Evergreen.V316.GuildName.GuildName
    , icon : Maybe Evergreen.V316.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V316.MembersAndOwner.MembersAndOwner
            (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V316.SecretId.SecretId Evergreen.V316.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V316.Id.Id Evergreen.V316.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V316.ChannelName.ChannelName
    , description : Evergreen.V316.ChannelDescription.ChannelDescription
    , messages : Evergreen.V316.IdArray.IdArray Evergreen.V316.Id.ChannelMessageId (Evergreen.V316.Message.MessageState Evergreen.V316.Id.ChannelMessageId (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId))
    , visibleMessages : Evergreen.V316.VisibleMessages.VisibleMessages Evergreen.V316.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Evergreen.V316.Thread.LastTypedAt Evergreen.V316.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) Evergreen.V316.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V316.Drawing.Drawing (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V316.GuildName.GuildName
    , icon : Maybe Evergreen.V316.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V316.MembersAndOwner.MembersAndOwner
            (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V316.Id.Id Evergreen.V316.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V316.Id.Id Evergreen.V316.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V316.NonemptyDict.NonemptyDict (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) Evergreen.V316.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V316.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V316.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V316.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V316.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V316.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V316.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V316.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V316.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V316.SessionIdHash.SessionIdHash (Evergreen.V316.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V316.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V316.SessionIdHash.SessionIdHash Evergreen.V316.UserSession.UserSession
    , wordSpellingGameSwedish : WordSpellingGameSwedishStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) Evergreen.V316.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId) Evergreen.V316.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V316.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V316.SessionIdHash.SessionIdHash Evergreen.V316.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V316.TextEditor.LocalState
    , calls : Evergreen.V316.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V316.Id.Id Evergreen.V316.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V316.Id.Id Evergreen.V316.Id.UserId
    , name : Evergreen.V316.ChannelName.ChannelName
    , description : Evergreen.V316.ChannelDescription.ChannelDescription
    , messages : Evergreen.V316.IdArray.IdArray Evergreen.V316.Id.ChannelMessageId (Evergreen.V316.Message.Message Evergreen.V316.Id.ChannelMessageId (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) (Evergreen.V316.Thread.LastTypedAt Evergreen.V316.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) Evergreen.V316.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V316.Drawing.Drawing (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) Evergreen.V316.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V316.Id.Id Evergreen.V316.Id.UserId
    , name : Evergreen.V316.GuildName.GuildName
    , icon : Maybe Evergreen.V316.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V316.MembersAndOwner.MembersAndOwner
            (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V316.SecretId.SecretId Evergreen.V316.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V316.Id.Id Evergreen.V316.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V316.ChannelName.ChannelName
    , description : Evergreen.V316.ChannelDescription.ChannelDescription
    , messages : Evergreen.V316.IdArray.IdArray Evergreen.V316.Id.ChannelMessageId (Evergreen.V316.Message.Message Evergreen.V316.Id.ChannelMessageId (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Evergreen.V316.Thread.LastTypedAt Evergreen.V316.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V316.OneToOne.OneToOne (Evergreen.V316.Discord.Id Evergreen.V316.Discord.MessageId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) Evergreen.V316.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V316.Drawing.Drawing (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V316.GuildName.GuildName
    , icon : Maybe Evergreen.V316.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V316.MembersAndOwner.MembersAndOwner
            (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V316.Id.Id Evergreen.V316.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V316.Id.Id Evergreen.V316.Id.CustomEmojiId)
    }
