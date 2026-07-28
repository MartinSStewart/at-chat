module Evergreen.V338.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V338.Call
import Evergreen.V338.ChannelDescription
import Evergreen.V338.ChannelName
import Evergreen.V338.Cloudflare
import Evergreen.V338.Discord
import Evergreen.V338.DiscordUserData
import Evergreen.V338.DmChannel
import Evergreen.V338.DmChannelId
import Evergreen.V338.Drawing
import Evergreen.V338.FileStatus
import Evergreen.V338.Game
import Evergreen.V338.GuildName
import Evergreen.V338.Id
import Evergreen.V338.IdArray
import Evergreen.V338.Log
import Evergreen.V338.MembersAndOwner
import Evergreen.V338.Message
import Evergreen.V338.MessageArray
import Evergreen.V338.NonemptyDict
import Evergreen.V338.OneToOne
import Evergreen.V338.Pagination
import Evergreen.V338.Postmark
import Evergreen.V338.SecretId
import Evergreen.V338.SessionIdHash
import Evergreen.V338.Slack
import Evergreen.V338.TextEditor
import Evergreen.V338.Thread
import Evergreen.V338.ToBackendLog
import Evergreen.V338.User
import Evergreen.V338.UserSession
import Evergreen.V338.VisibleMessages
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
        Evergreen.V338.NonemptyDict.NonemptyDict
            (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V338.Message.Message Evergreen.V338.Id.ChannelMessageId (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V338.Discord.PartialUser
        , icon : Maybe Evergreen.V338.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V338.Discord.User
        , linkedTo : Evergreen.V338.Id.Id Evergreen.V338.Id.UserId
        , icon : Maybe Evergreen.V338.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V338.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V338.Discord.User
        , linkedTo : Evergreen.V338.Id.Id Evergreen.V338.Id.UserId
        , icon : Maybe Evergreen.V338.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V338.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V338.Message.Message Evergreen.V338.Id.ChannelMessageId (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId))
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V338.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V338.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V338.MembersAndOwner.MembersAndOwner
            (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V338.Discord.Id Evergreen.V338.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V338.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V338.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V338.Id.Id Evergreen.V338.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V338.GuildName.GuildName
    , owner : Evergreen.V338.Id.Id Evergreen.V338.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V338.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V338.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V338.Call.CallId
    | ConnectedToCall
        Evergreen.V338.Call.CallId
        { sessionId : Evergreen.V338.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V338.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V338.Call.RemoteCallData
    , currentlyViewing : Evergreen.V338.UserSession.Viewing
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V338.Id.Id Evergreen.V338.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V338.Id.Id Evergreen.V338.Id.UserId
    , name : Evergreen.V338.ChannelName.ChannelName
    , description : Evergreen.V338.ChannelDescription.ChannelDescription
    , messages : Evergreen.V338.MessageArray.MessageArray Evergreen.V338.Id.ChannelMessageId (Evergreen.V338.Message.Message Evergreen.V338.Id.ChannelMessageId (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId))
    , visibleMessages : Evergreen.V338.VisibleMessages.VisibleMessages Evergreen.V338.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) (Evergreen.V338.Thread.LastTypedAt Evergreen.V338.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) Evergreen.V338.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V338.Drawing.Drawing (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) Evergreen.V338.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V338.Id.Id Evergreen.V338.Id.UserId
    , name : Evergreen.V338.GuildName.GuildName
    , icon : Maybe Evergreen.V338.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V338.MembersAndOwner.MembersAndOwner
            (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V338.SecretId.SecretId Evergreen.V338.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V338.Id.Id Evergreen.V338.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V338.ChannelName.ChannelName
    , description : Evergreen.V338.ChannelDescription.ChannelDescription
    , messages : Evergreen.V338.MessageArray.MessageArray Evergreen.V338.Id.ChannelMessageId (Evergreen.V338.Message.Message Evergreen.V338.Id.ChannelMessageId (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId))
    , visibleMessages : Evergreen.V338.VisibleMessages.VisibleMessages Evergreen.V338.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Thread.LastTypedAt Evergreen.V338.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) Evergreen.V338.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V338.Drawing.Drawing (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId))
    , permissionOverwrites : List Evergreen.V338.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V338.GuildName.GuildName
    , icon : Maybe Evergreen.V338.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V338.MembersAndOwner.MembersAndOwner
            (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V338.Discord.Id Evergreen.V338.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V338.Id.Id Evergreen.V338.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V338.Id.Id Evergreen.V338.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V338.NonemptyDict.NonemptyDict (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) Evergreen.V338.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V338.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V338.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V338.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V338.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V338.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V338.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V338.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V338.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V338.SessionIdHash.SessionIdHash (Evergreen.V338.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V338.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V338.SessionIdHash.SessionIdHash Evergreen.V338.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) Evergreen.V338.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId) Evergreen.V338.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V338.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V338.SessionIdHash.SessionIdHash Evergreen.V338.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V338.TextEditor.LocalState
    , calls : Evergreen.V338.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V338.Id.Id Evergreen.V338.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V338.Id.Id Evergreen.V338.Id.UserId
    , name : Evergreen.V338.ChannelName.ChannelName
    , description : Evergreen.V338.ChannelDescription.ChannelDescription
    , messages : Evergreen.V338.IdArray.IdArray Evergreen.V338.Id.ChannelMessageId (Evergreen.V338.Message.Message Evergreen.V338.Id.ChannelMessageId (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) (Evergreen.V338.Thread.LastTypedAt Evergreen.V338.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) Evergreen.V338.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V338.Drawing.Drawing (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) Evergreen.V338.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V338.Id.Id Evergreen.V338.Id.UserId
    , name : Evergreen.V338.GuildName.GuildName
    , icon : Maybe Evergreen.V338.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V338.MembersAndOwner.MembersAndOwner
            (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V338.SecretId.SecretId Evergreen.V338.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V338.Id.Id Evergreen.V338.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V338.ChannelName.ChannelName
    , description : Evergreen.V338.ChannelDescription.ChannelDescription
    , messages : Evergreen.V338.IdArray.IdArray Evergreen.V338.Id.ChannelMessageId (Evergreen.V338.Message.Message Evergreen.V338.Id.ChannelMessageId (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Thread.LastTypedAt Evergreen.V338.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V338.OneToOne.OneToOne (Evergreen.V338.Discord.Id Evergreen.V338.Discord.MessageId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) Evergreen.V338.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V338.Drawing.Drawing (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId))
    , permissionOverwrites : List Evergreen.V338.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V338.GuildName.GuildName
    , icon : Maybe Evergreen.V338.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V338.MembersAndOwner.MembersAndOwner
            (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V338.Discord.Id Evergreen.V338.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V338.Id.Id Evergreen.V338.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V338.Id.Id Evergreen.V338.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.RoleId) DiscordRole
    }
