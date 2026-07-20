module Evergreen.V330.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V330.Call
import Evergreen.V330.ChannelDescription
import Evergreen.V330.ChannelName
import Evergreen.V330.Cloudflare
import Evergreen.V330.Discord
import Evergreen.V330.DiscordUserData
import Evergreen.V330.DmChannel
import Evergreen.V330.DmChannelId
import Evergreen.V330.Drawing
import Evergreen.V330.FileStatus
import Evergreen.V330.Game
import Evergreen.V330.GuildName
import Evergreen.V330.Id
import Evergreen.V330.IdArray
import Evergreen.V330.Log
import Evergreen.V330.MembersAndOwner
import Evergreen.V330.Message
import Evergreen.V330.NonemptyDict
import Evergreen.V330.OneToOne
import Evergreen.V330.Pagination
import Evergreen.V330.Postmark
import Evergreen.V330.SecretId
import Evergreen.V330.SessionIdHash
import Evergreen.V330.Slack
import Evergreen.V330.TextEditor
import Evergreen.V330.Thread
import Evergreen.V330.ToBackendLog
import Evergreen.V330.User
import Evergreen.V330.UserSession
import Evergreen.V330.VisibleMessages
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
        Evergreen.V330.NonemptyDict.NonemptyDict
            (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V330.Message.Message Evergreen.V330.Id.ChannelMessageId (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V330.Discord.PartialUser
        , icon : Maybe Evergreen.V330.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V330.Discord.User
        , linkedTo : Evergreen.V330.Id.Id Evergreen.V330.Id.UserId
        , icon : Maybe Evergreen.V330.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V330.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V330.Discord.User
        , linkedTo : Evergreen.V330.Id.Id Evergreen.V330.Id.UserId
        , icon : Maybe Evergreen.V330.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V330.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V330.Message.Message Evergreen.V330.Id.ChannelMessageId (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V330.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V330.MembersAndOwner.MembersAndOwner
            (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V330.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V330.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V330.Id.Id Evergreen.V330.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V330.GuildName.GuildName
    , owner : Evergreen.V330.Id.Id Evergreen.V330.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V330.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V330.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V330.Call.CallId
    | ConnectedToCall
        Evergreen.V330.Call.CallId
        { sessionId : Evergreen.V330.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V330.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V330.Call.RemoteCallData
    , currentlyViewing : Evergreen.V330.UserSession.Viewing
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V330.Id.Id Evergreen.V330.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V330.Id.Id Evergreen.V330.Id.UserId
    , name : Evergreen.V330.ChannelName.ChannelName
    , description : Evergreen.V330.ChannelDescription.ChannelDescription
    , messages : Evergreen.V330.IdArray.IdArray Evergreen.V330.Id.ChannelMessageId (Evergreen.V330.Message.MessageState Evergreen.V330.Id.ChannelMessageId (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId))
    , visibleMessages : Evergreen.V330.VisibleMessages.VisibleMessages Evergreen.V330.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) (Evergreen.V330.Thread.LastTypedAt Evergreen.V330.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) Evergreen.V330.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V330.Drawing.Drawing (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) Evergreen.V330.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V330.Id.Id Evergreen.V330.Id.UserId
    , name : Evergreen.V330.GuildName.GuildName
    , icon : Maybe Evergreen.V330.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V330.MembersAndOwner.MembersAndOwner
            (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V330.SecretId.SecretId Evergreen.V330.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V330.Id.Id Evergreen.V330.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V330.ChannelName.ChannelName
    , description : Evergreen.V330.ChannelDescription.ChannelDescription
    , messages : Evergreen.V330.IdArray.IdArray Evergreen.V330.Id.ChannelMessageId (Evergreen.V330.Message.MessageState Evergreen.V330.Id.ChannelMessageId (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId))
    , visibleMessages : Evergreen.V330.VisibleMessages.VisibleMessages Evergreen.V330.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Thread.LastTypedAt Evergreen.V330.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) Evergreen.V330.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V330.Drawing.Drawing (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V330.GuildName.GuildName
    , icon : Maybe Evergreen.V330.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V330.MembersAndOwner.MembersAndOwner
            (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V330.Id.Id Evergreen.V330.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V330.Id.Id Evergreen.V330.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V330.NonemptyDict.NonemptyDict (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) Evergreen.V330.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V330.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V330.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V330.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V330.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V330.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V330.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V330.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V330.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V330.SessionIdHash.SessionIdHash (Evergreen.V330.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V330.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V330.SessionIdHash.SessionIdHash Evergreen.V330.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) Evergreen.V330.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId) Evergreen.V330.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V330.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V330.SessionIdHash.SessionIdHash Evergreen.V330.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V330.TextEditor.LocalState
    , calls : Evergreen.V330.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V330.Id.Id Evergreen.V330.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V330.Id.Id Evergreen.V330.Id.UserId
    , name : Evergreen.V330.ChannelName.ChannelName
    , description : Evergreen.V330.ChannelDescription.ChannelDescription
    , messages : Evergreen.V330.IdArray.IdArray Evergreen.V330.Id.ChannelMessageId (Evergreen.V330.Message.Message Evergreen.V330.Id.ChannelMessageId (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) (Evergreen.V330.Thread.LastTypedAt Evergreen.V330.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) Evergreen.V330.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V330.Drawing.Drawing (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) Evergreen.V330.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V330.Id.Id Evergreen.V330.Id.UserId
    , name : Evergreen.V330.GuildName.GuildName
    , icon : Maybe Evergreen.V330.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V330.MembersAndOwner.MembersAndOwner
            (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V330.SecretId.SecretId Evergreen.V330.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V330.Id.Id Evergreen.V330.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V330.ChannelName.ChannelName
    , description : Evergreen.V330.ChannelDescription.ChannelDescription
    , messages : Evergreen.V330.IdArray.IdArray Evergreen.V330.Id.ChannelMessageId (Evergreen.V330.Message.Message Evergreen.V330.Id.ChannelMessageId (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Thread.LastTypedAt Evergreen.V330.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V330.OneToOne.OneToOne (Evergreen.V330.Discord.Id Evergreen.V330.Discord.MessageId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) Evergreen.V330.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V330.Drawing.Drawing (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V330.GuildName.GuildName
    , icon : Maybe Evergreen.V330.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V330.MembersAndOwner.MembersAndOwner
            (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V330.Id.Id Evergreen.V330.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V330.Id.Id Evergreen.V330.Id.CustomEmojiId)
    }
