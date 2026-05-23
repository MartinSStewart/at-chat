module Evergreen.V250.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V250.Call
import Evergreen.V250.ChannelDescription
import Evergreen.V250.ChannelName
import Evergreen.V250.Discord
import Evergreen.V250.DiscordUserData
import Evergreen.V250.DmChannel
import Evergreen.V250.FileStatus
import Evergreen.V250.GuildName
import Evergreen.V250.Id
import Evergreen.V250.Log
import Evergreen.V250.MembersAndOwner
import Evergreen.V250.Message
import Evergreen.V250.NonemptyDict
import Evergreen.V250.OneToOne
import Evergreen.V250.Pagination
import Evergreen.V250.Postmark
import Evergreen.V250.SecretId
import Evergreen.V250.SessionIdHash
import Evergreen.V250.Slack
import Evergreen.V250.TextEditor
import Evergreen.V250.Thread
import Evergreen.V250.ToBackendLog
import Evergreen.V250.User
import Evergreen.V250.UserSession
import Evergreen.V250.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V250.NonemptyDict.NonemptyDict
            (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V250.Message.Message Evergreen.V250.Id.ChannelMessageId (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V250.Discord.PartialUser
        , icon : Maybe Evergreen.V250.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V250.Discord.User
        , linkedTo : Evergreen.V250.Id.Id Evergreen.V250.Id.UserId
        , icon : Maybe Evergreen.V250.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V250.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V250.Discord.User
        , linkedTo : Evergreen.V250.Id.Id Evergreen.V250.Id.UserId
        , icon : Maybe Evergreen.V250.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V250.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V250.Message.Message Evergreen.V250.Id.ChannelMessageId (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V250.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V250.MembersAndOwner.MembersAndOwner
            (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V250.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V250.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V250.Id.Id Evergreen.V250.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V250.GuildName.GuildName
    , owner : Evergreen.V250.Id.Id Evergreen.V250.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V250.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V250.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : Maybe Evergreen.V250.Call.RoomId
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V250.Id.Id Evergreen.V250.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V250.Id.Id Evergreen.V250.Id.UserId
    , name : Evergreen.V250.ChannelName.ChannelName
    , description : Evergreen.V250.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V250.Message.MessageState Evergreen.V250.Id.ChannelMessageId (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId))
    , visibleMessages : Evergreen.V250.VisibleMessages.VisibleMessages Evergreen.V250.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) (Evergreen.V250.Thread.LastTypedAt Evergreen.V250.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) Evergreen.V250.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V250.Id.Id Evergreen.V250.Id.UserId
    , name : Evergreen.V250.GuildName.GuildName
    , icon : Maybe Evergreen.V250.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V250.MembersAndOwner.MembersAndOwner
            (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V250.SecretId.SecretId Evergreen.V250.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V250.Id.Id Evergreen.V250.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V250.ChannelName.ChannelName
    , description : Evergreen.V250.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V250.Message.MessageState Evergreen.V250.Id.ChannelMessageId (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId))
    , visibleMessages : Evergreen.V250.VisibleMessages.VisibleMessages Evergreen.V250.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Evergreen.V250.Thread.LastTypedAt Evergreen.V250.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) Evergreen.V250.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V250.GuildName.GuildName
    , icon : Maybe Evergreen.V250.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V250.MembersAndOwner.MembersAndOwner
            (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V250.Id.Id Evergreen.V250.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V250.Id.Id Evergreen.V250.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V250.NonemptyDict.NonemptyDict (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) Evergreen.V250.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V250.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareTurnApiToken : Maybe String
    , postmarkKey : Evergreen.V250.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V250.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V250.SessionIdHash.SessionIdHash (Evergreen.V250.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V250.ToBackendLog.ToBackendLogData
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
    , guilds : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) Evergreen.V250.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId) Evergreen.V250.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V250.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V250.SessionIdHash.SessionIdHash Evergreen.V250.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V250.TextEditor.LocalState
    , calls : Evergreen.V250.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V250.Id.Id Evergreen.V250.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V250.Id.Id Evergreen.V250.Id.UserId
    , name : Evergreen.V250.ChannelName.ChannelName
    , description : Evergreen.V250.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V250.Message.Message Evergreen.V250.Id.ChannelMessageId (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) (Evergreen.V250.Thread.LastTypedAt Evergreen.V250.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) Evergreen.V250.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V250.Id.Id Evergreen.V250.Id.UserId
    , name : Evergreen.V250.GuildName.GuildName
    , icon : Maybe Evergreen.V250.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V250.MembersAndOwner.MembersAndOwner
            (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V250.SecretId.SecretId Evergreen.V250.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V250.Id.Id Evergreen.V250.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V250.ChannelName.ChannelName
    , description : Evergreen.V250.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V250.Message.Message Evergreen.V250.Id.ChannelMessageId (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Evergreen.V250.Thread.LastTypedAt Evergreen.V250.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V250.OneToOne.OneToOne (Evergreen.V250.Discord.Id Evergreen.V250.Discord.MessageId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) Evergreen.V250.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V250.GuildName.GuildName
    , icon : Maybe Evergreen.V250.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V250.MembersAndOwner.MembersAndOwner
            (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V250.Id.Id Evergreen.V250.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V250.Id.Id Evergreen.V250.Id.CustomEmojiId)
    }
