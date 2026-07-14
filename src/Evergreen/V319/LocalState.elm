module Evergreen.V319.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V319.Call
import Evergreen.V319.ChannelDescription
import Evergreen.V319.ChannelName
import Evergreen.V319.Cloudflare
import Evergreen.V319.Discord
import Evergreen.V319.DiscordUserData
import Evergreen.V319.DmChannel
import Evergreen.V319.DmChannelId
import Evergreen.V319.Drawing
import Evergreen.V319.FileStatus
import Evergreen.V319.Game
import Evergreen.V319.GuildName
import Evergreen.V319.Id
import Evergreen.V319.IdArray
import Evergreen.V319.Log
import Evergreen.V319.MembersAndOwner
import Evergreen.V319.Message
import Evergreen.V319.NonemptyDict
import Evergreen.V319.OneToOne
import Evergreen.V319.Pagination
import Evergreen.V319.Postmark
import Evergreen.V319.SecretId
import Evergreen.V319.SessionIdHash
import Evergreen.V319.Slack
import Evergreen.V319.TextEditor
import Evergreen.V319.Thread
import Evergreen.V319.ToBackendLog
import Evergreen.V319.User
import Evergreen.V319.UserSession
import Evergreen.V319.VisibleMessages
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
        Evergreen.V319.NonemptyDict.NonemptyDict
            (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V319.Message.Message Evergreen.V319.Id.ChannelMessageId (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V319.Discord.PartialUser
        , icon : Maybe Evergreen.V319.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V319.Discord.User
        , linkedTo : Evergreen.V319.Id.Id Evergreen.V319.Id.UserId
        , icon : Maybe Evergreen.V319.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V319.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V319.Discord.User
        , linkedTo : Evergreen.V319.Id.Id Evergreen.V319.Id.UserId
        , icon : Maybe Evergreen.V319.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V319.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V319.Message.Message Evergreen.V319.Id.ChannelMessageId (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V319.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V319.MembersAndOwner.MembersAndOwner
            (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V319.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V319.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V319.Id.Id Evergreen.V319.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V319.GuildName.GuildName
    , owner : Evergreen.V319.Id.Id Evergreen.V319.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V319.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V319.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V319.Call.CallId
    | ConnectedToCall
        Evergreen.V319.Call.CallId
        { sessionId : Evergreen.V319.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V319.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V319.Call.RemoteCallData
    , currentlyViewing : Maybe ( Evergreen.V319.Id.AnyGuildOrDmId, Evergreen.V319.Id.ThreadRoute )
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameSwedishStatus
    = WordSpellingGameSwedishStatus_NotLoaded
    | WordSpellingGameSwedishStatus_Loading
    | WordSpellingGameSwedishStatus_Error Effect.Http.Error
    | WordSpellingGameSwedishStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V319.Id.Id Evergreen.V319.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V319.Id.Id Evergreen.V319.Id.UserId
    , name : Evergreen.V319.ChannelName.ChannelName
    , description : Evergreen.V319.ChannelDescription.ChannelDescription
    , messages : Evergreen.V319.IdArray.IdArray Evergreen.V319.Id.ChannelMessageId (Evergreen.V319.Message.MessageState Evergreen.V319.Id.ChannelMessageId (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId))
    , visibleMessages : Evergreen.V319.VisibleMessages.VisibleMessages Evergreen.V319.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) (Evergreen.V319.Thread.LastTypedAt Evergreen.V319.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) Evergreen.V319.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V319.Drawing.Drawing (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) Evergreen.V319.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V319.Id.Id Evergreen.V319.Id.UserId
    , name : Evergreen.V319.GuildName.GuildName
    , icon : Maybe Evergreen.V319.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V319.MembersAndOwner.MembersAndOwner
            (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V319.SecretId.SecretId Evergreen.V319.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V319.Id.Id Evergreen.V319.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V319.ChannelName.ChannelName
    , description : Evergreen.V319.ChannelDescription.ChannelDescription
    , messages : Evergreen.V319.IdArray.IdArray Evergreen.V319.Id.ChannelMessageId (Evergreen.V319.Message.MessageState Evergreen.V319.Id.ChannelMessageId (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId))
    , visibleMessages : Evergreen.V319.VisibleMessages.VisibleMessages Evergreen.V319.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Evergreen.V319.Thread.LastTypedAt Evergreen.V319.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) Evergreen.V319.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V319.Drawing.Drawing (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V319.GuildName.GuildName
    , icon : Maybe Evergreen.V319.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V319.MembersAndOwner.MembersAndOwner
            (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V319.Id.Id Evergreen.V319.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V319.Id.Id Evergreen.V319.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V319.NonemptyDict.NonemptyDict (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) Evergreen.V319.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V319.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V319.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V319.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V319.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V319.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V319.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V319.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V319.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V319.SessionIdHash.SessionIdHash (Evergreen.V319.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V319.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V319.SessionIdHash.SessionIdHash Evergreen.V319.UserSession.UserSession
    , wordSpellingGameSwedish : WordSpellingGameSwedishStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) Evergreen.V319.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId) Evergreen.V319.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V319.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V319.SessionIdHash.SessionIdHash Evergreen.V319.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V319.TextEditor.LocalState
    , calls : Evergreen.V319.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V319.Id.Id Evergreen.V319.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V319.Id.Id Evergreen.V319.Id.UserId
    , name : Evergreen.V319.ChannelName.ChannelName
    , description : Evergreen.V319.ChannelDescription.ChannelDescription
    , messages : Evergreen.V319.IdArray.IdArray Evergreen.V319.Id.ChannelMessageId (Evergreen.V319.Message.Message Evergreen.V319.Id.ChannelMessageId (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) (Evergreen.V319.Thread.LastTypedAt Evergreen.V319.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) Evergreen.V319.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V319.Drawing.Drawing (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) Evergreen.V319.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V319.Id.Id Evergreen.V319.Id.UserId
    , name : Evergreen.V319.GuildName.GuildName
    , icon : Maybe Evergreen.V319.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V319.MembersAndOwner.MembersAndOwner
            (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V319.SecretId.SecretId Evergreen.V319.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V319.Id.Id Evergreen.V319.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V319.ChannelName.ChannelName
    , description : Evergreen.V319.ChannelDescription.ChannelDescription
    , messages : Evergreen.V319.IdArray.IdArray Evergreen.V319.Id.ChannelMessageId (Evergreen.V319.Message.Message Evergreen.V319.Id.ChannelMessageId (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Evergreen.V319.Thread.LastTypedAt Evergreen.V319.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V319.OneToOne.OneToOne (Evergreen.V319.Discord.Id Evergreen.V319.Discord.MessageId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) Evergreen.V319.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V319.Drawing.Drawing (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V319.GuildName.GuildName
    , icon : Maybe Evergreen.V319.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V319.MembersAndOwner.MembersAndOwner
            (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V319.Id.Id Evergreen.V319.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V319.Id.Id Evergreen.V319.Id.CustomEmojiId)
    }
