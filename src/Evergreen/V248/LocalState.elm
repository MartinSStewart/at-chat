module Evergreen.V248.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V248.Call
import Evergreen.V248.ChannelDescription
import Evergreen.V248.ChannelName
import Evergreen.V248.Discord
import Evergreen.V248.DiscordUserData
import Evergreen.V248.DmChannel
import Evergreen.V248.FileStatus
import Evergreen.V248.GuildName
import Evergreen.V248.Id
import Evergreen.V248.Log
import Evergreen.V248.MembersAndOwner
import Evergreen.V248.Message
import Evergreen.V248.NonemptyDict
import Evergreen.V248.OneToOne
import Evergreen.V248.Pagination
import Evergreen.V248.Postmark
import Evergreen.V248.SecretId
import Evergreen.V248.SessionIdHash
import Evergreen.V248.Slack
import Evergreen.V248.TextEditor
import Evergreen.V248.Thread
import Evergreen.V248.ToBackendLog
import Evergreen.V248.User
import Evergreen.V248.UserSession
import Evergreen.V248.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V248.NonemptyDict.NonemptyDict
            (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V248.Message.Message Evergreen.V248.Id.ChannelMessageId (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V248.Discord.PartialUser
        , icon : Maybe Evergreen.V248.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V248.Discord.User
        , linkedTo : Evergreen.V248.Id.Id Evergreen.V248.Id.UserId
        , icon : Maybe Evergreen.V248.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V248.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V248.Discord.User
        , linkedTo : Evergreen.V248.Id.Id Evergreen.V248.Id.UserId
        , icon : Maybe Evergreen.V248.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V248.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V248.Message.Message Evergreen.V248.Id.ChannelMessageId (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V248.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V248.MembersAndOwner.MembersAndOwner
            (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V248.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V248.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V248.Id.Id Evergreen.V248.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V248.GuildName.GuildName
    , owner : Evergreen.V248.Id.Id Evergreen.V248.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V248.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V248.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : Maybe Evergreen.V248.Call.RoomId
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V248.Id.Id Evergreen.V248.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V248.Id.Id Evergreen.V248.Id.UserId
    , name : Evergreen.V248.ChannelName.ChannelName
    , description : Evergreen.V248.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V248.Message.MessageState Evergreen.V248.Id.ChannelMessageId (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId))
    , visibleMessages : Evergreen.V248.VisibleMessages.VisibleMessages Evergreen.V248.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) (Evergreen.V248.Thread.LastTypedAt Evergreen.V248.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) Evergreen.V248.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V248.Id.Id Evergreen.V248.Id.UserId
    , name : Evergreen.V248.GuildName.GuildName
    , icon : Maybe Evergreen.V248.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V248.MembersAndOwner.MembersAndOwner
            (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V248.SecretId.SecretId Evergreen.V248.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V248.Id.Id Evergreen.V248.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V248.ChannelName.ChannelName
    , description : Evergreen.V248.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V248.Message.MessageState Evergreen.V248.Id.ChannelMessageId (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId))
    , visibleMessages : Evergreen.V248.VisibleMessages.VisibleMessages Evergreen.V248.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Evergreen.V248.Thread.LastTypedAt Evergreen.V248.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) Evergreen.V248.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V248.GuildName.GuildName
    , icon : Maybe Evergreen.V248.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V248.MembersAndOwner.MembersAndOwner
            (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V248.Id.Id Evergreen.V248.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V248.Id.Id Evergreen.V248.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V248.NonemptyDict.NonemptyDict (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) Evergreen.V248.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V248.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareTurnApiToken : Maybe String
    , postmarkKey : Evergreen.V248.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V248.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V248.SessionIdHash.SessionIdHash (Evergreen.V248.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V248.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array.Array WebsocketClosedEvent
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) Evergreen.V248.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId) Evergreen.V248.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V248.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V248.SessionIdHash.SessionIdHash Evergreen.V248.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V248.TextEditor.LocalState
    , calls : Evergreen.V248.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V248.Id.Id Evergreen.V248.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V248.Id.Id Evergreen.V248.Id.UserId
    , name : Evergreen.V248.ChannelName.ChannelName
    , description : Evergreen.V248.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V248.Message.Message Evergreen.V248.Id.ChannelMessageId (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) (Evergreen.V248.Thread.LastTypedAt Evergreen.V248.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) Evergreen.V248.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V248.Id.Id Evergreen.V248.Id.UserId
    , name : Evergreen.V248.GuildName.GuildName
    , icon : Maybe Evergreen.V248.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V248.MembersAndOwner.MembersAndOwner
            (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V248.SecretId.SecretId Evergreen.V248.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V248.Id.Id Evergreen.V248.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V248.ChannelName.ChannelName
    , description : Evergreen.V248.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V248.Message.Message Evergreen.V248.Id.ChannelMessageId (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Evergreen.V248.Thread.LastTypedAt Evergreen.V248.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V248.OneToOne.OneToOne (Evergreen.V248.Discord.Id Evergreen.V248.Discord.MessageId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) Evergreen.V248.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V248.GuildName.GuildName
    , icon : Maybe Evergreen.V248.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V248.MembersAndOwner.MembersAndOwner
            (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V248.Id.Id Evergreen.V248.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V248.Id.Id Evergreen.V248.Id.CustomEmojiId)
    }
