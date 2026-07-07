module Evergreen.V305.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V305.Call
import Evergreen.V305.ChannelDescription
import Evergreen.V305.ChannelName
import Evergreen.V305.Cloudflare
import Evergreen.V305.Discord
import Evergreen.V305.DiscordUserData
import Evergreen.V305.DmChannel
import Evergreen.V305.DmChannelId
import Evergreen.V305.Drawing
import Evergreen.V305.FileStatus
import Evergreen.V305.Game
import Evergreen.V305.GuildName
import Evergreen.V305.Id
import Evergreen.V305.IdArray
import Evergreen.V305.Log
import Evergreen.V305.MembersAndOwner
import Evergreen.V305.Message
import Evergreen.V305.NonemptyDict
import Evergreen.V305.OneToOne
import Evergreen.V305.Pagination
import Evergreen.V305.Postmark
import Evergreen.V305.SecretId
import Evergreen.V305.SessionIdHash
import Evergreen.V305.Slack
import Evergreen.V305.TextEditor
import Evergreen.V305.Thread
import Evergreen.V305.ToBackendLog
import Evergreen.V305.User
import Evergreen.V305.UserSession
import Evergreen.V305.VisibleMessages
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
        Evergreen.V305.NonemptyDict.NonemptyDict
            (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V305.Message.Message Evergreen.V305.Id.ChannelMessageId (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V305.Discord.PartialUser
        , icon : Maybe Evergreen.V305.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V305.Discord.User
        , linkedTo : Evergreen.V305.Id.Id Evergreen.V305.Id.UserId
        , icon : Maybe Evergreen.V305.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V305.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V305.Discord.User
        , linkedTo : Evergreen.V305.Id.Id Evergreen.V305.Id.UserId
        , icon : Maybe Evergreen.V305.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V305.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V305.Message.Message Evergreen.V305.Id.ChannelMessageId (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V305.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V305.Discord.Id Evergreen.V305.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V305.MembersAndOwner.MembersAndOwner
            (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V305.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V305.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V305.Id.Id Evergreen.V305.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V305.GuildName.GuildName
    , owner : Evergreen.V305.Id.Id Evergreen.V305.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V305.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V305.Discord.Id Evergreen.V305.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V305.Discord.Id Evergreen.V305.Discord.GuildId) (Evergreen.V305.Discord.Id Evergreen.V305.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V305.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectingToCall Evergreen.V305.Call.CallId
    | ConnectedToCall
        Evergreen.V305.Call.CallId
        { sessionId : Evergreen.V305.Cloudflare.RealtimeSessionId
        , trackNames : List Evergreen.V305.Cloudflare.TrackName
        , pullTracksReady : Bool
        }


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V305.Call.RemoteCallData
    , currentlyViewing : Maybe ( Evergreen.V305.Id.AnyGuildOrDmId, Evergreen.V305.Id.ThreadRoute )
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameSwedishStatus
    = WordSpellingGameSwedishStatus_NotLoaded
    | WordSpellingGameSwedishStatus_Loading
    | WordSpellingGameSwedishStatus_Error Effect.Http.Error
    | WordSpellingGameSwedishStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V305.Id.Id Evergreen.V305.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V305.Id.Id Evergreen.V305.Id.UserId
    , name : Evergreen.V305.ChannelName.ChannelName
    , description : Evergreen.V305.ChannelDescription.ChannelDescription
    , messages : Evergreen.V305.IdArray.IdArray Evergreen.V305.Id.ChannelMessageId (Evergreen.V305.Message.MessageState Evergreen.V305.Id.ChannelMessageId (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId))
    , visibleMessages : Evergreen.V305.VisibleMessages.VisibleMessages Evergreen.V305.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId) (Evergreen.V305.Thread.LastTypedAt Evergreen.V305.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId) Evergreen.V305.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V305.Drawing.Drawing (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId) Evergreen.V305.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V305.Id.Id Evergreen.V305.Id.UserId
    , name : Evergreen.V305.GuildName.GuildName
    , icon : Maybe Evergreen.V305.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V305.MembersAndOwner.MembersAndOwner
            (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V305.SecretId.SecretId Evergreen.V305.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V305.Id.Id Evergreen.V305.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V305.ChannelName.ChannelName
    , description : Evergreen.V305.ChannelDescription.ChannelDescription
    , messages : Evergreen.V305.IdArray.IdArray Evergreen.V305.Id.ChannelMessageId (Evergreen.V305.Message.MessageState Evergreen.V305.Id.ChannelMessageId (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId))
    , visibleMessages : Evergreen.V305.VisibleMessages.VisibleMessages Evergreen.V305.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId) (Evergreen.V305.Thread.LastTypedAt Evergreen.V305.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId) Evergreen.V305.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V305.Drawing.Drawing (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId))
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V305.GuildName.GuildName
    , icon : Maybe Evergreen.V305.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V305.Discord.Id Evergreen.V305.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V305.MembersAndOwner.MembersAndOwner
            (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V305.Id.Id Evergreen.V305.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V305.Id.Id Evergreen.V305.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V305.NonemptyDict.NonemptyDict (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId) Evergreen.V305.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V305.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V305.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V305.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V305.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V305.Cloudflare.AnalyticsApiToken
    , postmarkKey : Evergreen.V305.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V305.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V305.Discord.Id Evergreen.V305.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V305.Discord.Id Evergreen.V305.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V305.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V305.SessionIdHash.SessionIdHash (Evergreen.V305.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V305.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V305.SessionIdHash.SessionIdHash Evergreen.V305.UserSession.UserSession
    , wordSpellingGameSwedish : WordSpellingGameSwedishStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V305.Discord.Id Evergreen.V305.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId) Evergreen.V305.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V305.Discord.Id Evergreen.V305.Discord.PrivateChannelId) Evergreen.V305.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V305.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V305.SessionIdHash.SessionIdHash Evergreen.V305.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V305.TextEditor.LocalState
    , calls : Evergreen.V305.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V305.Id.Id Evergreen.V305.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V305.Id.Id Evergreen.V305.Id.UserId
    , name : Evergreen.V305.ChannelName.ChannelName
    , description : Evergreen.V305.ChannelDescription.ChannelDescription
    , messages : Evergreen.V305.IdArray.IdArray Evergreen.V305.Id.ChannelMessageId (Evergreen.V305.Message.Message Evergreen.V305.Id.ChannelMessageId (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId) (Evergreen.V305.Thread.LastTypedAt Evergreen.V305.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId) Evergreen.V305.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V305.Drawing.Drawing (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId) Evergreen.V305.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V305.Id.Id Evergreen.V305.Id.UserId
    , name : Evergreen.V305.GuildName.GuildName
    , icon : Maybe Evergreen.V305.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V305.MembersAndOwner.MembersAndOwner
            (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V305.SecretId.SecretId Evergreen.V305.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V305.Id.Id Evergreen.V305.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V305.ChannelName.ChannelName
    , description : Evergreen.V305.ChannelDescription.ChannelDescription
    , messages : Evergreen.V305.IdArray.IdArray Evergreen.V305.Id.ChannelMessageId (Evergreen.V305.Message.Message Evergreen.V305.Id.ChannelMessageId (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId) (Evergreen.V305.Thread.LastTypedAt Evergreen.V305.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V305.OneToOne.OneToOne (Evergreen.V305.Discord.Id Evergreen.V305.Discord.MessageId) (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId) Evergreen.V305.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V305.Drawing.Drawing (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId))
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V305.GuildName.GuildName
    , icon : Maybe Evergreen.V305.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V305.Discord.Id Evergreen.V305.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V305.MembersAndOwner.MembersAndOwner
            (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V305.Id.Id Evergreen.V305.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V305.Id.Id Evergreen.V305.Id.CustomEmojiId)
    }
