module Evergreen.V334.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V334.Call
import Evergreen.V334.ChannelDescription
import Evergreen.V334.ChannelName
import Evergreen.V334.Cloudflare
import Evergreen.V334.Discord
import Evergreen.V334.DiscordUserData
import Evergreen.V334.DmChannel
import Evergreen.V334.DmChannelId
import Evergreen.V334.Drawing
import Evergreen.V334.FileStatus
import Evergreen.V334.Game
import Evergreen.V334.GuildName
import Evergreen.V334.Id
import Evergreen.V334.IdArray
import Evergreen.V334.Log
import Evergreen.V334.MembersAndOwner
import Evergreen.V334.Message
import Evergreen.V334.NonemptyDict
import Evergreen.V334.OneToOne
import Evergreen.V334.Pagination
import Evergreen.V334.Postmark
import Evergreen.V334.SecretId
import Evergreen.V334.SessionIdHash
import Evergreen.V334.Slack
import Evergreen.V334.TextEditor
import Evergreen.V334.Thread
import Evergreen.V334.ToBackendLog
import Evergreen.V334.User
import Evergreen.V334.UserSession
import Evergreen.V334.VisibleMessages
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
        Evergreen.V334.NonemptyDict.NonemptyDict
            (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V334.Message.Message Evergreen.V334.Id.ChannelMessageId (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V334.Discord.PartialUser
        , icon : Maybe Evergreen.V334.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V334.Discord.User
        , linkedTo : Evergreen.V334.Id.Id Evergreen.V334.Id.UserId
        , icon : Maybe Evergreen.V334.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V334.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V334.Discord.User
        , linkedTo : Evergreen.V334.Id.Id Evergreen.V334.Id.UserId
        , icon : Maybe Evergreen.V334.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V334.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V334.Message.Message Evergreen.V334.Id.ChannelMessageId (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId))
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V334.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V334.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V334.Discord.Id Evergreen.V334.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V334.MembersAndOwner.MembersAndOwner
            (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V334.Discord.Id Evergreen.V334.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V334.Discord.Id Evergreen.V334.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V334.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V334.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V334.Id.Id Evergreen.V334.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V334.GuildName.GuildName
    , owner : Evergreen.V334.Id.Id Evergreen.V334.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V334.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V334.Discord.Id Evergreen.V334.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId) (Evergreen.V334.Discord.Id Evergreen.V334.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V334.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V334.Call.CallId
    | ConnectedToCall
        Evergreen.V334.Call.CallId
        { sessionId : Evergreen.V334.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V334.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V334.Call.RemoteCallData
    , currentlyViewing : Evergreen.V334.UserSession.Viewing
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V334.Id.Id Evergreen.V334.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V334.Id.Id Evergreen.V334.Id.UserId
    , name : Evergreen.V334.ChannelName.ChannelName
    , description : Evergreen.V334.ChannelDescription.ChannelDescription
    , messages : Evergreen.V334.IdArray.IdArray Evergreen.V334.Id.ChannelMessageId (Evergreen.V334.Message.MessageState Evergreen.V334.Id.ChannelMessageId (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId))
    , visibleMessages : Evergreen.V334.VisibleMessages.VisibleMessages Evergreen.V334.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId) (Evergreen.V334.Thread.LastTypedAt Evergreen.V334.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId) Evergreen.V334.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V334.Drawing.Drawing (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId) Evergreen.V334.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V334.Id.Id Evergreen.V334.Id.UserId
    , name : Evergreen.V334.GuildName.GuildName
    , icon : Maybe Evergreen.V334.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V334.MembersAndOwner.MembersAndOwner
            (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V334.SecretId.SecretId Evergreen.V334.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V334.Id.Id Evergreen.V334.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V334.ChannelName.ChannelName
    , description : Evergreen.V334.ChannelDescription.ChannelDescription
    , messages : Evergreen.V334.IdArray.IdArray Evergreen.V334.Id.ChannelMessageId (Evergreen.V334.Message.MessageState Evergreen.V334.Id.ChannelMessageId (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId))
    , visibleMessages : Evergreen.V334.VisibleMessages.VisibleMessages Evergreen.V334.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) (Evergreen.V334.Thread.LastTypedAt Evergreen.V334.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId) Evergreen.V334.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V334.Drawing.Drawing (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId))
    , permissionOverwrites : List Evergreen.V334.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V334.GuildName.GuildName
    , icon : Maybe Evergreen.V334.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V334.Discord.Id Evergreen.V334.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V334.MembersAndOwner.MembersAndOwner
            (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V334.Discord.Id Evergreen.V334.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V334.Id.Id Evergreen.V334.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V334.Id.Id Evergreen.V334.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V334.Discord.Id Evergreen.V334.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V334.NonemptyDict.NonemptyDict (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId) Evergreen.V334.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V334.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V334.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V334.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V334.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V334.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V334.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V334.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V334.Discord.Id Evergreen.V334.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V334.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V334.SessionIdHash.SessionIdHash (Evergreen.V334.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V334.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V334.SessionIdHash.SessionIdHash Evergreen.V334.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId) Evergreen.V334.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V334.Discord.Id Evergreen.V334.Discord.PrivateChannelId) Evergreen.V334.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V334.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V334.SessionIdHash.SessionIdHash Evergreen.V334.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V334.TextEditor.LocalState
    , calls : Evergreen.V334.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V334.Id.Id Evergreen.V334.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V334.Id.Id Evergreen.V334.Id.UserId
    , name : Evergreen.V334.ChannelName.ChannelName
    , description : Evergreen.V334.ChannelDescription.ChannelDescription
    , messages : Evergreen.V334.IdArray.IdArray Evergreen.V334.Id.ChannelMessageId (Evergreen.V334.Message.Message Evergreen.V334.Id.ChannelMessageId (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId) (Evergreen.V334.Thread.LastTypedAt Evergreen.V334.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId) Evergreen.V334.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V334.Drawing.Drawing (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId) Evergreen.V334.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V334.Id.Id Evergreen.V334.Id.UserId
    , name : Evergreen.V334.GuildName.GuildName
    , icon : Maybe Evergreen.V334.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V334.MembersAndOwner.MembersAndOwner
            (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V334.SecretId.SecretId Evergreen.V334.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V334.Id.Id Evergreen.V334.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V334.ChannelName.ChannelName
    , description : Evergreen.V334.ChannelDescription.ChannelDescription
    , messages : Evergreen.V334.IdArray.IdArray Evergreen.V334.Id.ChannelMessageId (Evergreen.V334.Message.Message Evergreen.V334.Id.ChannelMessageId (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) (Evergreen.V334.Thread.LastTypedAt Evergreen.V334.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V334.OneToOne.OneToOne (Evergreen.V334.Discord.Id Evergreen.V334.Discord.MessageId) (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId) Evergreen.V334.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V334.Drawing.Drawing (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId))
    , permissionOverwrites : List Evergreen.V334.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V334.GuildName.GuildName
    , icon : Maybe Evergreen.V334.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V334.Discord.Id Evergreen.V334.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V334.MembersAndOwner.MembersAndOwner
            (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V334.Discord.Id Evergreen.V334.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V334.Id.Id Evergreen.V334.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V334.Id.Id Evergreen.V334.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V334.Discord.Id Evergreen.V334.Discord.RoleId) DiscordRole
    }
