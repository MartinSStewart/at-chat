module Evergreen.V349.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V349.Call
import Evergreen.V349.ChannelDescription
import Evergreen.V349.ChannelName
import Evergreen.V349.Cloudflare
import Evergreen.V349.Discord
import Evergreen.V349.DiscordUserData
import Evergreen.V349.DmChannel
import Evergreen.V349.DmChannelId
import Evergreen.V349.Drawing
import Evergreen.V349.FileStatus
import Evergreen.V349.Game
import Evergreen.V349.GuildName
import Evergreen.V349.Id
import Evergreen.V349.IdArray
import Evergreen.V349.Log
import Evergreen.V349.MembersAndOwner
import Evergreen.V349.Message
import Evergreen.V349.MessageArray
import Evergreen.V349.NonemptyDict
import Evergreen.V349.OneToOne
import Evergreen.V349.Pagination
import Evergreen.V349.Postmark
import Evergreen.V349.SecretId
import Evergreen.V349.SessionIdHash
import Evergreen.V349.Slack
import Evergreen.V349.TextEditor
import Evergreen.V349.Thread
import Evergreen.V349.ToBackendLog
import Evergreen.V349.User
import Evergreen.V349.UserSession
import Evergreen.V349.VisibleMessages
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
        Evergreen.V349.NonemptyDict.NonemptyDict
            (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V349.Message.Message Evergreen.V349.Id.ChannelMessageId (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V349.Discord.PartialUser
        , icon : Maybe Evergreen.V349.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V349.Discord.User
        , linkedTo : Evergreen.V349.Id.Id Evergreen.V349.Id.UserId
        , icon : Maybe Evergreen.V349.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V349.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V349.Discord.User
        , linkedTo : Evergreen.V349.Id.Id Evergreen.V349.Id.UserId
        , icon : Maybe Evergreen.V349.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V349.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V349.Message.Message Evergreen.V349.Id.ChannelMessageId (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId))
    , permissionOverwrites : List Evergreen.V349.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V349.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V349.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V349.MembersAndOwner.MembersAndOwner
            (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V349.Discord.Id Evergreen.V349.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V349.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V349.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V349.Id.Id Evergreen.V349.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V349.GuildName.GuildName
    , owner : Evergreen.V349.Id.Id Evergreen.V349.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V349.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V349.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V349.Call.CallId
    | ConnectedToCall
        Evergreen.V349.Call.CallId
        { sessionId : Evergreen.V349.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V349.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V349.Call.RemoteCallData
    , currentlyViewing : Evergreen.V349.UserSession.Viewing
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V349.Id.Id Evergreen.V349.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V349.Id.Id Evergreen.V349.Id.UserId
    , name : Evergreen.V349.ChannelName.ChannelName
    , description : Evergreen.V349.ChannelDescription.ChannelDescription
    , messages : Evergreen.V349.MessageArray.MessageArray Evergreen.V349.Id.ChannelMessageId (Evergreen.V349.Message.Message Evergreen.V349.Id.ChannelMessageId (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId))
    , visibleMessages : Evergreen.V349.VisibleMessages.VisibleMessages Evergreen.V349.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) (Evergreen.V349.Thread.LastTypedAt Evergreen.V349.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) Evergreen.V349.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V349.Drawing.Drawing (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) Evergreen.V349.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V349.Id.Id Evergreen.V349.Id.UserId
    , name : Evergreen.V349.GuildName.GuildName
    , icon : Maybe Evergreen.V349.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V349.MembersAndOwner.MembersAndOwner
            (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V349.SecretId.SecretId Evergreen.V349.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V349.Id.Id Evergreen.V349.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V349.ChannelName.ChannelName
    , description : Evergreen.V349.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V349.MessageArray.MessageArray Evergreen.V349.Id.ChannelMessageId (Evergreen.V349.Message.Message Evergreen.V349.Id.ChannelMessageId (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId))
    , visibleMessages : Evergreen.V349.VisibleMessages.VisibleMessages Evergreen.V349.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Thread.LastTypedAt Evergreen.V349.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) Evergreen.V349.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V349.Drawing.Drawing (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId))
    , permissionOverwrites : List Evergreen.V349.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V349.GuildName.GuildName
    , icon : Maybe Evergreen.V349.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V349.MembersAndOwner.MembersAndOwner
            (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V349.Discord.Id Evergreen.V349.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V349.Id.Id Evergreen.V349.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V349.Id.Id Evergreen.V349.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V349.NonemptyDict.NonemptyDict (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) Evergreen.V349.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V349.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V349.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V349.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V349.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V349.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V349.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V349.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V349.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V349.SessionIdHash.SessionIdHash (Evergreen.V349.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V349.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V349.SessionIdHash.SessionIdHash Evergreen.V349.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) Evergreen.V349.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId) Evergreen.V349.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V349.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V349.SessionIdHash.SessionIdHash Evergreen.V349.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V349.TextEditor.LocalState
    , calls : Evergreen.V349.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V349.Id.Id Evergreen.V349.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V349.Id.Id Evergreen.V349.Id.UserId
    , name : Evergreen.V349.ChannelName.ChannelName
    , description : Evergreen.V349.ChannelDescription.ChannelDescription
    , messages : Evergreen.V349.IdArray.IdArray Evergreen.V349.Id.ChannelMessageId (Evergreen.V349.Message.Message Evergreen.V349.Id.ChannelMessageId (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) (Evergreen.V349.Thread.LastTypedAt Evergreen.V349.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) Evergreen.V349.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V349.Drawing.Drawing (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) Evergreen.V349.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V349.Id.Id Evergreen.V349.Id.UserId
    , name : Evergreen.V349.GuildName.GuildName
    , icon : Maybe Evergreen.V349.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V349.MembersAndOwner.MembersAndOwner
            (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V349.SecretId.SecretId Evergreen.V349.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V349.Id.Id Evergreen.V349.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V349.ChannelName.ChannelName
    , description : Evergreen.V349.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V349.IdArray.IdArray Evergreen.V349.Id.ChannelMessageId (Evergreen.V349.Message.Message Evergreen.V349.Id.ChannelMessageId (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Thread.LastTypedAt Evergreen.V349.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V349.OneToOne.OneToOne (Evergreen.V349.Discord.Id Evergreen.V349.Discord.MessageId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) Evergreen.V349.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V349.Drawing.Drawing (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId))
    , permissionOverwrites : List Evergreen.V349.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V349.GuildName.GuildName
    , icon : Maybe Evergreen.V349.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V349.MembersAndOwner.MembersAndOwner
            (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V349.Discord.Id Evergreen.V349.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V349.Id.Id Evergreen.V349.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V349.Id.Id Evergreen.V349.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId
    , messages : List Evergreen.V349.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V349.Discord.Message
    , threads : List DiscordThreadReload
    }
