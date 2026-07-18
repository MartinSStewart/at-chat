module Evergreen.V328.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V328.Call
import Evergreen.V328.ChannelDescription
import Evergreen.V328.ChannelName
import Evergreen.V328.Cloudflare
import Evergreen.V328.Discord
import Evergreen.V328.DiscordUserData
import Evergreen.V328.DmChannel
import Evergreen.V328.DmChannelId
import Evergreen.V328.Drawing
import Evergreen.V328.FileStatus
import Evergreen.V328.Game
import Evergreen.V328.GuildName
import Evergreen.V328.Id
import Evergreen.V328.IdArray
import Evergreen.V328.Log
import Evergreen.V328.MembersAndOwner
import Evergreen.V328.Message
import Evergreen.V328.NonemptyDict
import Evergreen.V328.OneToOne
import Evergreen.V328.Pagination
import Evergreen.V328.Postmark
import Evergreen.V328.SecretId
import Evergreen.V328.SessionIdHash
import Evergreen.V328.Slack
import Evergreen.V328.TextEditor
import Evergreen.V328.Thread
import Evergreen.V328.ToBackendLog
import Evergreen.V328.User
import Evergreen.V328.UserSession
import Evergreen.V328.VisibleMessages
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
        Evergreen.V328.NonemptyDict.NonemptyDict
            (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V328.Message.Message Evergreen.V328.Id.ChannelMessageId (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V328.Discord.PartialUser
        , icon : Maybe Evergreen.V328.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V328.Discord.User
        , linkedTo : Evergreen.V328.Id.Id Evergreen.V328.Id.UserId
        , icon : Maybe Evergreen.V328.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V328.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V328.Discord.User
        , linkedTo : Evergreen.V328.Id.Id Evergreen.V328.Id.UserId
        , icon : Maybe Evergreen.V328.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V328.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V328.Message.Message Evergreen.V328.Id.ChannelMessageId (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V328.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V328.Discord.Id Evergreen.V328.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V328.MembersAndOwner.MembersAndOwner
            (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V328.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V328.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V328.Id.Id Evergreen.V328.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V328.GuildName.GuildName
    , owner : Evergreen.V328.Id.Id Evergreen.V328.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V328.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V328.Discord.Id Evergreen.V328.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V328.Discord.Id Evergreen.V328.Discord.GuildId) (Evergreen.V328.Discord.Id Evergreen.V328.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V328.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V328.Call.CallId
    | ConnectedToCall
        Evergreen.V328.Call.CallId
        { sessionId : Evergreen.V328.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V328.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V328.Call.RemoteCallData
    , currentlyViewing : Evergreen.V328.UserSession.Viewing
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V328.Id.Id Evergreen.V328.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V328.Id.Id Evergreen.V328.Id.UserId
    , name : Evergreen.V328.ChannelName.ChannelName
    , description : Evergreen.V328.ChannelDescription.ChannelDescription
    , messages : Evergreen.V328.IdArray.IdArray Evergreen.V328.Id.ChannelMessageId (Evergreen.V328.Message.MessageState Evergreen.V328.Id.ChannelMessageId (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId))
    , visibleMessages : Evergreen.V328.VisibleMessages.VisibleMessages Evergreen.V328.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId) (Evergreen.V328.Thread.LastTypedAt Evergreen.V328.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId) Evergreen.V328.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V328.Drawing.Drawing (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId) Evergreen.V328.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V328.Id.Id Evergreen.V328.Id.UserId
    , name : Evergreen.V328.GuildName.GuildName
    , icon : Maybe Evergreen.V328.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V328.MembersAndOwner.MembersAndOwner
            (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V328.SecretId.SecretId Evergreen.V328.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V328.Id.Id Evergreen.V328.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V328.ChannelName.ChannelName
    , description : Evergreen.V328.ChannelDescription.ChannelDescription
    , messages : Evergreen.V328.IdArray.IdArray Evergreen.V328.Id.ChannelMessageId (Evergreen.V328.Message.MessageState Evergreen.V328.Id.ChannelMessageId (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId))
    , visibleMessages : Evergreen.V328.VisibleMessages.VisibleMessages Evergreen.V328.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) (Evergreen.V328.Thread.LastTypedAt Evergreen.V328.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId) Evergreen.V328.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V328.Drawing.Drawing (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V328.GuildName.GuildName
    , icon : Maybe Evergreen.V328.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V328.Discord.Id Evergreen.V328.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V328.MembersAndOwner.MembersAndOwner
            (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V328.Id.Id Evergreen.V328.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V328.Id.Id Evergreen.V328.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V328.NonemptyDict.NonemptyDict (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId) Evergreen.V328.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V328.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V328.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V328.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V328.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V328.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V328.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V328.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V328.Discord.Id Evergreen.V328.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V328.Discord.Id Evergreen.V328.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V328.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V328.SessionIdHash.SessionIdHash (Evergreen.V328.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V328.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V328.SessionIdHash.SessionIdHash Evergreen.V328.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V328.Discord.Id Evergreen.V328.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId) Evergreen.V328.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V328.Discord.Id Evergreen.V328.Discord.PrivateChannelId) Evergreen.V328.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V328.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V328.SessionIdHash.SessionIdHash Evergreen.V328.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V328.TextEditor.LocalState
    , calls : Evergreen.V328.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V328.Id.Id Evergreen.V328.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V328.Id.Id Evergreen.V328.Id.UserId
    , name : Evergreen.V328.ChannelName.ChannelName
    , description : Evergreen.V328.ChannelDescription.ChannelDescription
    , messages : Evergreen.V328.IdArray.IdArray Evergreen.V328.Id.ChannelMessageId (Evergreen.V328.Message.Message Evergreen.V328.Id.ChannelMessageId (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId) (Evergreen.V328.Thread.LastTypedAt Evergreen.V328.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId) Evergreen.V328.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V328.Drawing.Drawing (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId) Evergreen.V328.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V328.Id.Id Evergreen.V328.Id.UserId
    , name : Evergreen.V328.GuildName.GuildName
    , icon : Maybe Evergreen.V328.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V328.MembersAndOwner.MembersAndOwner
            (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V328.SecretId.SecretId Evergreen.V328.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V328.Id.Id Evergreen.V328.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V328.ChannelName.ChannelName
    , description : Evergreen.V328.ChannelDescription.ChannelDescription
    , messages : Evergreen.V328.IdArray.IdArray Evergreen.V328.Id.ChannelMessageId (Evergreen.V328.Message.Message Evergreen.V328.Id.ChannelMessageId (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) (Evergreen.V328.Thread.LastTypedAt Evergreen.V328.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V328.OneToOne.OneToOne (Evergreen.V328.Discord.Id Evergreen.V328.Discord.MessageId) (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId) Evergreen.V328.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V328.Drawing.Drawing (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V328.GuildName.GuildName
    , icon : Maybe Evergreen.V328.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V328.Discord.Id Evergreen.V328.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V328.MembersAndOwner.MembersAndOwner
            (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V328.Id.Id Evergreen.V328.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V328.Id.Id Evergreen.V328.Id.CustomEmojiId)
    }
