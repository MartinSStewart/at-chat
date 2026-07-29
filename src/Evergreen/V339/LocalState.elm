module Evergreen.V339.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V339.Call
import Evergreen.V339.ChannelDescription
import Evergreen.V339.ChannelName
import Evergreen.V339.Cloudflare
import Evergreen.V339.Discord
import Evergreen.V339.DiscordUserData
import Evergreen.V339.DmChannel
import Evergreen.V339.DmChannelId
import Evergreen.V339.Drawing
import Evergreen.V339.FileStatus
import Evergreen.V339.Game
import Evergreen.V339.GuildName
import Evergreen.V339.Id
import Evergreen.V339.IdArray
import Evergreen.V339.Log
import Evergreen.V339.MembersAndOwner
import Evergreen.V339.Message
import Evergreen.V339.MessageArray
import Evergreen.V339.NonemptyDict
import Evergreen.V339.OneToOne
import Evergreen.V339.Pagination
import Evergreen.V339.Postmark
import Evergreen.V339.SecretId
import Evergreen.V339.SessionIdHash
import Evergreen.V339.Slack
import Evergreen.V339.TextEditor
import Evergreen.V339.Thread
import Evergreen.V339.ToBackendLog
import Evergreen.V339.User
import Evergreen.V339.UserSession
import Evergreen.V339.VisibleMessages
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
        Evergreen.V339.NonemptyDict.NonemptyDict
            (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V339.Message.Message Evergreen.V339.Id.ChannelMessageId (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V339.Discord.PartialUser
        , icon : Maybe Evergreen.V339.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V339.Discord.User
        , linkedTo : Evergreen.V339.Id.Id Evergreen.V339.Id.UserId
        , icon : Maybe Evergreen.V339.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V339.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V339.Discord.User
        , linkedTo : Evergreen.V339.Id.Id Evergreen.V339.Id.UserId
        , icon : Maybe Evergreen.V339.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V339.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V339.Message.Message Evergreen.V339.Id.ChannelMessageId (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId))
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V339.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V339.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V339.MembersAndOwner.MembersAndOwner
            (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V339.Discord.Id Evergreen.V339.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V339.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V339.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V339.Id.Id Evergreen.V339.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V339.GuildName.GuildName
    , owner : Evergreen.V339.Id.Id Evergreen.V339.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V339.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V339.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V339.Call.CallId
    | ConnectedToCall
        Evergreen.V339.Call.CallId
        { sessionId : Evergreen.V339.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V339.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V339.Call.RemoteCallData
    , currentlyViewing : Evergreen.V339.UserSession.Viewing
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V339.Id.Id Evergreen.V339.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V339.Id.Id Evergreen.V339.Id.UserId
    , name : Evergreen.V339.ChannelName.ChannelName
    , description : Evergreen.V339.ChannelDescription.ChannelDescription
    , messages : Evergreen.V339.MessageArray.MessageArray Evergreen.V339.Id.ChannelMessageId (Evergreen.V339.Message.Message Evergreen.V339.Id.ChannelMessageId (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId))
    , visibleMessages : Evergreen.V339.VisibleMessages.VisibleMessages Evergreen.V339.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) (Evergreen.V339.Thread.LastTypedAt Evergreen.V339.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) Evergreen.V339.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V339.Drawing.Drawing (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) Evergreen.V339.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V339.Id.Id Evergreen.V339.Id.UserId
    , name : Evergreen.V339.GuildName.GuildName
    , icon : Maybe Evergreen.V339.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V339.MembersAndOwner.MembersAndOwner
            (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V339.SecretId.SecretId Evergreen.V339.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V339.Id.Id Evergreen.V339.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V339.ChannelName.ChannelName
    , description : Evergreen.V339.ChannelDescription.ChannelDescription
    , messages : Evergreen.V339.MessageArray.MessageArray Evergreen.V339.Id.ChannelMessageId (Evergreen.V339.Message.Message Evergreen.V339.Id.ChannelMessageId (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId))
    , visibleMessages : Evergreen.V339.VisibleMessages.VisibleMessages Evergreen.V339.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Thread.LastTypedAt Evergreen.V339.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) Evergreen.V339.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V339.Drawing.Drawing (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId))
    , permissionOverwrites : List Evergreen.V339.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V339.GuildName.GuildName
    , icon : Maybe Evergreen.V339.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V339.MembersAndOwner.MembersAndOwner
            (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V339.Discord.Id Evergreen.V339.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V339.Id.Id Evergreen.V339.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V339.Id.Id Evergreen.V339.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V339.NonemptyDict.NonemptyDict (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) Evergreen.V339.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V339.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V339.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V339.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V339.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V339.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V339.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V339.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V339.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V339.SessionIdHash.SessionIdHash (Evergreen.V339.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V339.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V339.SessionIdHash.SessionIdHash Evergreen.V339.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) Evergreen.V339.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId) Evergreen.V339.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V339.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V339.SessionIdHash.SessionIdHash Evergreen.V339.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V339.TextEditor.LocalState
    , calls : Evergreen.V339.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V339.Id.Id Evergreen.V339.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V339.Id.Id Evergreen.V339.Id.UserId
    , name : Evergreen.V339.ChannelName.ChannelName
    , description : Evergreen.V339.ChannelDescription.ChannelDescription
    , messages : Evergreen.V339.IdArray.IdArray Evergreen.V339.Id.ChannelMessageId (Evergreen.V339.Message.Message Evergreen.V339.Id.ChannelMessageId (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) (Evergreen.V339.Thread.LastTypedAt Evergreen.V339.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) Evergreen.V339.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V339.Drawing.Drawing (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) Evergreen.V339.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V339.Id.Id Evergreen.V339.Id.UserId
    , name : Evergreen.V339.GuildName.GuildName
    , icon : Maybe Evergreen.V339.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V339.MembersAndOwner.MembersAndOwner
            (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V339.SecretId.SecretId Evergreen.V339.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V339.Id.Id Evergreen.V339.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V339.ChannelName.ChannelName
    , description : Evergreen.V339.ChannelDescription.ChannelDescription
    , messages : Evergreen.V339.IdArray.IdArray Evergreen.V339.Id.ChannelMessageId (Evergreen.V339.Message.Message Evergreen.V339.Id.ChannelMessageId (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Thread.LastTypedAt Evergreen.V339.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V339.OneToOne.OneToOne (Evergreen.V339.Discord.Id Evergreen.V339.Discord.MessageId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) Evergreen.V339.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V339.Drawing.Drawing (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId))
    , permissionOverwrites : List Evergreen.V339.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V339.GuildName.GuildName
    , icon : Maybe Evergreen.V339.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V339.MembersAndOwner.MembersAndOwner
            (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V339.Discord.Id Evergreen.V339.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V339.Id.Id Evergreen.V339.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V339.Id.Id Evergreen.V339.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.RoleId) DiscordRole
    }
