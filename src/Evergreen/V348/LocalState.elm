module Evergreen.V348.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V348.Call
import Evergreen.V348.ChannelDescription
import Evergreen.V348.ChannelName
import Evergreen.V348.Cloudflare
import Evergreen.V348.Discord
import Evergreen.V348.DiscordUserData
import Evergreen.V348.DmChannel
import Evergreen.V348.DmChannelId
import Evergreen.V348.Drawing
import Evergreen.V348.FileStatus
import Evergreen.V348.Game
import Evergreen.V348.GuildName
import Evergreen.V348.Id
import Evergreen.V348.IdArray
import Evergreen.V348.Log
import Evergreen.V348.MembersAndOwner
import Evergreen.V348.Message
import Evergreen.V348.MessageArray
import Evergreen.V348.NonemptyDict
import Evergreen.V348.OneToOne
import Evergreen.V348.Pagination
import Evergreen.V348.Postmark
import Evergreen.V348.SecretId
import Evergreen.V348.SessionIdHash
import Evergreen.V348.Slack
import Evergreen.V348.TextEditor
import Evergreen.V348.Thread
import Evergreen.V348.ToBackendLog
import Evergreen.V348.User
import Evergreen.V348.UserSession
import Evergreen.V348.VisibleMessages
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
        Evergreen.V348.NonemptyDict.NonemptyDict
            (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V348.Message.Message Evergreen.V348.Id.ChannelMessageId (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V348.Discord.PartialUser
        , icon : Maybe Evergreen.V348.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V348.Discord.User
        , linkedTo : Evergreen.V348.Id.Id Evergreen.V348.Id.UserId
        , icon : Maybe Evergreen.V348.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V348.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V348.Discord.User
        , linkedTo : Evergreen.V348.Id.Id Evergreen.V348.Id.UserId
        , icon : Maybe Evergreen.V348.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V348.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V348.Message.Message Evergreen.V348.Id.ChannelMessageId (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId))
    , permissionOverwrites : List Evergreen.V348.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V348.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V348.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V348.MembersAndOwner.MembersAndOwner
            (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V348.Discord.Id Evergreen.V348.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V348.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V348.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V348.Id.Id Evergreen.V348.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V348.GuildName.GuildName
    , owner : Evergreen.V348.Id.Id Evergreen.V348.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V348.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V348.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V348.Call.CallId
    | ConnectedToCall
        Evergreen.V348.Call.CallId
        { sessionId : Evergreen.V348.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V348.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V348.Call.RemoteCallData
    , currentlyViewing : Evergreen.V348.UserSession.Viewing
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V348.Id.Id Evergreen.V348.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V348.Id.Id Evergreen.V348.Id.UserId
    , name : Evergreen.V348.ChannelName.ChannelName
    , description : Evergreen.V348.ChannelDescription.ChannelDescription
    , messages : Evergreen.V348.MessageArray.MessageArray Evergreen.V348.Id.ChannelMessageId (Evergreen.V348.Message.Message Evergreen.V348.Id.ChannelMessageId (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId))
    , visibleMessages : Evergreen.V348.VisibleMessages.VisibleMessages Evergreen.V348.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) (Evergreen.V348.Thread.LastTypedAt Evergreen.V348.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) Evergreen.V348.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V348.Drawing.Drawing (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) Evergreen.V348.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V348.Id.Id Evergreen.V348.Id.UserId
    , name : Evergreen.V348.GuildName.GuildName
    , icon : Maybe Evergreen.V348.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V348.MembersAndOwner.MembersAndOwner
            (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V348.SecretId.SecretId Evergreen.V348.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V348.Id.Id Evergreen.V348.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V348.ChannelName.ChannelName
    , description : Evergreen.V348.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V348.MessageArray.MessageArray Evergreen.V348.Id.ChannelMessageId (Evergreen.V348.Message.Message Evergreen.V348.Id.ChannelMessageId (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId))
    , visibleMessages : Evergreen.V348.VisibleMessages.VisibleMessages Evergreen.V348.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Thread.LastTypedAt Evergreen.V348.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) Evergreen.V348.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V348.Drawing.Drawing (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId))
    , permissionOverwrites : List Evergreen.V348.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V348.GuildName.GuildName
    , icon : Maybe Evergreen.V348.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V348.MembersAndOwner.MembersAndOwner
            (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V348.Discord.Id Evergreen.V348.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V348.Id.Id Evergreen.V348.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V348.Id.Id Evergreen.V348.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V348.NonemptyDict.NonemptyDict (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) Evergreen.V348.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V348.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V348.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V348.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V348.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V348.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V348.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V348.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V348.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V348.SessionIdHash.SessionIdHash (Evergreen.V348.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V348.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V348.SessionIdHash.SessionIdHash Evergreen.V348.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) Evergreen.V348.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId) Evergreen.V348.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V348.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V348.SessionIdHash.SessionIdHash Evergreen.V348.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V348.TextEditor.LocalState
    , calls : Evergreen.V348.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V348.Id.Id Evergreen.V348.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V348.Id.Id Evergreen.V348.Id.UserId
    , name : Evergreen.V348.ChannelName.ChannelName
    , description : Evergreen.V348.ChannelDescription.ChannelDescription
    , messages : Evergreen.V348.IdArray.IdArray Evergreen.V348.Id.ChannelMessageId (Evergreen.V348.Message.Message Evergreen.V348.Id.ChannelMessageId (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) (Evergreen.V348.Thread.LastTypedAt Evergreen.V348.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) Evergreen.V348.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V348.Drawing.Drawing (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) Evergreen.V348.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V348.Id.Id Evergreen.V348.Id.UserId
    , name : Evergreen.V348.GuildName.GuildName
    , icon : Maybe Evergreen.V348.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V348.MembersAndOwner.MembersAndOwner
            (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V348.SecretId.SecretId Evergreen.V348.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V348.Id.Id Evergreen.V348.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V348.ChannelName.ChannelName
    , description : Evergreen.V348.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V348.IdArray.IdArray Evergreen.V348.Id.ChannelMessageId (Evergreen.V348.Message.Message Evergreen.V348.Id.ChannelMessageId (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Thread.LastTypedAt Evergreen.V348.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V348.OneToOne.OneToOne (Evergreen.V348.Discord.Id Evergreen.V348.Discord.MessageId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) Evergreen.V348.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V348.Drawing.Drawing (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId))
    , permissionOverwrites : List Evergreen.V348.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V348.GuildName.GuildName
    , icon : Maybe Evergreen.V348.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V348.MembersAndOwner.MembersAndOwner
            (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V348.Discord.Id Evergreen.V348.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V348.Id.Id Evergreen.V348.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V348.Id.Id Evergreen.V348.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId
    , messages : List Evergreen.V348.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V348.Discord.Message
    , threads : List DiscordThreadReload
    }
