module Evergreen.V347.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V347.Call
import Evergreen.V347.ChannelDescription
import Evergreen.V347.ChannelName
import Evergreen.V347.Cloudflare
import Evergreen.V347.Discord
import Evergreen.V347.DiscordUserData
import Evergreen.V347.DmChannel
import Evergreen.V347.DmChannelId
import Evergreen.V347.Drawing
import Evergreen.V347.FileStatus
import Evergreen.V347.Game
import Evergreen.V347.GuildName
import Evergreen.V347.Id
import Evergreen.V347.IdArray
import Evergreen.V347.Log
import Evergreen.V347.MembersAndOwner
import Evergreen.V347.Message
import Evergreen.V347.MessageArray
import Evergreen.V347.NonemptyDict
import Evergreen.V347.OneToOne
import Evergreen.V347.Pagination
import Evergreen.V347.Postmark
import Evergreen.V347.SecretId
import Evergreen.V347.SessionIdHash
import Evergreen.V347.Slack
import Evergreen.V347.TextEditor
import Evergreen.V347.Thread
import Evergreen.V347.ToBackendLog
import Evergreen.V347.User
import Evergreen.V347.UserSession
import Evergreen.V347.VisibleMessages
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
        Evergreen.V347.NonemptyDict.NonemptyDict
            (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V347.Message.Message Evergreen.V347.Id.ChannelMessageId (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V347.Discord.PartialUser
        , icon : Maybe Evergreen.V347.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V347.Discord.User
        , linkedTo : Evergreen.V347.Id.Id Evergreen.V347.Id.UserId
        , icon : Maybe Evergreen.V347.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V347.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V347.Discord.User
        , linkedTo : Evergreen.V347.Id.Id Evergreen.V347.Id.UserId
        , icon : Maybe Evergreen.V347.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V347.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V347.Message.Message Evergreen.V347.Id.ChannelMessageId (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId))
    , permissionOverwrites : List Evergreen.V347.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V347.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V347.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V347.MembersAndOwner.MembersAndOwner
            (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V347.Discord.Id Evergreen.V347.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V347.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V347.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V347.Id.Id Evergreen.V347.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V347.GuildName.GuildName
    , owner : Evergreen.V347.Id.Id Evergreen.V347.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V347.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V347.Discord.Id Evergreen.V347.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId) (Evergreen.V347.Discord.Id Evergreen.V347.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V347.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V347.Call.CallId
    | ConnectedToCall
        Evergreen.V347.Call.CallId
        { sessionId : Evergreen.V347.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V347.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V347.Call.RemoteCallData
    , currentlyViewing : Evergreen.V347.UserSession.Viewing
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V347.Id.Id Evergreen.V347.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V347.Id.Id Evergreen.V347.Id.UserId
    , name : Evergreen.V347.ChannelName.ChannelName
    , description : Evergreen.V347.ChannelDescription.ChannelDescription
    , messages : Evergreen.V347.MessageArray.MessageArray Evergreen.V347.Id.ChannelMessageId (Evergreen.V347.Message.Message Evergreen.V347.Id.ChannelMessageId (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId))
    , visibleMessages : Evergreen.V347.VisibleMessages.VisibleMessages Evergreen.V347.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId) (Evergreen.V347.Thread.LastTypedAt Evergreen.V347.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId) Evergreen.V347.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V347.Drawing.Drawing (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId) Evergreen.V347.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V347.Id.Id Evergreen.V347.Id.UserId
    , name : Evergreen.V347.GuildName.GuildName
    , icon : Maybe Evergreen.V347.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V347.MembersAndOwner.MembersAndOwner
            (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V347.SecretId.SecretId Evergreen.V347.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V347.Id.Id Evergreen.V347.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V347.ChannelName.ChannelName
    , description : Evergreen.V347.ChannelDescription.ChannelDescription
    , messages : Evergreen.V347.MessageArray.MessageArray Evergreen.V347.Id.ChannelMessageId (Evergreen.V347.Message.Message Evergreen.V347.Id.ChannelMessageId (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId))
    , visibleMessages : Evergreen.V347.VisibleMessages.VisibleMessages Evergreen.V347.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) (Evergreen.V347.Thread.LastTypedAt Evergreen.V347.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId) Evergreen.V347.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V347.Drawing.Drawing (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId))
    , permissionOverwrites : List Evergreen.V347.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V347.GuildName.GuildName
    , icon : Maybe Evergreen.V347.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V347.MembersAndOwner.MembersAndOwner
            (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V347.Discord.Id Evergreen.V347.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V347.Id.Id Evergreen.V347.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V347.Id.Id Evergreen.V347.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V347.NonemptyDict.NonemptyDict (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId) Evergreen.V347.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V347.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V347.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V347.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V347.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V347.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V347.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V347.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V347.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V347.SessionIdHash.SessionIdHash (Evergreen.V347.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V347.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V347.SessionIdHash.SessionIdHash Evergreen.V347.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId) Evergreen.V347.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.PrivateChannelId) Evergreen.V347.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V347.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V347.SessionIdHash.SessionIdHash Evergreen.V347.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V347.TextEditor.LocalState
    , calls : Evergreen.V347.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V347.Id.Id Evergreen.V347.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V347.Id.Id Evergreen.V347.Id.UserId
    , name : Evergreen.V347.ChannelName.ChannelName
    , description : Evergreen.V347.ChannelDescription.ChannelDescription
    , messages : Evergreen.V347.IdArray.IdArray Evergreen.V347.Id.ChannelMessageId (Evergreen.V347.Message.Message Evergreen.V347.Id.ChannelMessageId (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId) (Evergreen.V347.Thread.LastTypedAt Evergreen.V347.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId) Evergreen.V347.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V347.Drawing.Drawing (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId) Evergreen.V347.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V347.Id.Id Evergreen.V347.Id.UserId
    , name : Evergreen.V347.GuildName.GuildName
    , icon : Maybe Evergreen.V347.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V347.MembersAndOwner.MembersAndOwner
            (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V347.SecretId.SecretId Evergreen.V347.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V347.Id.Id Evergreen.V347.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V347.ChannelName.ChannelName
    , description : Evergreen.V347.ChannelDescription.ChannelDescription
    , messages : Evergreen.V347.IdArray.IdArray Evergreen.V347.Id.ChannelMessageId (Evergreen.V347.Message.Message Evergreen.V347.Id.ChannelMessageId (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) (Evergreen.V347.Thread.LastTypedAt Evergreen.V347.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V347.OneToOne.OneToOne (Evergreen.V347.Discord.Id Evergreen.V347.Discord.MessageId) (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId) Evergreen.V347.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V347.Drawing.Drawing (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId))
    , permissionOverwrites : List Evergreen.V347.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V347.GuildName.GuildName
    , icon : Maybe Evergreen.V347.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V347.MembersAndOwner.MembersAndOwner
            (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V347.Discord.Id Evergreen.V347.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V347.Id.Id Evergreen.V347.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V347.Id.Id Evergreen.V347.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V347.Discord.Id Evergreen.V347.Discord.ChannelId
    , messages : List Evergreen.V347.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V347.Discord.Message
    , threads : List DiscordThreadReload
    }
