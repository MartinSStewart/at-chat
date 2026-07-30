module Evergreen.V340.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V340.Call
import Evergreen.V340.ChannelDescription
import Evergreen.V340.ChannelName
import Evergreen.V340.Cloudflare
import Evergreen.V340.Discord
import Evergreen.V340.DiscordUserData
import Evergreen.V340.DmChannel
import Evergreen.V340.DmChannelId
import Evergreen.V340.Drawing
import Evergreen.V340.FileStatus
import Evergreen.V340.Game
import Evergreen.V340.GuildName
import Evergreen.V340.Id
import Evergreen.V340.IdArray
import Evergreen.V340.Log
import Evergreen.V340.MembersAndOwner
import Evergreen.V340.Message
import Evergreen.V340.MessageArray
import Evergreen.V340.NonemptyDict
import Evergreen.V340.OneToOne
import Evergreen.V340.Pagination
import Evergreen.V340.Postmark
import Evergreen.V340.SecretId
import Evergreen.V340.SessionIdHash
import Evergreen.V340.Slack
import Evergreen.V340.TextEditor
import Evergreen.V340.Thread
import Evergreen.V340.ToBackendLog
import Evergreen.V340.User
import Evergreen.V340.UserSession
import Evergreen.V340.VisibleMessages
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
        Evergreen.V340.NonemptyDict.NonemptyDict
            (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V340.Message.Message Evergreen.V340.Id.ChannelMessageId (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V340.Discord.PartialUser
        , icon : Maybe Evergreen.V340.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V340.Discord.User
        , linkedTo : Evergreen.V340.Id.Id Evergreen.V340.Id.UserId
        , icon : Maybe Evergreen.V340.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V340.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V340.Discord.User
        , linkedTo : Evergreen.V340.Id.Id Evergreen.V340.Id.UserId
        , icon : Maybe Evergreen.V340.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V340.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V340.Message.Message Evergreen.V340.Id.ChannelMessageId (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId))
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V340.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V340.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V340.MembersAndOwner.MembersAndOwner
            (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V340.Discord.Id Evergreen.V340.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V340.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V340.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V340.Id.Id Evergreen.V340.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V340.GuildName.GuildName
    , owner : Evergreen.V340.Id.Id Evergreen.V340.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V340.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V340.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V340.Call.CallId
    | ConnectedToCall
        Evergreen.V340.Call.CallId
        { sessionId : Evergreen.V340.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V340.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V340.Call.RemoteCallData
    , currentlyViewing : Evergreen.V340.UserSession.Viewing
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V340.Id.Id Evergreen.V340.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V340.Id.Id Evergreen.V340.Id.UserId
    , name : Evergreen.V340.ChannelName.ChannelName
    , description : Evergreen.V340.ChannelDescription.ChannelDescription
    , messages : Evergreen.V340.MessageArray.MessageArray Evergreen.V340.Id.ChannelMessageId (Evergreen.V340.Message.Message Evergreen.V340.Id.ChannelMessageId (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId))
    , visibleMessages : Evergreen.V340.VisibleMessages.VisibleMessages Evergreen.V340.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) (Evergreen.V340.Thread.LastTypedAt Evergreen.V340.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) Evergreen.V340.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V340.Drawing.Drawing (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) Evergreen.V340.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V340.Id.Id Evergreen.V340.Id.UserId
    , name : Evergreen.V340.GuildName.GuildName
    , icon : Maybe Evergreen.V340.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V340.MembersAndOwner.MembersAndOwner
            (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V340.SecretId.SecretId Evergreen.V340.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V340.Id.Id Evergreen.V340.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V340.ChannelName.ChannelName
    , description : Evergreen.V340.ChannelDescription.ChannelDescription
    , messages : Evergreen.V340.MessageArray.MessageArray Evergreen.V340.Id.ChannelMessageId (Evergreen.V340.Message.Message Evergreen.V340.Id.ChannelMessageId (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId))
    , visibleMessages : Evergreen.V340.VisibleMessages.VisibleMessages Evergreen.V340.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Thread.LastTypedAt Evergreen.V340.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) Evergreen.V340.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V340.Drawing.Drawing (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId))
    , permissionOverwrites : List Evergreen.V340.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V340.GuildName.GuildName
    , icon : Maybe Evergreen.V340.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V340.MembersAndOwner.MembersAndOwner
            (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V340.Discord.Id Evergreen.V340.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V340.Id.Id Evergreen.V340.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V340.Id.Id Evergreen.V340.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V340.NonemptyDict.NonemptyDict (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) Evergreen.V340.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V340.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V340.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V340.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V340.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V340.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V340.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V340.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V340.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V340.SessionIdHash.SessionIdHash (Evergreen.V340.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V340.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V340.SessionIdHash.SessionIdHash Evergreen.V340.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) Evergreen.V340.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId) Evergreen.V340.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V340.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V340.SessionIdHash.SessionIdHash Evergreen.V340.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V340.TextEditor.LocalState
    , calls : Evergreen.V340.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V340.Id.Id Evergreen.V340.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V340.Id.Id Evergreen.V340.Id.UserId
    , name : Evergreen.V340.ChannelName.ChannelName
    , description : Evergreen.V340.ChannelDescription.ChannelDescription
    , messages : Evergreen.V340.IdArray.IdArray Evergreen.V340.Id.ChannelMessageId (Evergreen.V340.Message.Message Evergreen.V340.Id.ChannelMessageId (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) (Evergreen.V340.Thread.LastTypedAt Evergreen.V340.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) Evergreen.V340.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V340.Drawing.Drawing (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) Evergreen.V340.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V340.Id.Id Evergreen.V340.Id.UserId
    , name : Evergreen.V340.GuildName.GuildName
    , icon : Maybe Evergreen.V340.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V340.MembersAndOwner.MembersAndOwner
            (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V340.SecretId.SecretId Evergreen.V340.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V340.Id.Id Evergreen.V340.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V340.ChannelName.ChannelName
    , description : Evergreen.V340.ChannelDescription.ChannelDescription
    , messages : Evergreen.V340.IdArray.IdArray Evergreen.V340.Id.ChannelMessageId (Evergreen.V340.Message.Message Evergreen.V340.Id.ChannelMessageId (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Thread.LastTypedAt Evergreen.V340.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V340.OneToOne.OneToOne (Evergreen.V340.Discord.Id Evergreen.V340.Discord.MessageId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) Evergreen.V340.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V340.Drawing.Drawing (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId))
    , permissionOverwrites : List Evergreen.V340.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V340.GuildName.GuildName
    , icon : Maybe Evergreen.V340.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V340.MembersAndOwner.MembersAndOwner
            (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V340.Discord.Id Evergreen.V340.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V340.Id.Id Evergreen.V340.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V340.Id.Id Evergreen.V340.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.RoleId) DiscordRole
    }
