module Evergreen.V326.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V326.Call
import Evergreen.V326.ChannelDescription
import Evergreen.V326.ChannelName
import Evergreen.V326.Cloudflare
import Evergreen.V326.Discord
import Evergreen.V326.DiscordUserData
import Evergreen.V326.DmChannel
import Evergreen.V326.DmChannelId
import Evergreen.V326.Drawing
import Evergreen.V326.FileStatus
import Evergreen.V326.Game
import Evergreen.V326.GuildName
import Evergreen.V326.Id
import Evergreen.V326.IdArray
import Evergreen.V326.Log
import Evergreen.V326.MembersAndOwner
import Evergreen.V326.Message
import Evergreen.V326.NonemptyDict
import Evergreen.V326.OneToOne
import Evergreen.V326.Pagination
import Evergreen.V326.Postmark
import Evergreen.V326.SecretId
import Evergreen.V326.SessionIdHash
import Evergreen.V326.Slack
import Evergreen.V326.TextEditor
import Evergreen.V326.Thread
import Evergreen.V326.ToBackendLog
import Evergreen.V326.User
import Evergreen.V326.UserSession
import Evergreen.V326.VisibleMessages
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
        Evergreen.V326.NonemptyDict.NonemptyDict
            (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V326.Message.Message Evergreen.V326.Id.ChannelMessageId (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V326.Discord.PartialUser
        , icon : Maybe Evergreen.V326.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V326.Discord.User
        , linkedTo : Evergreen.V326.Id.Id Evergreen.V326.Id.UserId
        , icon : Maybe Evergreen.V326.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V326.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V326.Discord.User
        , linkedTo : Evergreen.V326.Id.Id Evergreen.V326.Id.UserId
        , icon : Maybe Evergreen.V326.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V326.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V326.Message.Message Evergreen.V326.Id.ChannelMessageId (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V326.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V326.MembersAndOwner.MembersAndOwner
            (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V326.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V326.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V326.Id.Id Evergreen.V326.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V326.GuildName.GuildName
    , owner : Evergreen.V326.Id.Id Evergreen.V326.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V326.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V326.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V326.Call.CallId
    | ConnectedToCall
        Evergreen.V326.Call.CallId
        { sessionId : Evergreen.V326.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V326.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V326.Call.RemoteCallData
    , currentlyViewing : Maybe ( Evergreen.V326.Id.AnyGuildOrDmId, Evergreen.V326.Id.ThreadRoute )
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V326.Id.Id Evergreen.V326.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V326.Id.Id Evergreen.V326.Id.UserId
    , name : Evergreen.V326.ChannelName.ChannelName
    , description : Evergreen.V326.ChannelDescription.ChannelDescription
    , messages : Evergreen.V326.IdArray.IdArray Evergreen.V326.Id.ChannelMessageId (Evergreen.V326.Message.MessageState Evergreen.V326.Id.ChannelMessageId (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId))
    , visibleMessages : Evergreen.V326.VisibleMessages.VisibleMessages Evergreen.V326.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) (Evergreen.V326.Thread.LastTypedAt Evergreen.V326.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) Evergreen.V326.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V326.Drawing.Drawing (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) Evergreen.V326.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V326.Id.Id Evergreen.V326.Id.UserId
    , name : Evergreen.V326.GuildName.GuildName
    , icon : Maybe Evergreen.V326.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V326.MembersAndOwner.MembersAndOwner
            (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V326.SecretId.SecretId Evergreen.V326.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V326.Id.Id Evergreen.V326.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V326.ChannelName.ChannelName
    , description : Evergreen.V326.ChannelDescription.ChannelDescription
    , messages : Evergreen.V326.IdArray.IdArray Evergreen.V326.Id.ChannelMessageId (Evergreen.V326.Message.MessageState Evergreen.V326.Id.ChannelMessageId (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId))
    , visibleMessages : Evergreen.V326.VisibleMessages.VisibleMessages Evergreen.V326.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Evergreen.V326.Thread.LastTypedAt Evergreen.V326.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) Evergreen.V326.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V326.Drawing.Drawing (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V326.GuildName.GuildName
    , icon : Maybe Evergreen.V326.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V326.MembersAndOwner.MembersAndOwner
            (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V326.Id.Id Evergreen.V326.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V326.Id.Id Evergreen.V326.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V326.NonemptyDict.NonemptyDict (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) Evergreen.V326.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V326.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V326.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V326.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V326.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V326.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V326.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V326.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V326.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V326.SessionIdHash.SessionIdHash (Evergreen.V326.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V326.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V326.SessionIdHash.SessionIdHash Evergreen.V326.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) Evergreen.V326.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId) Evergreen.V326.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V326.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V326.SessionIdHash.SessionIdHash Evergreen.V326.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V326.TextEditor.LocalState
    , calls : Evergreen.V326.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V326.Id.Id Evergreen.V326.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V326.Id.Id Evergreen.V326.Id.UserId
    , name : Evergreen.V326.ChannelName.ChannelName
    , description : Evergreen.V326.ChannelDescription.ChannelDescription
    , messages : Evergreen.V326.IdArray.IdArray Evergreen.V326.Id.ChannelMessageId (Evergreen.V326.Message.Message Evergreen.V326.Id.ChannelMessageId (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) (Evergreen.V326.Thread.LastTypedAt Evergreen.V326.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) Evergreen.V326.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V326.Drawing.Drawing (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) Evergreen.V326.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V326.Id.Id Evergreen.V326.Id.UserId
    , name : Evergreen.V326.GuildName.GuildName
    , icon : Maybe Evergreen.V326.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V326.MembersAndOwner.MembersAndOwner
            (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V326.SecretId.SecretId Evergreen.V326.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V326.Id.Id Evergreen.V326.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V326.ChannelName.ChannelName
    , description : Evergreen.V326.ChannelDescription.ChannelDescription
    , messages : Evergreen.V326.IdArray.IdArray Evergreen.V326.Id.ChannelMessageId (Evergreen.V326.Message.Message Evergreen.V326.Id.ChannelMessageId (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Evergreen.V326.Thread.LastTypedAt Evergreen.V326.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V326.OneToOne.OneToOne (Evergreen.V326.Discord.Id Evergreen.V326.Discord.MessageId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) Evergreen.V326.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V326.Drawing.Drawing (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V326.GuildName.GuildName
    , icon : Maybe Evergreen.V326.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V326.MembersAndOwner.MembersAndOwner
            (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V326.Id.Id Evergreen.V326.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V326.Id.Id Evergreen.V326.Id.CustomEmojiId)
    }
