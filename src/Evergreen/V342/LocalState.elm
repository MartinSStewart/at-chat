module Evergreen.V342.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V342.Call
import Evergreen.V342.ChannelDescription
import Evergreen.V342.ChannelName
import Evergreen.V342.Cloudflare
import Evergreen.V342.Discord
import Evergreen.V342.DiscordUserData
import Evergreen.V342.DmChannel
import Evergreen.V342.DmChannelId
import Evergreen.V342.Drawing
import Evergreen.V342.FileStatus
import Evergreen.V342.Game
import Evergreen.V342.GuildName
import Evergreen.V342.Id
import Evergreen.V342.IdArray
import Evergreen.V342.Log
import Evergreen.V342.MembersAndOwner
import Evergreen.V342.Message
import Evergreen.V342.MessageArray
import Evergreen.V342.NonemptyDict
import Evergreen.V342.OneToOne
import Evergreen.V342.Pagination
import Evergreen.V342.Postmark
import Evergreen.V342.SecretId
import Evergreen.V342.SessionIdHash
import Evergreen.V342.Slack
import Evergreen.V342.TextEditor
import Evergreen.V342.Thread
import Evergreen.V342.ToBackendLog
import Evergreen.V342.User
import Evergreen.V342.UserSession
import Evergreen.V342.VisibleMessages
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
        Evergreen.V342.NonemptyDict.NonemptyDict
            (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V342.Message.Message Evergreen.V342.Id.ChannelMessageId (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V342.Discord.PartialUser
        , icon : Maybe Evergreen.V342.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V342.Discord.User
        , linkedTo : Evergreen.V342.Id.Id Evergreen.V342.Id.UserId
        , icon : Maybe Evergreen.V342.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V342.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V342.Discord.User
        , linkedTo : Evergreen.V342.Id.Id Evergreen.V342.Id.UserId
        , icon : Maybe Evergreen.V342.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V342.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V342.Message.Message Evergreen.V342.Id.ChannelMessageId (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId))
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V342.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V342.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V342.MembersAndOwner.MembersAndOwner
            (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V342.Discord.Id Evergreen.V342.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V342.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V342.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V342.Id.Id Evergreen.V342.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V342.GuildName.GuildName
    , owner : Evergreen.V342.Id.Id Evergreen.V342.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V342.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V342.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V342.Call.CallId
    | ConnectedToCall
        Evergreen.V342.Call.CallId
        { sessionId : Evergreen.V342.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V342.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V342.Call.RemoteCallData
    , currentlyViewing : Evergreen.V342.UserSession.Viewing
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V342.Id.Id Evergreen.V342.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V342.Id.Id Evergreen.V342.Id.UserId
    , name : Evergreen.V342.ChannelName.ChannelName
    , description : Evergreen.V342.ChannelDescription.ChannelDescription
    , messages : Evergreen.V342.MessageArray.MessageArray Evergreen.V342.Id.ChannelMessageId (Evergreen.V342.Message.Message Evergreen.V342.Id.ChannelMessageId (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId))
    , visibleMessages : Evergreen.V342.VisibleMessages.VisibleMessages Evergreen.V342.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) (Evergreen.V342.Thread.LastTypedAt Evergreen.V342.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) Evergreen.V342.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V342.Drawing.Drawing (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) Evergreen.V342.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V342.Id.Id Evergreen.V342.Id.UserId
    , name : Evergreen.V342.GuildName.GuildName
    , icon : Maybe Evergreen.V342.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V342.MembersAndOwner.MembersAndOwner
            (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V342.SecretId.SecretId Evergreen.V342.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V342.Id.Id Evergreen.V342.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V342.ChannelName.ChannelName
    , description : Evergreen.V342.ChannelDescription.ChannelDescription
    , messages : Evergreen.V342.MessageArray.MessageArray Evergreen.V342.Id.ChannelMessageId (Evergreen.V342.Message.Message Evergreen.V342.Id.ChannelMessageId (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId))
    , visibleMessages : Evergreen.V342.VisibleMessages.VisibleMessages Evergreen.V342.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Thread.LastTypedAt Evergreen.V342.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) Evergreen.V342.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V342.Drawing.Drawing (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId))
    , permissionOverwrites : List Evergreen.V342.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V342.GuildName.GuildName
    , icon : Maybe Evergreen.V342.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V342.MembersAndOwner.MembersAndOwner
            (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V342.Discord.Id Evergreen.V342.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V342.Id.Id Evergreen.V342.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V342.Id.Id Evergreen.V342.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V342.NonemptyDict.NonemptyDict (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) Evergreen.V342.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V342.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V342.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V342.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V342.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V342.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V342.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V342.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V342.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V342.SessionIdHash.SessionIdHash (Evergreen.V342.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V342.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V342.SessionIdHash.SessionIdHash Evergreen.V342.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) Evergreen.V342.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId) Evergreen.V342.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V342.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V342.SessionIdHash.SessionIdHash Evergreen.V342.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V342.TextEditor.LocalState
    , calls : Evergreen.V342.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V342.Id.Id Evergreen.V342.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V342.Id.Id Evergreen.V342.Id.UserId
    , name : Evergreen.V342.ChannelName.ChannelName
    , description : Evergreen.V342.ChannelDescription.ChannelDescription
    , messages : Evergreen.V342.IdArray.IdArray Evergreen.V342.Id.ChannelMessageId (Evergreen.V342.Message.Message Evergreen.V342.Id.ChannelMessageId (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) (Evergreen.V342.Thread.LastTypedAt Evergreen.V342.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) Evergreen.V342.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V342.Drawing.Drawing (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) Evergreen.V342.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V342.Id.Id Evergreen.V342.Id.UserId
    , name : Evergreen.V342.GuildName.GuildName
    , icon : Maybe Evergreen.V342.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V342.MembersAndOwner.MembersAndOwner
            (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V342.SecretId.SecretId Evergreen.V342.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V342.Id.Id Evergreen.V342.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V342.ChannelName.ChannelName
    , description : Evergreen.V342.ChannelDescription.ChannelDescription
    , messages : Evergreen.V342.IdArray.IdArray Evergreen.V342.Id.ChannelMessageId (Evergreen.V342.Message.Message Evergreen.V342.Id.ChannelMessageId (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Thread.LastTypedAt Evergreen.V342.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V342.OneToOne.OneToOne (Evergreen.V342.Discord.Id Evergreen.V342.Discord.MessageId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) Evergreen.V342.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V342.Drawing.Drawing (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId))
    , permissionOverwrites : List Evergreen.V342.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V342.GuildName.GuildName
    , icon : Maybe Evergreen.V342.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V342.MembersAndOwner.MembersAndOwner
            (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V342.Discord.Id Evergreen.V342.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V342.Id.Id Evergreen.V342.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V342.Id.Id Evergreen.V342.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.RoleId) DiscordRole
    }
