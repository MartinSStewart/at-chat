module Evergreen.V345.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V345.Call
import Evergreen.V345.ChannelDescription
import Evergreen.V345.ChannelName
import Evergreen.V345.Cloudflare
import Evergreen.V345.Discord
import Evergreen.V345.DiscordUserData
import Evergreen.V345.DmChannel
import Evergreen.V345.DmChannelId
import Evergreen.V345.Drawing
import Evergreen.V345.FileStatus
import Evergreen.V345.Game
import Evergreen.V345.GuildName
import Evergreen.V345.Id
import Evergreen.V345.IdArray
import Evergreen.V345.Log
import Evergreen.V345.MembersAndOwner
import Evergreen.V345.Message
import Evergreen.V345.MessageArray
import Evergreen.V345.NonemptyDict
import Evergreen.V345.OneToOne
import Evergreen.V345.Pagination
import Evergreen.V345.Postmark
import Evergreen.V345.SecretId
import Evergreen.V345.SessionIdHash
import Evergreen.V345.Slack
import Evergreen.V345.TextEditor
import Evergreen.V345.Thread
import Evergreen.V345.ToBackendLog
import Evergreen.V345.User
import Evergreen.V345.UserSession
import Evergreen.V345.VisibleMessages
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
        Evergreen.V345.NonemptyDict.NonemptyDict
            (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V345.Message.Message Evergreen.V345.Id.ChannelMessageId (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V345.Discord.PartialUser
        , icon : Maybe Evergreen.V345.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V345.Discord.User
        , linkedTo : Evergreen.V345.Id.Id Evergreen.V345.Id.UserId
        , icon : Maybe Evergreen.V345.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V345.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V345.Discord.User
        , linkedTo : Evergreen.V345.Id.Id Evergreen.V345.Id.UserId
        , icon : Maybe Evergreen.V345.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V345.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V345.Message.Message Evergreen.V345.Id.ChannelMessageId (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId))
    , permissionOverwrites : List Evergreen.V345.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V345.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V345.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V345.MembersAndOwner.MembersAndOwner
            (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V345.Discord.Id Evergreen.V345.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V345.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V345.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V345.Id.Id Evergreen.V345.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V345.GuildName.GuildName
    , owner : Evergreen.V345.Id.Id Evergreen.V345.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V345.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V345.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V345.Call.CallId
    | ConnectedToCall
        Evergreen.V345.Call.CallId
        { sessionId : Evergreen.V345.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V345.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V345.Call.RemoteCallData
    , currentlyViewing : Evergreen.V345.UserSession.Viewing
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V345.Id.Id Evergreen.V345.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V345.Id.Id Evergreen.V345.Id.UserId
    , name : Evergreen.V345.ChannelName.ChannelName
    , description : Evergreen.V345.ChannelDescription.ChannelDescription
    , messages : Evergreen.V345.MessageArray.MessageArray Evergreen.V345.Id.ChannelMessageId (Evergreen.V345.Message.Message Evergreen.V345.Id.ChannelMessageId (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId))
    , visibleMessages : Evergreen.V345.VisibleMessages.VisibleMessages Evergreen.V345.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) (Evergreen.V345.Thread.LastTypedAt Evergreen.V345.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) Evergreen.V345.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V345.Drawing.Drawing (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) Evergreen.V345.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V345.Id.Id Evergreen.V345.Id.UserId
    , name : Evergreen.V345.GuildName.GuildName
    , icon : Maybe Evergreen.V345.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V345.MembersAndOwner.MembersAndOwner
            (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V345.SecretId.SecretId Evergreen.V345.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V345.Id.Id Evergreen.V345.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V345.ChannelName.ChannelName
    , description : Evergreen.V345.ChannelDescription.ChannelDescription
    , messages : Evergreen.V345.MessageArray.MessageArray Evergreen.V345.Id.ChannelMessageId (Evergreen.V345.Message.Message Evergreen.V345.Id.ChannelMessageId (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId))
    , visibleMessages : Evergreen.V345.VisibleMessages.VisibleMessages Evergreen.V345.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Thread.LastTypedAt Evergreen.V345.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) Evergreen.V345.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V345.Drawing.Drawing (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId))
    , permissionOverwrites : List Evergreen.V345.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V345.GuildName.GuildName
    , icon : Maybe Evergreen.V345.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V345.MembersAndOwner.MembersAndOwner
            (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V345.Discord.Id Evergreen.V345.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V345.Id.Id Evergreen.V345.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V345.Id.Id Evergreen.V345.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V345.NonemptyDict.NonemptyDict (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) Evergreen.V345.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V345.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V345.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V345.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V345.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V345.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V345.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V345.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V345.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V345.SessionIdHash.SessionIdHash (Evergreen.V345.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V345.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V345.SessionIdHash.SessionIdHash Evergreen.V345.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) Evergreen.V345.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId) Evergreen.V345.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V345.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V345.SessionIdHash.SessionIdHash Evergreen.V345.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V345.TextEditor.LocalState
    , calls : Evergreen.V345.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V345.Id.Id Evergreen.V345.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V345.Id.Id Evergreen.V345.Id.UserId
    , name : Evergreen.V345.ChannelName.ChannelName
    , description : Evergreen.V345.ChannelDescription.ChannelDescription
    , messages : Evergreen.V345.IdArray.IdArray Evergreen.V345.Id.ChannelMessageId (Evergreen.V345.Message.Message Evergreen.V345.Id.ChannelMessageId (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) (Evergreen.V345.Thread.LastTypedAt Evergreen.V345.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) Evergreen.V345.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V345.Drawing.Drawing (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) Evergreen.V345.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V345.Id.Id Evergreen.V345.Id.UserId
    , name : Evergreen.V345.GuildName.GuildName
    , icon : Maybe Evergreen.V345.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V345.MembersAndOwner.MembersAndOwner
            (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V345.SecretId.SecretId Evergreen.V345.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V345.Id.Id Evergreen.V345.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V345.ChannelName.ChannelName
    , description : Evergreen.V345.ChannelDescription.ChannelDescription
    , messages : Evergreen.V345.IdArray.IdArray Evergreen.V345.Id.ChannelMessageId (Evergreen.V345.Message.Message Evergreen.V345.Id.ChannelMessageId (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Thread.LastTypedAt Evergreen.V345.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V345.OneToOne.OneToOne (Evergreen.V345.Discord.Id Evergreen.V345.Discord.MessageId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) Evergreen.V345.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V345.Drawing.Drawing (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId))
    , permissionOverwrites : List Evergreen.V345.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V345.GuildName.GuildName
    , icon : Maybe Evergreen.V345.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V345.MembersAndOwner.MembersAndOwner
            (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V345.Discord.Id Evergreen.V345.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V345.Id.Id Evergreen.V345.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V345.Id.Id Evergreen.V345.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId
    , messages : List Evergreen.V345.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V345.Discord.Message
    , threads : List DiscordThreadReload
    }
