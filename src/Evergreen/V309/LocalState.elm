module Evergreen.V309.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V309.Call
import Evergreen.V309.ChannelDescription
import Evergreen.V309.ChannelName
import Evergreen.V309.Cloudflare
import Evergreen.V309.Discord
import Evergreen.V309.DiscordUserData
import Evergreen.V309.DmChannel
import Evergreen.V309.DmChannelId
import Evergreen.V309.Drawing
import Evergreen.V309.FileStatus
import Evergreen.V309.Game
import Evergreen.V309.GuildName
import Evergreen.V309.Id
import Evergreen.V309.IdArray
import Evergreen.V309.Log
import Evergreen.V309.MembersAndOwner
import Evergreen.V309.Message
import Evergreen.V309.NonemptyDict
import Evergreen.V309.OneToOne
import Evergreen.V309.Pagination
import Evergreen.V309.Postmark
import Evergreen.V309.SecretId
import Evergreen.V309.SessionIdHash
import Evergreen.V309.Slack
import Evergreen.V309.TextEditor
import Evergreen.V309.Thread
import Evergreen.V309.ToBackendLog
import Evergreen.V309.User
import Evergreen.V309.UserSession
import Evergreen.V309.VisibleMessages
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
        Evergreen.V309.NonemptyDict.NonemptyDict
            (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V309.Message.Message Evergreen.V309.Id.ChannelMessageId (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V309.Discord.PartialUser
        , icon : Maybe Evergreen.V309.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V309.Discord.User
        , linkedTo : Evergreen.V309.Id.Id Evergreen.V309.Id.UserId
        , icon : Maybe Evergreen.V309.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V309.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V309.Discord.User
        , linkedTo : Evergreen.V309.Id.Id Evergreen.V309.Id.UserId
        , icon : Maybe Evergreen.V309.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V309.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V309.Message.Message Evergreen.V309.Id.ChannelMessageId (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V309.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V309.MembersAndOwner.MembersAndOwner
            (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V309.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V309.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V309.Id.Id Evergreen.V309.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V309.GuildName.GuildName
    , owner : Evergreen.V309.Id.Id Evergreen.V309.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V309.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V309.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V309.Call.CallId
    | ConnectedToCall
        Evergreen.V309.Call.CallId
        { sessionId : Evergreen.V309.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V309.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V309.Call.RemoteCallData
    , currentlyViewing : Maybe ( Evergreen.V309.Id.AnyGuildOrDmId, Evergreen.V309.Id.ThreadRoute )
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameSwedishStatus
    = WordSpellingGameSwedishStatus_NotLoaded
    | WordSpellingGameSwedishStatus_Loading
    | WordSpellingGameSwedishStatus_Error Effect.Http.Error
    | WordSpellingGameSwedishStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V309.Id.Id Evergreen.V309.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V309.Id.Id Evergreen.V309.Id.UserId
    , name : Evergreen.V309.ChannelName.ChannelName
    , description : Evergreen.V309.ChannelDescription.ChannelDescription
    , messages : Evergreen.V309.IdArray.IdArray Evergreen.V309.Id.ChannelMessageId (Evergreen.V309.Message.MessageState Evergreen.V309.Id.ChannelMessageId (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId))
    , visibleMessages : Evergreen.V309.VisibleMessages.VisibleMessages Evergreen.V309.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) (Evergreen.V309.Thread.LastTypedAt Evergreen.V309.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) Evergreen.V309.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V309.Drawing.Drawing (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) Evergreen.V309.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V309.Id.Id Evergreen.V309.Id.UserId
    , name : Evergreen.V309.GuildName.GuildName
    , icon : Maybe Evergreen.V309.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V309.MembersAndOwner.MembersAndOwner
            (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V309.SecretId.SecretId Evergreen.V309.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V309.Id.Id Evergreen.V309.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V309.ChannelName.ChannelName
    , description : Evergreen.V309.ChannelDescription.ChannelDescription
    , messages : Evergreen.V309.IdArray.IdArray Evergreen.V309.Id.ChannelMessageId (Evergreen.V309.Message.MessageState Evergreen.V309.Id.ChannelMessageId (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId))
    , visibleMessages : Evergreen.V309.VisibleMessages.VisibleMessages Evergreen.V309.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Evergreen.V309.Thread.LastTypedAt Evergreen.V309.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) Evergreen.V309.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V309.Drawing.Drawing (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V309.GuildName.GuildName
    , icon : Maybe Evergreen.V309.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V309.MembersAndOwner.MembersAndOwner
            (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V309.Id.Id Evergreen.V309.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V309.Id.Id Evergreen.V309.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V309.NonemptyDict.NonemptyDict (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) Evergreen.V309.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V309.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V309.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V309.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V309.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V309.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V309.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V309.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V309.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V309.SessionIdHash.SessionIdHash (Evergreen.V309.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V309.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V309.SessionIdHash.SessionIdHash Evergreen.V309.UserSession.UserSession
    , wordSpellingGameSwedish : WordSpellingGameSwedishStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) Evergreen.V309.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId) Evergreen.V309.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V309.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V309.SessionIdHash.SessionIdHash Evergreen.V309.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V309.TextEditor.LocalState
    , calls : Evergreen.V309.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V309.Id.Id Evergreen.V309.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V309.Id.Id Evergreen.V309.Id.UserId
    , name : Evergreen.V309.ChannelName.ChannelName
    , description : Evergreen.V309.ChannelDescription.ChannelDescription
    , messages : Evergreen.V309.IdArray.IdArray Evergreen.V309.Id.ChannelMessageId (Evergreen.V309.Message.Message Evergreen.V309.Id.ChannelMessageId (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) (Evergreen.V309.Thread.LastTypedAt Evergreen.V309.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) Evergreen.V309.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V309.Drawing.Drawing (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) Evergreen.V309.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V309.Id.Id Evergreen.V309.Id.UserId
    , name : Evergreen.V309.GuildName.GuildName
    , icon : Maybe Evergreen.V309.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V309.MembersAndOwner.MembersAndOwner
            (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V309.SecretId.SecretId Evergreen.V309.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V309.Id.Id Evergreen.V309.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V309.ChannelName.ChannelName
    , description : Evergreen.V309.ChannelDescription.ChannelDescription
    , messages : Evergreen.V309.IdArray.IdArray Evergreen.V309.Id.ChannelMessageId (Evergreen.V309.Message.Message Evergreen.V309.Id.ChannelMessageId (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Evergreen.V309.Thread.LastTypedAt Evergreen.V309.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V309.OneToOne.OneToOne (Evergreen.V309.Discord.Id Evergreen.V309.Discord.MessageId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) Evergreen.V309.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V309.Drawing.Drawing (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V309.GuildName.GuildName
    , icon : Maybe Evergreen.V309.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V309.MembersAndOwner.MembersAndOwner
            (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V309.Id.Id Evergreen.V309.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V309.Id.Id Evergreen.V309.Id.CustomEmojiId)
    }
