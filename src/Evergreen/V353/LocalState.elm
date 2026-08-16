module Evergreen.V353.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V353.Call
import Evergreen.V353.ChannelDescription
import Evergreen.V353.ChannelName
import Evergreen.V353.Discord
import Evergreen.V353.DiscordUserData
import Evergreen.V353.DmChannel
import Evergreen.V353.DmChannelId
import Evergreen.V353.Drawing
import Evergreen.V353.FileStatus
import Evergreen.V353.Game
import Evergreen.V353.GuildName
import Evergreen.V353.Id
import Evergreen.V353.IdArray
import Evergreen.V353.Log
import Evergreen.V353.MembersAndOwner
import Evergreen.V353.Message
import Evergreen.V353.MessageArray
import Evergreen.V353.NonemptyDict
import Evergreen.V353.OneToOne
import Evergreen.V353.Pagination
import Evergreen.V353.Postmark
import Evergreen.V353.SecretId
import Evergreen.V353.SessionIdHash
import Evergreen.V353.Slack
import Evergreen.V353.TextEditor
import Evergreen.V353.Thread
import Evergreen.V353.ToBackendLog
import Evergreen.V353.User
import Evergreen.V353.UserSession
import Evergreen.V353.VisibleMessages
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
        Evergreen.V353.NonemptyDict.NonemptyDict
            (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V353.Message.Message Evergreen.V353.Id.ChannelMessageId (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V353.Discord.PartialUser
        , icon : Maybe Evergreen.V353.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V353.Discord.User
        , linkedTo : Evergreen.V353.Id.Id Evergreen.V353.Id.UserId
        , icon : Maybe Evergreen.V353.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V353.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V353.Discord.User
        , linkedTo : Evergreen.V353.Id.Id Evergreen.V353.Id.UserId
        , icon : Maybe Evergreen.V353.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V353.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V353.Message.Message Evergreen.V353.Id.ChannelMessageId (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId))
    , permissionOverwrites : List Evergreen.V353.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V353.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V353.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V353.MembersAndOwner.MembersAndOwner
            (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V353.Discord.Id Evergreen.V353.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V353.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V353.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V353.Id.Id Evergreen.V353.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V353.GuildName.GuildName
    , owner : Evergreen.V353.Id.Id Evergreen.V353.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V353.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V353.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V353.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V353.Call.RemoteCallData
    , currentlyViewing : Evergreen.V353.UserSession.Viewing
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V353.Id.Id Evergreen.V353.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V353.Id.Id Evergreen.V353.Id.UserId
    , name : Evergreen.V353.ChannelName.ChannelName
    , description : Evergreen.V353.ChannelDescription.ChannelDescription
    , messages : Evergreen.V353.MessageArray.MessageArray Evergreen.V353.Id.ChannelMessageId (Evergreen.V353.Message.Message Evergreen.V353.Id.ChannelMessageId (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId))
    , visibleMessages : Evergreen.V353.VisibleMessages.VisibleMessages Evergreen.V353.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) (Evergreen.V353.Thread.LastTypedAt Evergreen.V353.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) Evergreen.V353.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V353.Drawing.Drawing (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) Evergreen.V353.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V353.Id.Id Evergreen.V353.Id.UserId
    , name : Evergreen.V353.GuildName.GuildName
    , icon : Maybe Evergreen.V353.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V353.MembersAndOwner.MembersAndOwner
            (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V353.SecretId.SecretId Evergreen.V353.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V353.Id.Id Evergreen.V353.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V353.ChannelName.ChannelName
    , description : Evergreen.V353.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V353.MessageArray.MessageArray Evergreen.V353.Id.ChannelMessageId (Evergreen.V353.Message.Message Evergreen.V353.Id.ChannelMessageId (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId))
    , visibleMessages : Evergreen.V353.VisibleMessages.VisibleMessages Evergreen.V353.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Thread.LastTypedAt Evergreen.V353.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) Evergreen.V353.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V353.Drawing.Drawing (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId))
    , permissionOverwrites : List Evergreen.V353.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V353.GuildName.GuildName
    , icon : Maybe Evergreen.V353.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V353.MembersAndOwner.MembersAndOwner
            (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V353.Discord.Id Evergreen.V353.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V353.Id.Id Evergreen.V353.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V353.Id.Id Evergreen.V353.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V353.NonemptyDict.NonemptyDict (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) Evergreen.V353.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V353.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V353.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V353.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V353.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V353.SessionIdHash.SessionIdHash (Evergreen.V353.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V353.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V353.SessionIdHash.SessionIdHash Evergreen.V353.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) Evergreen.V353.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId) Evergreen.V353.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V353.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V353.SessionIdHash.SessionIdHash Evergreen.V353.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V353.TextEditor.LocalState
    , calls : Evergreen.V353.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V353.Id.Id Evergreen.V353.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V353.Id.Id Evergreen.V353.Id.UserId
    , name : Evergreen.V353.ChannelName.ChannelName
    , description : Evergreen.V353.ChannelDescription.ChannelDescription
    , messages : Evergreen.V353.IdArray.IdArray Evergreen.V353.Id.ChannelMessageId (Evergreen.V353.Message.Message Evergreen.V353.Id.ChannelMessageId (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) (Evergreen.V353.Thread.LastTypedAt Evergreen.V353.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) Evergreen.V353.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V353.Drawing.Drawing (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) Evergreen.V353.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V353.Id.Id Evergreen.V353.Id.UserId
    , name : Evergreen.V353.GuildName.GuildName
    , icon : Maybe Evergreen.V353.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V353.MembersAndOwner.MembersAndOwner
            (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V353.SecretId.SecretId Evergreen.V353.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V353.Id.Id Evergreen.V353.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V353.ChannelName.ChannelName
    , description : Evergreen.V353.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V353.IdArray.IdArray Evergreen.V353.Id.ChannelMessageId (Evergreen.V353.Message.Message Evergreen.V353.Id.ChannelMessageId (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Thread.LastTypedAt Evergreen.V353.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V353.OneToOne.OneToOne (Evergreen.V353.Discord.Id Evergreen.V353.Discord.MessageId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) Evergreen.V353.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V353.Drawing.Drawing (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId))
    , permissionOverwrites : List Evergreen.V353.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V353.GuildName.GuildName
    , icon : Maybe Evergreen.V353.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V353.MembersAndOwner.MembersAndOwner
            (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V353.Discord.Id Evergreen.V353.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V353.Id.Id Evergreen.V353.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V353.Id.Id Evergreen.V353.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId
    , messages : List Evergreen.V353.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V353.Discord.Message
    , threads : List DiscordThreadReload
    }
