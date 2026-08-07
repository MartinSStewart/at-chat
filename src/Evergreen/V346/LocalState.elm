module Evergreen.V346.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V346.Call
import Evergreen.V346.ChannelDescription
import Evergreen.V346.ChannelName
import Evergreen.V346.Cloudflare
import Evergreen.V346.Discord
import Evergreen.V346.DiscordUserData
import Evergreen.V346.DmChannel
import Evergreen.V346.DmChannelId
import Evergreen.V346.Drawing
import Evergreen.V346.FileStatus
import Evergreen.V346.Game
import Evergreen.V346.GuildName
import Evergreen.V346.Id
import Evergreen.V346.IdArray
import Evergreen.V346.Log
import Evergreen.V346.MembersAndOwner
import Evergreen.V346.Message
import Evergreen.V346.MessageArray
import Evergreen.V346.NonemptyDict
import Evergreen.V346.OneToOne
import Evergreen.V346.Pagination
import Evergreen.V346.Postmark
import Evergreen.V346.SecretId
import Evergreen.V346.SessionIdHash
import Evergreen.V346.Slack
import Evergreen.V346.TextEditor
import Evergreen.V346.Thread
import Evergreen.V346.ToBackendLog
import Evergreen.V346.User
import Evergreen.V346.UserSession
import Evergreen.V346.VisibleMessages
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
        Evergreen.V346.NonemptyDict.NonemptyDict
            (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V346.Message.Message Evergreen.V346.Id.ChannelMessageId (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V346.Discord.PartialUser
        , icon : Maybe Evergreen.V346.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V346.Discord.User
        , linkedTo : Evergreen.V346.Id.Id Evergreen.V346.Id.UserId
        , icon : Maybe Evergreen.V346.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V346.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V346.Discord.User
        , linkedTo : Evergreen.V346.Id.Id Evergreen.V346.Id.UserId
        , icon : Maybe Evergreen.V346.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V346.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V346.Message.Message Evergreen.V346.Id.ChannelMessageId (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId))
    , permissionOverwrites : List Evergreen.V346.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V346.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V346.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V346.MembersAndOwner.MembersAndOwner
            (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V346.Discord.Id Evergreen.V346.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V346.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V346.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V346.Id.Id Evergreen.V346.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V346.GuildName.GuildName
    , owner : Evergreen.V346.Id.Id Evergreen.V346.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V346.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V346.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V346.Call.CallId
    | ConnectedToCall
        Evergreen.V346.Call.CallId
        { sessionId : Evergreen.V346.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V346.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V346.Call.RemoteCallData
    , currentlyViewing : Evergreen.V346.UserSession.Viewing
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V346.Id.Id Evergreen.V346.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V346.Id.Id Evergreen.V346.Id.UserId
    , name : Evergreen.V346.ChannelName.ChannelName
    , description : Evergreen.V346.ChannelDescription.ChannelDescription
    , messages : Evergreen.V346.MessageArray.MessageArray Evergreen.V346.Id.ChannelMessageId (Evergreen.V346.Message.Message Evergreen.V346.Id.ChannelMessageId (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId))
    , visibleMessages : Evergreen.V346.VisibleMessages.VisibleMessages Evergreen.V346.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) (Evergreen.V346.Thread.LastTypedAt Evergreen.V346.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) Evergreen.V346.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V346.Drawing.Drawing (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) Evergreen.V346.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V346.Id.Id Evergreen.V346.Id.UserId
    , name : Evergreen.V346.GuildName.GuildName
    , icon : Maybe Evergreen.V346.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V346.MembersAndOwner.MembersAndOwner
            (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V346.SecretId.SecretId Evergreen.V346.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V346.Id.Id Evergreen.V346.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V346.ChannelName.ChannelName
    , description : Evergreen.V346.ChannelDescription.ChannelDescription
    , messages : Evergreen.V346.MessageArray.MessageArray Evergreen.V346.Id.ChannelMessageId (Evergreen.V346.Message.Message Evergreen.V346.Id.ChannelMessageId (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId))
    , visibleMessages : Evergreen.V346.VisibleMessages.VisibleMessages Evergreen.V346.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Thread.LastTypedAt Evergreen.V346.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) Evergreen.V346.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V346.Drawing.Drawing (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId))
    , permissionOverwrites : List Evergreen.V346.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V346.GuildName.GuildName
    , icon : Maybe Evergreen.V346.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V346.MembersAndOwner.MembersAndOwner
            (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V346.Discord.Id Evergreen.V346.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V346.Id.Id Evergreen.V346.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V346.Id.Id Evergreen.V346.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V346.NonemptyDict.NonemptyDict (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) Evergreen.V346.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V346.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V346.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V346.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V346.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V346.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V346.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V346.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V346.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V346.SessionIdHash.SessionIdHash (Evergreen.V346.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V346.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V346.SessionIdHash.SessionIdHash Evergreen.V346.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) Evergreen.V346.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId) Evergreen.V346.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V346.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V346.SessionIdHash.SessionIdHash Evergreen.V346.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V346.TextEditor.LocalState
    , calls : Evergreen.V346.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V346.Id.Id Evergreen.V346.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V346.Id.Id Evergreen.V346.Id.UserId
    , name : Evergreen.V346.ChannelName.ChannelName
    , description : Evergreen.V346.ChannelDescription.ChannelDescription
    , messages : Evergreen.V346.IdArray.IdArray Evergreen.V346.Id.ChannelMessageId (Evergreen.V346.Message.Message Evergreen.V346.Id.ChannelMessageId (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) (Evergreen.V346.Thread.LastTypedAt Evergreen.V346.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) Evergreen.V346.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V346.Drawing.Drawing (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) Evergreen.V346.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V346.Id.Id Evergreen.V346.Id.UserId
    , name : Evergreen.V346.GuildName.GuildName
    , icon : Maybe Evergreen.V346.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V346.MembersAndOwner.MembersAndOwner
            (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V346.SecretId.SecretId Evergreen.V346.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V346.Id.Id Evergreen.V346.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V346.ChannelName.ChannelName
    , description : Evergreen.V346.ChannelDescription.ChannelDescription
    , messages : Evergreen.V346.IdArray.IdArray Evergreen.V346.Id.ChannelMessageId (Evergreen.V346.Message.Message Evergreen.V346.Id.ChannelMessageId (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Thread.LastTypedAt Evergreen.V346.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V346.OneToOne.OneToOne (Evergreen.V346.Discord.Id Evergreen.V346.Discord.MessageId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) Evergreen.V346.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V346.Drawing.Drawing (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId))
    , permissionOverwrites : List Evergreen.V346.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V346.GuildName.GuildName
    , icon : Maybe Evergreen.V346.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V346.MembersAndOwner.MembersAndOwner
            (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V346.Discord.Id Evergreen.V346.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V346.Id.Id Evergreen.V346.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V346.Id.Id Evergreen.V346.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId
    , messages : List Evergreen.V346.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V346.Discord.Message
    , threads : List DiscordThreadReload
    }
