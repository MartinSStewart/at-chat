module Evergreen.V323.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V323.Call
import Evergreen.V323.ChannelDescription
import Evergreen.V323.ChannelName
import Evergreen.V323.Cloudflare
import Evergreen.V323.Discord
import Evergreen.V323.DiscordUserData
import Evergreen.V323.DmChannel
import Evergreen.V323.DmChannelId
import Evergreen.V323.Drawing
import Evergreen.V323.FileStatus
import Evergreen.V323.Game
import Evergreen.V323.GuildName
import Evergreen.V323.Id
import Evergreen.V323.IdArray
import Evergreen.V323.Log
import Evergreen.V323.MembersAndOwner
import Evergreen.V323.Message
import Evergreen.V323.NonemptyDict
import Evergreen.V323.OneToOne
import Evergreen.V323.Pagination
import Evergreen.V323.Postmark
import Evergreen.V323.SecretId
import Evergreen.V323.SessionIdHash
import Evergreen.V323.Slack
import Evergreen.V323.TextEditor
import Evergreen.V323.Thread
import Evergreen.V323.ToBackendLog
import Evergreen.V323.User
import Evergreen.V323.UserSession
import Evergreen.V323.VisibleMessages
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
        Evergreen.V323.NonemptyDict.NonemptyDict
            (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V323.Message.Message Evergreen.V323.Id.ChannelMessageId (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V323.Discord.PartialUser
        , icon : Maybe Evergreen.V323.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V323.Discord.User
        , linkedTo : Evergreen.V323.Id.Id Evergreen.V323.Id.UserId
        , icon : Maybe Evergreen.V323.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V323.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V323.Discord.User
        , linkedTo : Evergreen.V323.Id.Id Evergreen.V323.Id.UserId
        , icon : Maybe Evergreen.V323.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V323.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V323.Message.Message Evergreen.V323.Id.ChannelMessageId (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V323.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V323.MembersAndOwner.MembersAndOwner
            (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V323.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V323.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V323.Id.Id Evergreen.V323.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V323.GuildName.GuildName
    , owner : Evergreen.V323.Id.Id Evergreen.V323.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V323.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V323.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V323.Call.CallId
    | ConnectedToCall
        Evergreen.V323.Call.CallId
        { sessionId : Evergreen.V323.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V323.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V323.Call.RemoteCallData
    , currentlyViewing : Maybe ( Evergreen.V323.Id.AnyGuildOrDmId, Evergreen.V323.Id.ThreadRoute )
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameSwedishStatus
    = WordSpellingGameSwedishStatus_NotLoaded
    | WordSpellingGameSwedishStatus_Loading
    | WordSpellingGameSwedishStatus_Error Effect.Http.Error
    | WordSpellingGameSwedishStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V323.Id.Id Evergreen.V323.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V323.Id.Id Evergreen.V323.Id.UserId
    , name : Evergreen.V323.ChannelName.ChannelName
    , description : Evergreen.V323.ChannelDescription.ChannelDescription
    , messages : Evergreen.V323.IdArray.IdArray Evergreen.V323.Id.ChannelMessageId (Evergreen.V323.Message.MessageState Evergreen.V323.Id.ChannelMessageId (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId))
    , visibleMessages : Evergreen.V323.VisibleMessages.VisibleMessages Evergreen.V323.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) (Evergreen.V323.Thread.LastTypedAt Evergreen.V323.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) Evergreen.V323.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V323.Drawing.Drawing (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) Evergreen.V323.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V323.Id.Id Evergreen.V323.Id.UserId
    , name : Evergreen.V323.GuildName.GuildName
    , icon : Maybe Evergreen.V323.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V323.MembersAndOwner.MembersAndOwner
            (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V323.SecretId.SecretId Evergreen.V323.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V323.Id.Id Evergreen.V323.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V323.ChannelName.ChannelName
    , description : Evergreen.V323.ChannelDescription.ChannelDescription
    , messages : Evergreen.V323.IdArray.IdArray Evergreen.V323.Id.ChannelMessageId (Evergreen.V323.Message.MessageState Evergreen.V323.Id.ChannelMessageId (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId))
    , visibleMessages : Evergreen.V323.VisibleMessages.VisibleMessages Evergreen.V323.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Evergreen.V323.Thread.LastTypedAt Evergreen.V323.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) Evergreen.V323.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V323.Drawing.Drawing (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V323.GuildName.GuildName
    , icon : Maybe Evergreen.V323.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V323.MembersAndOwner.MembersAndOwner
            (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V323.Id.Id Evergreen.V323.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V323.Id.Id Evergreen.V323.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V323.NonemptyDict.NonemptyDict (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) Evergreen.V323.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V323.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V323.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V323.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V323.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V323.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V323.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V323.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V323.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V323.SessionIdHash.SessionIdHash (Evergreen.V323.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V323.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V323.SessionIdHash.SessionIdHash Evergreen.V323.UserSession.UserSession
    , wordSpellingGameSwedish : WordSpellingGameSwedishStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) Evergreen.V323.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId) Evergreen.V323.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V323.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V323.SessionIdHash.SessionIdHash Evergreen.V323.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V323.TextEditor.LocalState
    , calls : Evergreen.V323.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V323.Id.Id Evergreen.V323.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V323.Id.Id Evergreen.V323.Id.UserId
    , name : Evergreen.V323.ChannelName.ChannelName
    , description : Evergreen.V323.ChannelDescription.ChannelDescription
    , messages : Evergreen.V323.IdArray.IdArray Evergreen.V323.Id.ChannelMessageId (Evergreen.V323.Message.Message Evergreen.V323.Id.ChannelMessageId (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) (Evergreen.V323.Thread.LastTypedAt Evergreen.V323.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) Evergreen.V323.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V323.Drawing.Drawing (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) Evergreen.V323.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V323.Id.Id Evergreen.V323.Id.UserId
    , name : Evergreen.V323.GuildName.GuildName
    , icon : Maybe Evergreen.V323.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V323.MembersAndOwner.MembersAndOwner
            (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V323.SecretId.SecretId Evergreen.V323.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V323.Id.Id Evergreen.V323.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V323.ChannelName.ChannelName
    , description : Evergreen.V323.ChannelDescription.ChannelDescription
    , messages : Evergreen.V323.IdArray.IdArray Evergreen.V323.Id.ChannelMessageId (Evergreen.V323.Message.Message Evergreen.V323.Id.ChannelMessageId (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Evergreen.V323.Thread.LastTypedAt Evergreen.V323.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V323.OneToOne.OneToOne (Evergreen.V323.Discord.Id Evergreen.V323.Discord.MessageId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) Evergreen.V323.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V323.Drawing.Drawing (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V323.GuildName.GuildName
    , icon : Maybe Evergreen.V323.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V323.MembersAndOwner.MembersAndOwner
            (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V323.Id.Id Evergreen.V323.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V323.Id.Id Evergreen.V323.Id.CustomEmojiId)
    }
