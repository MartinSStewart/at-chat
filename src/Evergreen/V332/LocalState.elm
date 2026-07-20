module Evergreen.V332.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V332.Call
import Evergreen.V332.ChannelDescription
import Evergreen.V332.ChannelName
import Evergreen.V332.Cloudflare
import Evergreen.V332.Discord
import Evergreen.V332.DiscordUserData
import Evergreen.V332.DmChannel
import Evergreen.V332.DmChannelId
import Evergreen.V332.Drawing
import Evergreen.V332.FileStatus
import Evergreen.V332.Game
import Evergreen.V332.GuildName
import Evergreen.V332.Id
import Evergreen.V332.IdArray
import Evergreen.V332.Log
import Evergreen.V332.MembersAndOwner
import Evergreen.V332.Message
import Evergreen.V332.NonemptyDict
import Evergreen.V332.OneToOne
import Evergreen.V332.Pagination
import Evergreen.V332.Postmark
import Evergreen.V332.SecretId
import Evergreen.V332.SessionIdHash
import Evergreen.V332.Slack
import Evergreen.V332.TextEditor
import Evergreen.V332.Thread
import Evergreen.V332.ToBackendLog
import Evergreen.V332.User
import Evergreen.V332.UserSession
import Evergreen.V332.VisibleMessages
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
        Evergreen.V332.NonemptyDict.NonemptyDict
            (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V332.Message.Message Evergreen.V332.Id.ChannelMessageId (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V332.Discord.PartialUser
        , icon : Maybe Evergreen.V332.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V332.Discord.User
        , linkedTo : Evergreen.V332.Id.Id Evergreen.V332.Id.UserId
        , icon : Maybe Evergreen.V332.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V332.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V332.Discord.User
        , linkedTo : Evergreen.V332.Id.Id Evergreen.V332.Id.UserId
        , icon : Maybe Evergreen.V332.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V332.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V332.Message.Message Evergreen.V332.Id.ChannelMessageId (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V332.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V332.MembersAndOwner.MembersAndOwner
            (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V332.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V332.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V332.Id.Id Evergreen.V332.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V332.GuildName.GuildName
    , owner : Evergreen.V332.Id.Id Evergreen.V332.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V332.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V332.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V332.Call.CallId
    | ConnectedToCall
        Evergreen.V332.Call.CallId
        { sessionId : Evergreen.V332.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V332.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V332.Call.RemoteCallData
    , currentlyViewing : Evergreen.V332.UserSession.Viewing
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V332.Id.Id Evergreen.V332.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V332.Id.Id Evergreen.V332.Id.UserId
    , name : Evergreen.V332.ChannelName.ChannelName
    , description : Evergreen.V332.ChannelDescription.ChannelDescription
    , messages : Evergreen.V332.IdArray.IdArray Evergreen.V332.Id.ChannelMessageId (Evergreen.V332.Message.MessageState Evergreen.V332.Id.ChannelMessageId (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId))
    , visibleMessages : Evergreen.V332.VisibleMessages.VisibleMessages Evergreen.V332.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) (Evergreen.V332.Thread.LastTypedAt Evergreen.V332.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) Evergreen.V332.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V332.Drawing.Drawing (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) Evergreen.V332.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V332.Id.Id Evergreen.V332.Id.UserId
    , name : Evergreen.V332.GuildName.GuildName
    , icon : Maybe Evergreen.V332.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V332.MembersAndOwner.MembersAndOwner
            (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V332.SecretId.SecretId Evergreen.V332.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V332.Id.Id Evergreen.V332.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V332.ChannelName.ChannelName
    , description : Evergreen.V332.ChannelDescription.ChannelDescription
    , messages : Evergreen.V332.IdArray.IdArray Evergreen.V332.Id.ChannelMessageId (Evergreen.V332.Message.MessageState Evergreen.V332.Id.ChannelMessageId (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId))
    , visibleMessages : Evergreen.V332.VisibleMessages.VisibleMessages Evergreen.V332.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Thread.LastTypedAt Evergreen.V332.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) Evergreen.V332.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V332.Drawing.Drawing (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V332.GuildName.GuildName
    , icon : Maybe Evergreen.V332.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V332.MembersAndOwner.MembersAndOwner
            (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V332.Id.Id Evergreen.V332.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V332.Id.Id Evergreen.V332.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V332.NonemptyDict.NonemptyDict (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) Evergreen.V332.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V332.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V332.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V332.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V332.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V332.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V332.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V332.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V332.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V332.SessionIdHash.SessionIdHash (Evergreen.V332.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V332.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V332.SessionIdHash.SessionIdHash Evergreen.V332.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) Evergreen.V332.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId) Evergreen.V332.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V332.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V332.SessionIdHash.SessionIdHash Evergreen.V332.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V332.TextEditor.LocalState
    , calls : Evergreen.V332.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V332.Id.Id Evergreen.V332.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V332.Id.Id Evergreen.V332.Id.UserId
    , name : Evergreen.V332.ChannelName.ChannelName
    , description : Evergreen.V332.ChannelDescription.ChannelDescription
    , messages : Evergreen.V332.IdArray.IdArray Evergreen.V332.Id.ChannelMessageId (Evergreen.V332.Message.Message Evergreen.V332.Id.ChannelMessageId (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) (Evergreen.V332.Thread.LastTypedAt Evergreen.V332.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) Evergreen.V332.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V332.Drawing.Drawing (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) Evergreen.V332.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V332.Id.Id Evergreen.V332.Id.UserId
    , name : Evergreen.V332.GuildName.GuildName
    , icon : Maybe Evergreen.V332.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V332.MembersAndOwner.MembersAndOwner
            (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V332.SecretId.SecretId Evergreen.V332.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V332.Id.Id Evergreen.V332.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V332.ChannelName.ChannelName
    , description : Evergreen.V332.ChannelDescription.ChannelDescription
    , messages : Evergreen.V332.IdArray.IdArray Evergreen.V332.Id.ChannelMessageId (Evergreen.V332.Message.Message Evergreen.V332.Id.ChannelMessageId (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Thread.LastTypedAt Evergreen.V332.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V332.OneToOne.OneToOne (Evergreen.V332.Discord.Id Evergreen.V332.Discord.MessageId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) Evergreen.V332.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V332.Drawing.Drawing (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V332.GuildName.GuildName
    , icon : Maybe Evergreen.V332.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V332.MembersAndOwner.MembersAndOwner
            (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V332.Id.Id Evergreen.V332.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V332.Id.Id Evergreen.V332.Id.CustomEmojiId)
    }
