module Evergreen.V318.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V318.Call
import Evergreen.V318.ChannelDescription
import Evergreen.V318.ChannelName
import Evergreen.V318.Cloudflare
import Evergreen.V318.Discord
import Evergreen.V318.DiscordUserData
import Evergreen.V318.DmChannel
import Evergreen.V318.DmChannelId
import Evergreen.V318.Drawing
import Evergreen.V318.FileStatus
import Evergreen.V318.Game
import Evergreen.V318.GuildName
import Evergreen.V318.Id
import Evergreen.V318.IdArray
import Evergreen.V318.Log
import Evergreen.V318.MembersAndOwner
import Evergreen.V318.Message
import Evergreen.V318.NonemptyDict
import Evergreen.V318.OneToOne
import Evergreen.V318.Pagination
import Evergreen.V318.Postmark
import Evergreen.V318.SecretId
import Evergreen.V318.SessionIdHash
import Evergreen.V318.Slack
import Evergreen.V318.TextEditor
import Evergreen.V318.Thread
import Evergreen.V318.ToBackendLog
import Evergreen.V318.User
import Evergreen.V318.UserSession
import Evergreen.V318.VisibleMessages
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
        Evergreen.V318.NonemptyDict.NonemptyDict
            (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V318.Message.Message Evergreen.V318.Id.ChannelMessageId (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V318.Discord.PartialUser
        , icon : Maybe Evergreen.V318.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V318.Discord.User
        , linkedTo : Evergreen.V318.Id.Id Evergreen.V318.Id.UserId
        , icon : Maybe Evergreen.V318.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V318.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V318.Discord.User
        , linkedTo : Evergreen.V318.Id.Id Evergreen.V318.Id.UserId
        , icon : Maybe Evergreen.V318.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V318.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V318.Message.Message Evergreen.V318.Id.ChannelMessageId (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V318.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V318.MembersAndOwner.MembersAndOwner
            (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V318.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V318.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V318.Id.Id Evergreen.V318.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V318.GuildName.GuildName
    , owner : Evergreen.V318.Id.Id Evergreen.V318.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V318.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V318.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V318.Call.CallId
    | ConnectedToCall
        Evergreen.V318.Call.CallId
        { sessionId : Evergreen.V318.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V318.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V318.Call.RemoteCallData
    , currentlyViewing : Maybe ( Evergreen.V318.Id.AnyGuildOrDmId, Evergreen.V318.Id.ThreadRoute )
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameSwedishStatus
    = WordSpellingGameSwedishStatus_NotLoaded
    | WordSpellingGameSwedishStatus_Loading
    | WordSpellingGameSwedishStatus_Error Effect.Http.Error
    | WordSpellingGameSwedishStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V318.Id.Id Evergreen.V318.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V318.Id.Id Evergreen.V318.Id.UserId
    , name : Evergreen.V318.ChannelName.ChannelName
    , description : Evergreen.V318.ChannelDescription.ChannelDescription
    , messages : Evergreen.V318.IdArray.IdArray Evergreen.V318.Id.ChannelMessageId (Evergreen.V318.Message.MessageState Evergreen.V318.Id.ChannelMessageId (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId))
    , visibleMessages : Evergreen.V318.VisibleMessages.VisibleMessages Evergreen.V318.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) (Evergreen.V318.Thread.LastTypedAt Evergreen.V318.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) Evergreen.V318.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V318.Drawing.Drawing (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) Evergreen.V318.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V318.Id.Id Evergreen.V318.Id.UserId
    , name : Evergreen.V318.GuildName.GuildName
    , icon : Maybe Evergreen.V318.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V318.MembersAndOwner.MembersAndOwner
            (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V318.SecretId.SecretId Evergreen.V318.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V318.Id.Id Evergreen.V318.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V318.ChannelName.ChannelName
    , description : Evergreen.V318.ChannelDescription.ChannelDescription
    , messages : Evergreen.V318.IdArray.IdArray Evergreen.V318.Id.ChannelMessageId (Evergreen.V318.Message.MessageState Evergreen.V318.Id.ChannelMessageId (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId))
    , visibleMessages : Evergreen.V318.VisibleMessages.VisibleMessages Evergreen.V318.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Evergreen.V318.Thread.LastTypedAt Evergreen.V318.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) Evergreen.V318.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V318.Drawing.Drawing (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V318.GuildName.GuildName
    , icon : Maybe Evergreen.V318.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V318.MembersAndOwner.MembersAndOwner
            (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V318.Id.Id Evergreen.V318.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V318.Id.Id Evergreen.V318.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V318.NonemptyDict.NonemptyDict (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) Evergreen.V318.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V318.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V318.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V318.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V318.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V318.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V318.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V318.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V318.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V318.SessionIdHash.SessionIdHash (Evergreen.V318.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V318.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V318.SessionIdHash.SessionIdHash Evergreen.V318.UserSession.UserSession
    , wordSpellingGameSwedish : WordSpellingGameSwedishStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) Evergreen.V318.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId) Evergreen.V318.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V318.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V318.SessionIdHash.SessionIdHash Evergreen.V318.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V318.TextEditor.LocalState
    , calls : Evergreen.V318.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V318.Id.Id Evergreen.V318.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V318.Id.Id Evergreen.V318.Id.UserId
    , name : Evergreen.V318.ChannelName.ChannelName
    , description : Evergreen.V318.ChannelDescription.ChannelDescription
    , messages : Evergreen.V318.IdArray.IdArray Evergreen.V318.Id.ChannelMessageId (Evergreen.V318.Message.Message Evergreen.V318.Id.ChannelMessageId (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) (Evergreen.V318.Thread.LastTypedAt Evergreen.V318.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) Evergreen.V318.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V318.Drawing.Drawing (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) Evergreen.V318.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V318.Id.Id Evergreen.V318.Id.UserId
    , name : Evergreen.V318.GuildName.GuildName
    , icon : Maybe Evergreen.V318.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V318.MembersAndOwner.MembersAndOwner
            (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V318.SecretId.SecretId Evergreen.V318.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V318.Id.Id Evergreen.V318.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V318.ChannelName.ChannelName
    , description : Evergreen.V318.ChannelDescription.ChannelDescription
    , messages : Evergreen.V318.IdArray.IdArray Evergreen.V318.Id.ChannelMessageId (Evergreen.V318.Message.Message Evergreen.V318.Id.ChannelMessageId (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Evergreen.V318.Thread.LastTypedAt Evergreen.V318.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V318.OneToOne.OneToOne (Evergreen.V318.Discord.Id Evergreen.V318.Discord.MessageId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) Evergreen.V318.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V318.Drawing.Drawing (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V318.GuildName.GuildName
    , icon : Maybe Evergreen.V318.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V318.MembersAndOwner.MembersAndOwner
            (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V318.Id.Id Evergreen.V318.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V318.Id.Id Evergreen.V318.Id.CustomEmojiId)
    }
