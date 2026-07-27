module Evergreen.V336.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V336.Call
import Evergreen.V336.ChannelDescription
import Evergreen.V336.ChannelName
import Evergreen.V336.Cloudflare
import Evergreen.V336.Discord
import Evergreen.V336.DiscordUserData
import Evergreen.V336.DmChannel
import Evergreen.V336.DmChannelId
import Evergreen.V336.Drawing
import Evergreen.V336.FileStatus
import Evergreen.V336.Game
import Evergreen.V336.GuildName
import Evergreen.V336.Id
import Evergreen.V336.IdArray
import Evergreen.V336.Log
import Evergreen.V336.MembersAndOwner
import Evergreen.V336.Message
import Evergreen.V336.MessageArray
import Evergreen.V336.NonemptyDict
import Evergreen.V336.OneToOne
import Evergreen.V336.Pagination
import Evergreen.V336.Postmark
import Evergreen.V336.SecretId
import Evergreen.V336.SessionIdHash
import Evergreen.V336.Slack
import Evergreen.V336.TextEditor
import Evergreen.V336.Thread
import Evergreen.V336.ToBackendLog
import Evergreen.V336.User
import Evergreen.V336.UserSession
import Evergreen.V336.VisibleMessages
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
        Evergreen.V336.NonemptyDict.NonemptyDict
            (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V336.Message.Message Evergreen.V336.Id.ChannelMessageId (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V336.Discord.PartialUser
        , icon : Maybe Evergreen.V336.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V336.Discord.User
        , linkedTo : Evergreen.V336.Id.Id Evergreen.V336.Id.UserId
        , icon : Maybe Evergreen.V336.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V336.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V336.Discord.User
        , linkedTo : Evergreen.V336.Id.Id Evergreen.V336.Id.UserId
        , icon : Maybe Evergreen.V336.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V336.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V336.Message.Message Evergreen.V336.Id.ChannelMessageId (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId))
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V336.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V336.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V336.MembersAndOwner.MembersAndOwner
            (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V336.Discord.Id Evergreen.V336.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V336.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V336.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V336.Id.Id Evergreen.V336.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V336.GuildName.GuildName
    , owner : Evergreen.V336.Id.Id Evergreen.V336.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V336.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V336.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V336.Call.CallId
    | ConnectedToCall
        Evergreen.V336.Call.CallId
        { sessionId : Evergreen.V336.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V336.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V336.Call.RemoteCallData
    , currentlyViewing : Evergreen.V336.UserSession.Viewing
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V336.Id.Id Evergreen.V336.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V336.Id.Id Evergreen.V336.Id.UserId
    , name : Evergreen.V336.ChannelName.ChannelName
    , description : Evergreen.V336.ChannelDescription.ChannelDescription
    , messages : Evergreen.V336.MessageArray.MessageArray Evergreen.V336.Id.ChannelMessageId (Evergreen.V336.Message.Message Evergreen.V336.Id.ChannelMessageId (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId))
    , visibleMessages : Evergreen.V336.VisibleMessages.VisibleMessages Evergreen.V336.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) (Evergreen.V336.Thread.LastTypedAt Evergreen.V336.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) Evergreen.V336.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V336.Drawing.Drawing (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) Evergreen.V336.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V336.Id.Id Evergreen.V336.Id.UserId
    , name : Evergreen.V336.GuildName.GuildName
    , icon : Maybe Evergreen.V336.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V336.MembersAndOwner.MembersAndOwner
            (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V336.SecretId.SecretId Evergreen.V336.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V336.Id.Id Evergreen.V336.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V336.ChannelName.ChannelName
    , description : Evergreen.V336.ChannelDescription.ChannelDescription
    , messages : Evergreen.V336.MessageArray.MessageArray Evergreen.V336.Id.ChannelMessageId (Evergreen.V336.Message.Message Evergreen.V336.Id.ChannelMessageId (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId))
    , visibleMessages : Evergreen.V336.VisibleMessages.VisibleMessages Evergreen.V336.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Thread.LastTypedAt Evergreen.V336.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) Evergreen.V336.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V336.Drawing.Drawing (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId))
    , permissionOverwrites : List Evergreen.V336.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V336.GuildName.GuildName
    , icon : Maybe Evergreen.V336.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V336.MembersAndOwner.MembersAndOwner
            (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V336.Discord.Id Evergreen.V336.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V336.Id.Id Evergreen.V336.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V336.Id.Id Evergreen.V336.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V336.NonemptyDict.NonemptyDict (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) Evergreen.V336.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V336.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V336.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V336.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V336.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V336.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V336.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V336.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V336.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V336.SessionIdHash.SessionIdHash (Evergreen.V336.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V336.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V336.SessionIdHash.SessionIdHash Evergreen.V336.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) Evergreen.V336.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId) Evergreen.V336.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V336.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V336.SessionIdHash.SessionIdHash Evergreen.V336.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V336.TextEditor.LocalState
    , calls : Evergreen.V336.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V336.Id.Id Evergreen.V336.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V336.Id.Id Evergreen.V336.Id.UserId
    , name : Evergreen.V336.ChannelName.ChannelName
    , description : Evergreen.V336.ChannelDescription.ChannelDescription
    , messages : Evergreen.V336.IdArray.IdArray Evergreen.V336.Id.ChannelMessageId (Evergreen.V336.Message.Message Evergreen.V336.Id.ChannelMessageId (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) (Evergreen.V336.Thread.LastTypedAt Evergreen.V336.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) Evergreen.V336.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V336.Drawing.Drawing (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) Evergreen.V336.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V336.Id.Id Evergreen.V336.Id.UserId
    , name : Evergreen.V336.GuildName.GuildName
    , icon : Maybe Evergreen.V336.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V336.MembersAndOwner.MembersAndOwner
            (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V336.SecretId.SecretId Evergreen.V336.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V336.Id.Id Evergreen.V336.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V336.ChannelName.ChannelName
    , description : Evergreen.V336.ChannelDescription.ChannelDescription
    , messages : Evergreen.V336.IdArray.IdArray Evergreen.V336.Id.ChannelMessageId (Evergreen.V336.Message.Message Evergreen.V336.Id.ChannelMessageId (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Thread.LastTypedAt Evergreen.V336.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V336.OneToOne.OneToOne (Evergreen.V336.Discord.Id Evergreen.V336.Discord.MessageId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) Evergreen.V336.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V336.Drawing.Drawing (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId))
    , permissionOverwrites : List Evergreen.V336.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V336.GuildName.GuildName
    , icon : Maybe Evergreen.V336.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V336.MembersAndOwner.MembersAndOwner
            (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V336.Discord.Id Evergreen.V336.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V336.Id.Id Evergreen.V336.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V336.Id.Id Evergreen.V336.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.RoleId) DiscordRole
    }
