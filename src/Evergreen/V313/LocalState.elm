module Evergreen.V313.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V313.Call
import Evergreen.V313.ChannelDescription
import Evergreen.V313.ChannelName
import Evergreen.V313.Cloudflare
import Evergreen.V313.Discord
import Evergreen.V313.DiscordUserData
import Evergreen.V313.DmChannel
import Evergreen.V313.DmChannelId
import Evergreen.V313.Drawing
import Evergreen.V313.FileStatus
import Evergreen.V313.Game
import Evergreen.V313.GuildName
import Evergreen.V313.Id
import Evergreen.V313.IdArray
import Evergreen.V313.Log
import Evergreen.V313.MembersAndOwner
import Evergreen.V313.Message
import Evergreen.V313.NonemptyDict
import Evergreen.V313.OneToOne
import Evergreen.V313.Pagination
import Evergreen.V313.Postmark
import Evergreen.V313.SecretId
import Evergreen.V313.SessionIdHash
import Evergreen.V313.Slack
import Evergreen.V313.TextEditor
import Evergreen.V313.Thread
import Evergreen.V313.ToBackendLog
import Evergreen.V313.User
import Evergreen.V313.UserSession
import Evergreen.V313.VisibleMessages
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
        Evergreen.V313.NonemptyDict.NonemptyDict
            (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V313.Message.Message Evergreen.V313.Id.ChannelMessageId (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V313.Discord.PartialUser
        , icon : Maybe Evergreen.V313.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V313.Discord.User
        , linkedTo : Evergreen.V313.Id.Id Evergreen.V313.Id.UserId
        , icon : Maybe Evergreen.V313.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V313.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V313.Discord.User
        , linkedTo : Evergreen.V313.Id.Id Evergreen.V313.Id.UserId
        , icon : Maybe Evergreen.V313.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V313.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V313.Message.Message Evergreen.V313.Id.ChannelMessageId (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V313.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V313.MembersAndOwner.MembersAndOwner
            (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V313.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V313.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V313.Id.Id Evergreen.V313.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V313.GuildName.GuildName
    , owner : Evergreen.V313.Id.Id Evergreen.V313.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V313.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V313.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V313.Call.CallId
    | ConnectedToCall
        Evergreen.V313.Call.CallId
        { sessionId : Evergreen.V313.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V313.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V313.Call.RemoteCallData
    , currentlyViewing : Maybe ( Evergreen.V313.Id.AnyGuildOrDmId, Evergreen.V313.Id.ThreadRoute )
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameSwedishStatus
    = WordSpellingGameSwedishStatus_NotLoaded
    | WordSpellingGameSwedishStatus_Loading
    | WordSpellingGameSwedishStatus_Error Effect.Http.Error
    | WordSpellingGameSwedishStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V313.Id.Id Evergreen.V313.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V313.Id.Id Evergreen.V313.Id.UserId
    , name : Evergreen.V313.ChannelName.ChannelName
    , description : Evergreen.V313.ChannelDescription.ChannelDescription
    , messages : Evergreen.V313.IdArray.IdArray Evergreen.V313.Id.ChannelMessageId (Evergreen.V313.Message.MessageState Evergreen.V313.Id.ChannelMessageId (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId))
    , visibleMessages : Evergreen.V313.VisibleMessages.VisibleMessages Evergreen.V313.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) (Evergreen.V313.Thread.LastTypedAt Evergreen.V313.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) Evergreen.V313.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V313.Drawing.Drawing (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) Evergreen.V313.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V313.Id.Id Evergreen.V313.Id.UserId
    , name : Evergreen.V313.GuildName.GuildName
    , icon : Maybe Evergreen.V313.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V313.MembersAndOwner.MembersAndOwner
            (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V313.SecretId.SecretId Evergreen.V313.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V313.Id.Id Evergreen.V313.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V313.ChannelName.ChannelName
    , description : Evergreen.V313.ChannelDescription.ChannelDescription
    , messages : Evergreen.V313.IdArray.IdArray Evergreen.V313.Id.ChannelMessageId (Evergreen.V313.Message.MessageState Evergreen.V313.Id.ChannelMessageId (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId))
    , visibleMessages : Evergreen.V313.VisibleMessages.VisibleMessages Evergreen.V313.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Evergreen.V313.Thread.LastTypedAt Evergreen.V313.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) Evergreen.V313.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V313.Drawing.Drawing (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V313.GuildName.GuildName
    , icon : Maybe Evergreen.V313.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V313.MembersAndOwner.MembersAndOwner
            (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V313.Id.Id Evergreen.V313.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V313.Id.Id Evergreen.V313.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V313.NonemptyDict.NonemptyDict (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) Evergreen.V313.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V313.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V313.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V313.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V313.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V313.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V313.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V313.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V313.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V313.SessionIdHash.SessionIdHash (Evergreen.V313.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V313.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V313.SessionIdHash.SessionIdHash Evergreen.V313.UserSession.UserSession
    , wordSpellingGameSwedish : WordSpellingGameSwedishStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) Evergreen.V313.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId) Evergreen.V313.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V313.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V313.SessionIdHash.SessionIdHash Evergreen.V313.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V313.TextEditor.LocalState
    , calls : Evergreen.V313.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V313.Id.Id Evergreen.V313.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V313.Id.Id Evergreen.V313.Id.UserId
    , name : Evergreen.V313.ChannelName.ChannelName
    , description : Evergreen.V313.ChannelDescription.ChannelDescription
    , messages : Evergreen.V313.IdArray.IdArray Evergreen.V313.Id.ChannelMessageId (Evergreen.V313.Message.Message Evergreen.V313.Id.ChannelMessageId (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) (Evergreen.V313.Thread.LastTypedAt Evergreen.V313.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) Evergreen.V313.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V313.Drawing.Drawing (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) Evergreen.V313.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V313.Id.Id Evergreen.V313.Id.UserId
    , name : Evergreen.V313.GuildName.GuildName
    , icon : Maybe Evergreen.V313.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V313.MembersAndOwner.MembersAndOwner
            (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V313.SecretId.SecretId Evergreen.V313.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V313.Id.Id Evergreen.V313.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V313.ChannelName.ChannelName
    , description : Evergreen.V313.ChannelDescription.ChannelDescription
    , messages : Evergreen.V313.IdArray.IdArray Evergreen.V313.Id.ChannelMessageId (Evergreen.V313.Message.Message Evergreen.V313.Id.ChannelMessageId (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Evergreen.V313.Thread.LastTypedAt Evergreen.V313.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V313.OneToOne.OneToOne (Evergreen.V313.Discord.Id Evergreen.V313.Discord.MessageId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) Evergreen.V313.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V313.Drawing.Drawing (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V313.GuildName.GuildName
    , icon : Maybe Evergreen.V313.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V313.MembersAndOwner.MembersAndOwner
            (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V313.Id.Id Evergreen.V313.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V313.Id.Id Evergreen.V313.Id.CustomEmojiId)
    }
