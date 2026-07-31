module Evergreen.V341.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V341.Call
import Evergreen.V341.ChannelDescription
import Evergreen.V341.ChannelName
import Evergreen.V341.Cloudflare
import Evergreen.V341.Discord
import Evergreen.V341.DiscordUserData
import Evergreen.V341.DmChannel
import Evergreen.V341.DmChannelId
import Evergreen.V341.Drawing
import Evergreen.V341.FileStatus
import Evergreen.V341.Game
import Evergreen.V341.GuildName
import Evergreen.V341.Id
import Evergreen.V341.IdArray
import Evergreen.V341.Log
import Evergreen.V341.MembersAndOwner
import Evergreen.V341.Message
import Evergreen.V341.MessageArray
import Evergreen.V341.NonemptyDict
import Evergreen.V341.OneToOne
import Evergreen.V341.Pagination
import Evergreen.V341.Postmark
import Evergreen.V341.SecretId
import Evergreen.V341.SessionIdHash
import Evergreen.V341.Slack
import Evergreen.V341.TextEditor
import Evergreen.V341.Thread
import Evergreen.V341.ToBackendLog
import Evergreen.V341.User
import Evergreen.V341.UserSession
import Evergreen.V341.VisibleMessages
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
        Evergreen.V341.NonemptyDict.NonemptyDict
            (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V341.Message.Message Evergreen.V341.Id.ChannelMessageId (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V341.Discord.PartialUser
        , icon : Maybe Evergreen.V341.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V341.Discord.User
        , linkedTo : Evergreen.V341.Id.Id Evergreen.V341.Id.UserId
        , icon : Maybe Evergreen.V341.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V341.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V341.Discord.User
        , linkedTo : Evergreen.V341.Id.Id Evergreen.V341.Id.UserId
        , icon : Maybe Evergreen.V341.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V341.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V341.Message.Message Evergreen.V341.Id.ChannelMessageId (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId))
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V341.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V341.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V341.MembersAndOwner.MembersAndOwner
            (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V341.Discord.Id Evergreen.V341.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V341.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V341.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V341.Id.Id Evergreen.V341.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V341.GuildName.GuildName
    , owner : Evergreen.V341.Id.Id Evergreen.V341.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V341.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V341.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V341.Call.CallId
    | ConnectedToCall
        Evergreen.V341.Call.CallId
        { sessionId : Evergreen.V341.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V341.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V341.Call.RemoteCallData
    , currentlyViewing : Evergreen.V341.UserSession.Viewing
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V341.Id.Id Evergreen.V341.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V341.Id.Id Evergreen.V341.Id.UserId
    , name : Evergreen.V341.ChannelName.ChannelName
    , description : Evergreen.V341.ChannelDescription.ChannelDescription
    , messages : Evergreen.V341.MessageArray.MessageArray Evergreen.V341.Id.ChannelMessageId (Evergreen.V341.Message.Message Evergreen.V341.Id.ChannelMessageId (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId))
    , visibleMessages : Evergreen.V341.VisibleMessages.VisibleMessages Evergreen.V341.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) (Evergreen.V341.Thread.LastTypedAt Evergreen.V341.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) Evergreen.V341.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V341.Drawing.Drawing (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) Evergreen.V341.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V341.Id.Id Evergreen.V341.Id.UserId
    , name : Evergreen.V341.GuildName.GuildName
    , icon : Maybe Evergreen.V341.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V341.MembersAndOwner.MembersAndOwner
            (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V341.SecretId.SecretId Evergreen.V341.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V341.Id.Id Evergreen.V341.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V341.ChannelName.ChannelName
    , description : Evergreen.V341.ChannelDescription.ChannelDescription
    , messages : Evergreen.V341.MessageArray.MessageArray Evergreen.V341.Id.ChannelMessageId (Evergreen.V341.Message.Message Evergreen.V341.Id.ChannelMessageId (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId))
    , visibleMessages : Evergreen.V341.VisibleMessages.VisibleMessages Evergreen.V341.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Thread.LastTypedAt Evergreen.V341.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) Evergreen.V341.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V341.Drawing.Drawing (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId))
    , permissionOverwrites : List Evergreen.V341.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V341.GuildName.GuildName
    , icon : Maybe Evergreen.V341.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V341.MembersAndOwner.MembersAndOwner
            (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V341.Discord.Id Evergreen.V341.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V341.Id.Id Evergreen.V341.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V341.Id.Id Evergreen.V341.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V341.NonemptyDict.NonemptyDict (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) Evergreen.V341.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V341.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V341.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V341.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V341.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V341.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V341.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V341.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V341.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V341.SessionIdHash.SessionIdHash (Evergreen.V341.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V341.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V341.SessionIdHash.SessionIdHash Evergreen.V341.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) Evergreen.V341.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId) Evergreen.V341.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V341.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V341.SessionIdHash.SessionIdHash Evergreen.V341.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V341.TextEditor.LocalState
    , calls : Evergreen.V341.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V341.Id.Id Evergreen.V341.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V341.Id.Id Evergreen.V341.Id.UserId
    , name : Evergreen.V341.ChannelName.ChannelName
    , description : Evergreen.V341.ChannelDescription.ChannelDescription
    , messages : Evergreen.V341.IdArray.IdArray Evergreen.V341.Id.ChannelMessageId (Evergreen.V341.Message.Message Evergreen.V341.Id.ChannelMessageId (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) (Evergreen.V341.Thread.LastTypedAt Evergreen.V341.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) Evergreen.V341.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V341.Drawing.Drawing (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) Evergreen.V341.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V341.Id.Id Evergreen.V341.Id.UserId
    , name : Evergreen.V341.GuildName.GuildName
    , icon : Maybe Evergreen.V341.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V341.MembersAndOwner.MembersAndOwner
            (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V341.SecretId.SecretId Evergreen.V341.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V341.Id.Id Evergreen.V341.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V341.ChannelName.ChannelName
    , description : Evergreen.V341.ChannelDescription.ChannelDescription
    , messages : Evergreen.V341.IdArray.IdArray Evergreen.V341.Id.ChannelMessageId (Evergreen.V341.Message.Message Evergreen.V341.Id.ChannelMessageId (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Thread.LastTypedAt Evergreen.V341.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V341.OneToOne.OneToOne (Evergreen.V341.Discord.Id Evergreen.V341.Discord.MessageId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) Evergreen.V341.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V341.Drawing.Drawing (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId))
    , permissionOverwrites : List Evergreen.V341.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V341.GuildName.GuildName
    , icon : Maybe Evergreen.V341.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V341.MembersAndOwner.MembersAndOwner
            (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V341.Discord.Id Evergreen.V341.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V341.Id.Id Evergreen.V341.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V341.Id.Id Evergreen.V341.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.RoleId) DiscordRole
    }
