module Evergreen.V343.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V343.Call
import Evergreen.V343.ChannelDescription
import Evergreen.V343.ChannelName
import Evergreen.V343.Cloudflare
import Evergreen.V343.Discord
import Evergreen.V343.DiscordUserData
import Evergreen.V343.DmChannel
import Evergreen.V343.DmChannelId
import Evergreen.V343.Drawing
import Evergreen.V343.FileStatus
import Evergreen.V343.Game
import Evergreen.V343.GuildName
import Evergreen.V343.Id
import Evergreen.V343.IdArray
import Evergreen.V343.Log
import Evergreen.V343.MembersAndOwner
import Evergreen.V343.Message
import Evergreen.V343.MessageArray
import Evergreen.V343.NonemptyDict
import Evergreen.V343.OneToOne
import Evergreen.V343.Pagination
import Evergreen.V343.Postmark
import Evergreen.V343.SecretId
import Evergreen.V343.SessionIdHash
import Evergreen.V343.Slack
import Evergreen.V343.TextEditor
import Evergreen.V343.Thread
import Evergreen.V343.ToBackendLog
import Evergreen.V343.User
import Evergreen.V343.UserSession
import Evergreen.V343.VisibleMessages
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
        Evergreen.V343.NonemptyDict.NonemptyDict
            (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V343.Message.Message Evergreen.V343.Id.ChannelMessageId (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V343.Discord.PartialUser
        , icon : Maybe Evergreen.V343.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V343.Discord.User
        , linkedTo : Evergreen.V343.Id.Id Evergreen.V343.Id.UserId
        , icon : Maybe Evergreen.V343.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V343.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V343.Discord.User
        , linkedTo : Evergreen.V343.Id.Id Evergreen.V343.Id.UserId
        , icon : Maybe Evergreen.V343.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V343.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V343.Message.Message Evergreen.V343.Id.ChannelMessageId (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId))
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V343.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V343.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V343.MembersAndOwner.MembersAndOwner
            (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V343.Discord.Id Evergreen.V343.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V343.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V343.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V343.Id.Id Evergreen.V343.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V343.GuildName.GuildName
    , owner : Evergreen.V343.Id.Id Evergreen.V343.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V343.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V343.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V343.Call.CallId
    | ConnectedToCall
        Evergreen.V343.Call.CallId
        { sessionId : Evergreen.V343.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V343.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V343.Call.RemoteCallData
    , currentlyViewing : Evergreen.V343.UserSession.Viewing
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V343.Id.Id Evergreen.V343.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V343.Id.Id Evergreen.V343.Id.UserId
    , name : Evergreen.V343.ChannelName.ChannelName
    , description : Evergreen.V343.ChannelDescription.ChannelDescription
    , messages : Evergreen.V343.MessageArray.MessageArray Evergreen.V343.Id.ChannelMessageId (Evergreen.V343.Message.Message Evergreen.V343.Id.ChannelMessageId (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId))
    , visibleMessages : Evergreen.V343.VisibleMessages.VisibleMessages Evergreen.V343.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) (Evergreen.V343.Thread.LastTypedAt Evergreen.V343.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) Evergreen.V343.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V343.Drawing.Drawing (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) Evergreen.V343.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V343.Id.Id Evergreen.V343.Id.UserId
    , name : Evergreen.V343.GuildName.GuildName
    , icon : Maybe Evergreen.V343.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V343.MembersAndOwner.MembersAndOwner
            (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V343.SecretId.SecretId Evergreen.V343.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V343.Id.Id Evergreen.V343.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V343.ChannelName.ChannelName
    , description : Evergreen.V343.ChannelDescription.ChannelDescription
    , messages : Evergreen.V343.MessageArray.MessageArray Evergreen.V343.Id.ChannelMessageId (Evergreen.V343.Message.Message Evergreen.V343.Id.ChannelMessageId (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId))
    , visibleMessages : Evergreen.V343.VisibleMessages.VisibleMessages Evergreen.V343.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Thread.LastTypedAt Evergreen.V343.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) Evergreen.V343.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V343.Drawing.Drawing (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId))
    , permissionOverwrites : List Evergreen.V343.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V343.GuildName.GuildName
    , icon : Maybe Evergreen.V343.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V343.MembersAndOwner.MembersAndOwner
            (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V343.Discord.Id Evergreen.V343.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V343.Id.Id Evergreen.V343.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V343.Id.Id Evergreen.V343.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V343.NonemptyDict.NonemptyDict (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) Evergreen.V343.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V343.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V343.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V343.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V343.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V343.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V343.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V343.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V343.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V343.SessionIdHash.SessionIdHash (Evergreen.V343.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V343.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V343.SessionIdHash.SessionIdHash Evergreen.V343.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) Evergreen.V343.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId) Evergreen.V343.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V343.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V343.SessionIdHash.SessionIdHash Evergreen.V343.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V343.TextEditor.LocalState
    , calls : Evergreen.V343.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V343.Id.Id Evergreen.V343.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V343.Id.Id Evergreen.V343.Id.UserId
    , name : Evergreen.V343.ChannelName.ChannelName
    , description : Evergreen.V343.ChannelDescription.ChannelDescription
    , messages : Evergreen.V343.IdArray.IdArray Evergreen.V343.Id.ChannelMessageId (Evergreen.V343.Message.Message Evergreen.V343.Id.ChannelMessageId (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) (Evergreen.V343.Thread.LastTypedAt Evergreen.V343.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) Evergreen.V343.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V343.Drawing.Drawing (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) Evergreen.V343.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V343.Id.Id Evergreen.V343.Id.UserId
    , name : Evergreen.V343.GuildName.GuildName
    , icon : Maybe Evergreen.V343.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V343.MembersAndOwner.MembersAndOwner
            (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V343.SecretId.SecretId Evergreen.V343.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V343.Id.Id Evergreen.V343.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V343.ChannelName.ChannelName
    , description : Evergreen.V343.ChannelDescription.ChannelDescription
    , messages : Evergreen.V343.IdArray.IdArray Evergreen.V343.Id.ChannelMessageId (Evergreen.V343.Message.Message Evergreen.V343.Id.ChannelMessageId (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Thread.LastTypedAt Evergreen.V343.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V343.OneToOne.OneToOne (Evergreen.V343.Discord.Id Evergreen.V343.Discord.MessageId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) Evergreen.V343.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V343.Drawing.Drawing (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId))
    , permissionOverwrites : List Evergreen.V343.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V343.GuildName.GuildName
    , icon : Maybe Evergreen.V343.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V343.MembersAndOwner.MembersAndOwner
            (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V343.Discord.Id Evergreen.V343.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V343.Id.Id Evergreen.V343.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V343.Id.Id Evergreen.V343.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId
    , messages : List Evergreen.V343.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V343.Discord.Message
    , threads : List DiscordThreadReload
    }
