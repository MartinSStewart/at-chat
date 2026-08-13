module Evergreen.V351.LocalState exposing (..)

import Array
import Date
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V351.Call
import Evergreen.V351.ChannelDescription
import Evergreen.V351.ChannelName
import Evergreen.V351.Discord
import Evergreen.V351.DiscordUserData
import Evergreen.V351.DmChannel
import Evergreen.V351.DmChannelId
import Evergreen.V351.Drawing
import Evergreen.V351.FileStatus
import Evergreen.V351.Game
import Evergreen.V351.GuildName
import Evergreen.V351.Id
import Evergreen.V351.IdArray
import Evergreen.V351.Log
import Evergreen.V351.MembersAndOwner
import Evergreen.V351.Message
import Evergreen.V351.MessageArray
import Evergreen.V351.NonemptyDict
import Evergreen.V351.OneToOne
import Evergreen.V351.Pagination
import Evergreen.V351.Postmark
import Evergreen.V351.SecretId
import Evergreen.V351.SessionIdHash
import Evergreen.V351.Slack
import Evergreen.V351.TextEditor
import Evergreen.V351.Thread
import Evergreen.V351.ToBackendLog
import Evergreen.V351.User
import Evergreen.V351.UserSession
import Evergreen.V351.VisibleMessages
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
        Evergreen.V351.NonemptyDict.NonemptyDict
            (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V351.Message.Message Evergreen.V351.Id.ChannelMessageId (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V351.Discord.PartialUser
        , icon : Maybe Evergreen.V351.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V351.Discord.User
        , linkedTo : Evergreen.V351.Id.Id Evergreen.V351.Id.UserId
        , icon : Maybe Evergreen.V351.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V351.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V351.Discord.User
        , linkedTo : Evergreen.V351.Id.Id Evergreen.V351.Id.UserId
        , icon : Maybe Evergreen.V351.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V351.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V351.Message.Message Evergreen.V351.Id.ChannelMessageId (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId))
    , permissionOverwrites : List Evergreen.V351.Discord.Overwrite
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Evergreen.V351.Discord.Permissions
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V351.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V351.MembersAndOwner.MembersAndOwner
            (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V351.Discord.Id Evergreen.V351.Discord.RoleId)
            }
    , roles : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.RoleId) DiscordRole
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V351.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V351.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V351.Id.Id Evergreen.V351.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V351.GuildName.GuildName
    , owner : Evergreen.V351.Id.Id Evergreen.V351.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V351.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V351.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type CallStatus
    = NotInCall
    | ConnectedToCall Evergreen.V351.Call.CallId


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Evergreen.V351.Call.RemoteCallData
    , currentlyViewing : Evergreen.V351.UserSession.Viewing
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix


type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Effect.Http.Error
    | WordSpellingGameStatus_Loaded


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V351.Id.Id Evergreen.V351.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V351.Id.Id Evergreen.V351.Id.UserId
    , name : Evergreen.V351.ChannelName.ChannelName
    , description : Evergreen.V351.ChannelDescription.ChannelDescription
    , messages : Evergreen.V351.MessageArray.MessageArray Evergreen.V351.Id.ChannelMessageId (Evergreen.V351.Message.Message Evergreen.V351.Id.ChannelMessageId (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId))
    , visibleMessages : Evergreen.V351.VisibleMessages.VisibleMessages Evergreen.V351.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) (Evergreen.V351.Thread.LastTypedAt Evergreen.V351.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) Evergreen.V351.Thread.FrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V351.Drawing.Drawing (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) Evergreen.V351.Game.MatchData
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V351.Id.Id Evergreen.V351.Id.UserId
    , name : Evergreen.V351.GuildName.GuildName
    , icon : Maybe Evergreen.V351.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V351.MembersAndOwner.MembersAndOwner
            (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V351.SecretId.SecretId Evergreen.V351.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V351.Id.Id Evergreen.V351.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V351.ChannelName.ChannelName
    , description : Evergreen.V351.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V351.MessageArray.MessageArray Evergreen.V351.Id.ChannelMessageId (Evergreen.V351.Message.Message Evergreen.V351.Id.ChannelMessageId (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId))
    , visibleMessages : Evergreen.V351.VisibleMessages.VisibleMessages Evergreen.V351.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Thread.LastTypedAt Evergreen.V351.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) Evergreen.V351.Thread.DiscordFrontendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V351.Drawing.Drawing (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId))
    , permissionOverwrites : List Evergreen.V351.Discord.Overwrite
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V351.GuildName.GuildName
    , icon : Maybe Evergreen.V351.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V351.MembersAndOwner.MembersAndOwner
            (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V351.Discord.Id Evergreen.V351.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V351.Id.Id Evergreen.V351.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V351.Id.Id Evergreen.V351.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.RoleId) DiscordRole
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V351.NonemptyDict.NonemptyDict (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) Evergreen.V351.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V351.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V351.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V351.DmChannelId.DmChannelId AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V351.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V351.SessionIdHash.SessionIdHash (Evergreen.V351.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V351.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V351.SessionIdHash.SessionIdHash Evergreen.V351.UserSession.UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) Evergreen.V351.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId) Evergreen.V351.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V351.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V351.SessionIdHash.SessionIdHash Evergreen.V351.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V351.TextEditor.LocalState
    , calls : Evergreen.V351.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V351.Id.Id Evergreen.V351.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V351.Id.Id Evergreen.V351.Id.UserId
    , name : Evergreen.V351.ChannelName.ChannelName
    , description : Evergreen.V351.ChannelDescription.ChannelDescription
    , messages : Evergreen.V351.IdArray.IdArray Evergreen.V351.Id.ChannelMessageId (Evergreen.V351.Message.Message Evergreen.V351.Id.ChannelMessageId (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) (Evergreen.V351.Thread.LastTypedAt Evergreen.V351.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) Evergreen.V351.Thread.BackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V351.Drawing.Drawing (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId))
    , games : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) Evergreen.V351.Game.BackendGameData
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V351.Id.Id Evergreen.V351.Id.UserId
    , name : Evergreen.V351.GuildName.GuildName
    , icon : Maybe Evergreen.V351.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V351.MembersAndOwner.MembersAndOwner
            (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V351.SecretId.SecretId Evergreen.V351.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V351.Id.Id Evergreen.V351.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V351.ChannelName.ChannelName
    , description : Evergreen.V351.ChannelDescription.ChannelDescription
    , isForum : Bool
    , messages : Evergreen.V351.IdArray.IdArray Evergreen.V351.Id.ChannelMessageId (Evergreen.V351.Message.Message Evergreen.V351.Id.ChannelMessageId (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Thread.LastTypedAt Evergreen.V351.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V351.OneToOne.OneToOne (Evergreen.V351.Discord.Id Evergreen.V351.Discord.MessageId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) Evergreen.V351.Thread.DiscordBackendThread
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V351.Drawing.Drawing (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId))
    , permissionOverwrites : List Evergreen.V351.Discord.Overwrite
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V351.GuildName.GuildName
    , icon : Maybe Evergreen.V351.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V351.MembersAndOwner.MembersAndOwner
            (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V351.Discord.Id Evergreen.V351.Discord.RoleId)
            }
    , stickers : SeqSet.SeqSet (Evergreen.V351.Id.Id Evergreen.V351.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V351.Id.Id Evergreen.V351.Id.CustomEmojiId)
    , roles : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.RoleId) DiscordRole
    }


type alias DiscordThreadReload =
    { threadId : Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId
    , messages : List Evergreen.V351.Discord.Message
    }


type alias DiscordChannelReload =
    { messages : List Evergreen.V351.Discord.Message
    , threads : List DiscordThreadReload
    }
