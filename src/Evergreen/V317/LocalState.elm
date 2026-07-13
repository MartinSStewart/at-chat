module Evergreen.V317.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V317.Call
import Evergreen.V317.ChannelDescription
import Evergreen.V317.ChannelName
import Evergreen.V317.Cloudflare
import Evergreen.V317.Discord
import Evergreen.V317.DiscordUserData
import Evergreen.V317.DmChannel
import Evergreen.V317.DmChannelId
import Evergreen.V317.Drawing
import Evergreen.V317.FileStatus
import Evergreen.V317.Game
import Evergreen.V317.GuildName
import Evergreen.V317.Id
import Evergreen.V317.IdArray
import Evergreen.V317.Log
import Evergreen.V317.MembersAndOwner
import Evergreen.V317.Message
import Evergreen.V317.NonemptyDict
import Evergreen.V317.OneToOne
import Evergreen.V317.Pagination
import Evergreen.V317.Postmark
import Evergreen.V317.SecretId
import Evergreen.V317.SessionIdHash
import Evergreen.V317.Slack
import Evergreen.V317.TextEditor
import Evergreen.V317.Thread
import Evergreen.V317.ToBackendLog
import Evergreen.V317.User
import Evergreen.V317.UserSession
import Evergreen.V317.VisibleMessages
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
        Evergreen.V317.NonemptyDict.NonemptyDict
            (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V317.Message.Message Evergreen.V317.Id.ChannelMessageId (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V317.Discord.PartialUser
        , icon : Maybe Evergreen.V317.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V317.Discord.User
        , linkedTo : Evergreen.V317.Id.Id Evergreen.V317.Id.UserId
        , icon : Maybe Evergreen.V317.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V317.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V317.Discord.User
        , linkedTo : Evergreen.V317.Id.Id Evergreen.V317.Id.UserId
        , icon : Maybe Evergreen.V317.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V317.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V317.Message.Message Evergreen.V317.Id.ChannelMessageId (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V317.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V317.MembersAndOwner.MembersAndOwner
            (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V317.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V317.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V317.Id.Id Evergreen.V317.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V317.GuildName.GuildName
    , owner : Evergreen.V317.Id.Id Evergreen.V317.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V317.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V317.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V317.Call.CallId
    | ConnectedToCall
        Evergreen.V317.Call.CallId
        { sessionId : Evergreen.V317.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V317.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V317.Call.RemoteCallData
    , currentlyViewing : Maybe ( Evergreen.V317.Id.AnyGuildOrDmId, Evergreen.V317.Id.ThreadRoute )
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameSwedishStatus
    = WordSpellingGameSwedishStatus_NotLoaded
    | WordSpellingGameSwedishStatus_Loading
    | WordSpellingGameSwedishStatus_Error Effect.Http.Error
    | WordSpellingGameSwedishStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V317.Id.Id Evergreen.V317.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V317.Id.Id Evergreen.V317.Id.UserId
    , name : Evergreen.V317.ChannelName.ChannelName
    , description : Evergreen.V317.ChannelDescription.ChannelDescription
    , messages : Evergreen.V317.IdArray.IdArray Evergreen.V317.Id.ChannelMessageId (Evergreen.V317.Message.MessageState Evergreen.V317.Id.ChannelMessageId (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId))
    , visibleMessages : Evergreen.V317.VisibleMessages.VisibleMessages Evergreen.V317.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) (Evergreen.V317.Thread.LastTypedAt Evergreen.V317.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) Evergreen.V317.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V317.Drawing.Drawing (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) Evergreen.V317.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V317.Id.Id Evergreen.V317.Id.UserId
    , name : Evergreen.V317.GuildName.GuildName
    , icon : Maybe Evergreen.V317.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V317.MembersAndOwner.MembersAndOwner
            (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V317.SecretId.SecretId Evergreen.V317.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V317.Id.Id Evergreen.V317.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V317.ChannelName.ChannelName
    , description : Evergreen.V317.ChannelDescription.ChannelDescription
    , messages : Evergreen.V317.IdArray.IdArray Evergreen.V317.Id.ChannelMessageId (Evergreen.V317.Message.MessageState Evergreen.V317.Id.ChannelMessageId (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId))
    , visibleMessages : Evergreen.V317.VisibleMessages.VisibleMessages Evergreen.V317.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Evergreen.V317.Thread.LastTypedAt Evergreen.V317.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) Evergreen.V317.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V317.Drawing.Drawing (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V317.GuildName.GuildName
    , icon : Maybe Evergreen.V317.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V317.MembersAndOwner.MembersAndOwner
            (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V317.Id.Id Evergreen.V317.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V317.Id.Id Evergreen.V317.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V317.NonemptyDict.NonemptyDict (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) Evergreen.V317.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V317.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V317.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V317.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V317.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V317.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V317.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V317.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V317.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V317.SessionIdHash.SessionIdHash (Evergreen.V317.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V317.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V317.SessionIdHash.SessionIdHash Evergreen.V317.UserSession.UserSession
    , wordSpellingGameSwedish : WordSpellingGameSwedishStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) Evergreen.V317.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId) Evergreen.V317.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V317.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V317.SessionIdHash.SessionIdHash Evergreen.V317.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V317.TextEditor.LocalState
    , calls : Evergreen.V317.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V317.Id.Id Evergreen.V317.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V317.Id.Id Evergreen.V317.Id.UserId
    , name : Evergreen.V317.ChannelName.ChannelName
    , description : Evergreen.V317.ChannelDescription.ChannelDescription
    , messages : Evergreen.V317.IdArray.IdArray Evergreen.V317.Id.ChannelMessageId (Evergreen.V317.Message.Message Evergreen.V317.Id.ChannelMessageId (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) (Evergreen.V317.Thread.LastTypedAt Evergreen.V317.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) Evergreen.V317.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V317.Drawing.Drawing (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) Evergreen.V317.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V317.Id.Id Evergreen.V317.Id.UserId
    , name : Evergreen.V317.GuildName.GuildName
    , icon : Maybe Evergreen.V317.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V317.MembersAndOwner.MembersAndOwner
            (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V317.SecretId.SecretId Evergreen.V317.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V317.Id.Id Evergreen.V317.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V317.ChannelName.ChannelName
    , description : Evergreen.V317.ChannelDescription.ChannelDescription
    , messages : Evergreen.V317.IdArray.IdArray Evergreen.V317.Id.ChannelMessageId (Evergreen.V317.Message.Message Evergreen.V317.Id.ChannelMessageId (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Evergreen.V317.Thread.LastTypedAt Evergreen.V317.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V317.OneToOne.OneToOne (Evergreen.V317.Discord.Id Evergreen.V317.Discord.MessageId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) Evergreen.V317.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V317.Drawing.Drawing (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V317.GuildName.GuildName
    , icon : Maybe Evergreen.V317.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V317.MembersAndOwner.MembersAndOwner
            (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V317.Id.Id Evergreen.V317.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V317.Id.Id Evergreen.V317.Id.CustomEmojiId)
    }
