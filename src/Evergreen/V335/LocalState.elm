module Evergreen.V335.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V335.Call
import Evergreen.V335.ChannelDescription
import Evergreen.V335.ChannelName
import Evergreen.V335.Cloudflare
import Evergreen.V335.Discord
import Evergreen.V335.DiscordUserData
import Evergreen.V335.DmChannel
import Evergreen.V335.DmChannelId
import Evergreen.V335.Drawing
import Evergreen.V335.FileStatus
import Evergreen.V335.Game
import Evergreen.V335.GuildName
import Evergreen.V335.Id
import Evergreen.V335.IdArray
import Evergreen.V335.Log
import Evergreen.V335.MembersAndOwner
import Evergreen.V335.Message
import Evergreen.V335.MessageArray
import Evergreen.V335.NonemptyDict
import Evergreen.V335.OneToOne
import Evergreen.V335.Pagination
import Evergreen.V335.Postmark
import Evergreen.V335.SecretId
import Evergreen.V335.SessionIdHash
import Evergreen.V335.Slack
import Evergreen.V335.TextEditor
import Evergreen.V335.Thread
import Evergreen.V335.ToBackendLog
import Evergreen.V335.User
import Evergreen.V335.UserSession
import Evergreen.V335.VisibleMessages
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
        Evergreen.V335.NonemptyDict.NonemptyDict
            (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V335.Message.Message Evergreen.V335.Id.ChannelMessageId (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V335.Discord.PartialUser
        , icon : Maybe Evergreen.V335.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V335.Discord.User
        , linkedTo : Evergreen.V335.Id.Id Evergreen.V335.Id.UserId
        , icon : Maybe Evergreen.V335.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V335.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V335.Discord.User
        , linkedTo : Evergreen.V335.Id.Id Evergreen.V335.Id.UserId
        , icon : Maybe Evergreen.V335.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V335.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V335.Message.Message Evergreen.V335.Id.ChannelMessageId (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId))
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V335.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V335.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V335.MembersAndOwner.MembersAndOwner
            (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V335.Discord.Id Evergreen.V335.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V335.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V335.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V335.Id.Id Evergreen.V335.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V335.GuildName.GuildName
    , owner : Evergreen.V335.Id.Id Evergreen.V335.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V335.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V335.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V335.Call.CallId
    | ConnectedToCall
        Evergreen.V335.Call.CallId
        { sessionId : Evergreen.V335.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V335.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V335.Call.RemoteCallData
    , currentlyViewing : Evergreen.V335.UserSession.Viewing
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V335.Id.Id Evergreen.V335.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V335.Id.Id Evergreen.V335.Id.UserId
    , name : Evergreen.V335.ChannelName.ChannelName
    , description : Evergreen.V335.ChannelDescription.ChannelDescription
    , messages : Evergreen.V335.MessageArray.MessageArray Evergreen.V335.Id.ChannelMessageId (Evergreen.V335.Message.Message Evergreen.V335.Id.ChannelMessageId (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId))
    , visibleMessages : Evergreen.V335.VisibleMessages.VisibleMessages Evergreen.V335.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) (Evergreen.V335.Thread.LastTypedAt Evergreen.V335.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) Evergreen.V335.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V335.Drawing.Drawing (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) Evergreen.V335.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V335.Id.Id Evergreen.V335.Id.UserId
    , name : Evergreen.V335.GuildName.GuildName
    , icon : Maybe Evergreen.V335.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V335.MembersAndOwner.MembersAndOwner
            (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V335.SecretId.SecretId Evergreen.V335.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V335.Id.Id Evergreen.V335.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V335.ChannelName.ChannelName
    , description : Evergreen.V335.ChannelDescription.ChannelDescription
    , messages : Evergreen.V335.MessageArray.MessageArray Evergreen.V335.Id.ChannelMessageId (Evergreen.V335.Message.Message Evergreen.V335.Id.ChannelMessageId (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId))
    , visibleMessages : Evergreen.V335.VisibleMessages.VisibleMessages Evergreen.V335.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Thread.LastTypedAt Evergreen.V335.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) Evergreen.V335.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V335.Drawing.Drawing (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId))
    , permissionOverwrites : List Evergreen.V335.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V335.GuildName.GuildName
    , icon : Maybe Evergreen.V335.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V335.MembersAndOwner.MembersAndOwner
            (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V335.Discord.Id Evergreen.V335.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V335.Id.Id Evergreen.V335.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V335.Id.Id Evergreen.V335.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V335.NonemptyDict.NonemptyDict (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) Evergreen.V335.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V335.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V335.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V335.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V335.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V335.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V335.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V335.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V335.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V335.SessionIdHash.SessionIdHash (Evergreen.V335.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V335.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V335.SessionIdHash.SessionIdHash Evergreen.V335.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) Evergreen.V335.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId) Evergreen.V335.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V335.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V335.SessionIdHash.SessionIdHash Evergreen.V335.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V335.TextEditor.LocalState
    , calls : Evergreen.V335.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V335.Id.Id Evergreen.V335.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V335.Id.Id Evergreen.V335.Id.UserId
    , name : Evergreen.V335.ChannelName.ChannelName
    , description : Evergreen.V335.ChannelDescription.ChannelDescription
    , messages : Evergreen.V335.IdArray.IdArray Evergreen.V335.Id.ChannelMessageId (Evergreen.V335.Message.Message Evergreen.V335.Id.ChannelMessageId (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) (Evergreen.V335.Thread.LastTypedAt Evergreen.V335.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) Evergreen.V335.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V335.Drawing.Drawing (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) Evergreen.V335.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V335.Id.Id Evergreen.V335.Id.UserId
    , name : Evergreen.V335.GuildName.GuildName
    , icon : Maybe Evergreen.V335.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V335.MembersAndOwner.MembersAndOwner
            (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V335.SecretId.SecretId Evergreen.V335.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V335.Id.Id Evergreen.V335.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V335.ChannelName.ChannelName
    , description : Evergreen.V335.ChannelDescription.ChannelDescription
    , messages : Evergreen.V335.IdArray.IdArray Evergreen.V335.Id.ChannelMessageId (Evergreen.V335.Message.Message Evergreen.V335.Id.ChannelMessageId (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Thread.LastTypedAt Evergreen.V335.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V335.OneToOne.OneToOne (Evergreen.V335.Discord.Id Evergreen.V335.Discord.MessageId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) Evergreen.V335.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V335.Drawing.Drawing (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId))
    , permissionOverwrites : List Evergreen.V335.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V335.GuildName.GuildName
    , icon : Maybe Evergreen.V335.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V335.MembersAndOwner.MembersAndOwner
            (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V335.Discord.Id Evergreen.V335.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V335.Id.Id Evergreen.V335.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V335.Id.Id Evergreen.V335.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.RoleId) DiscordRole
    }
