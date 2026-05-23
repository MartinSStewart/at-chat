module Evergreen.V247.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V247.Call
import Evergreen.V247.ChannelDescription
import Evergreen.V247.ChannelName
import Evergreen.V247.Discord
import Evergreen.V247.DiscordUserData
import Evergreen.V247.DmChannel
import Evergreen.V247.FileStatus
import Evergreen.V247.GuildName
import Evergreen.V247.Id
import Evergreen.V247.Log
import Evergreen.V247.MembersAndOwner
import Evergreen.V247.Message
import Evergreen.V247.NonemptyDict
import Evergreen.V247.OneToOne
import Evergreen.V247.Pagination
import Evergreen.V247.Postmark
import Evergreen.V247.SecretId
import Evergreen.V247.SessionIdHash
import Evergreen.V247.Slack
import Evergreen.V247.TextEditor
import Evergreen.V247.Thread
import Evergreen.V247.ToBackendLog
import Evergreen.V247.User
import Evergreen.V247.UserSession
import Evergreen.V247.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V247.NonemptyDict.NonemptyDict
            (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V247.Message.Message Evergreen.V247.Id.ChannelMessageId (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V247.Discord.PartialUser
        , icon : Maybe Evergreen.V247.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V247.Discord.User
        , linkedTo : Evergreen.V247.Id.Id Evergreen.V247.Id.UserId
        , icon : Maybe Evergreen.V247.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V247.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V247.Discord.User
        , linkedTo : Evergreen.V247.Id.Id Evergreen.V247.Id.UserId
        , icon : Maybe Evergreen.V247.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V247.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V247.Message.Message Evergreen.V247.Id.ChannelMessageId (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V247.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V247.MembersAndOwner.MembersAndOwner
            (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V247.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V247.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V247.Id.Id Evergreen.V247.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V247.GuildName.GuildName
    , owner : Evergreen.V247.Id.Id Evergreen.V247.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V247.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V247.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : Maybe Evergreen.V247.Call.RoomId
    }


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) Effect.Time.Posix
    | WebsocketClosed_ListenCloseEvent (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) String Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V247.Id.Id Evergreen.V247.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V247.Id.Id Evergreen.V247.Id.UserId
    , name : Evergreen.V247.ChannelName.ChannelName
    , description : Evergreen.V247.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V247.Message.MessageState Evergreen.V247.Id.ChannelMessageId (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId))
    , visibleMessages : Evergreen.V247.VisibleMessages.VisibleMessages Evergreen.V247.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) (Evergreen.V247.Thread.LastTypedAt Evergreen.V247.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) Evergreen.V247.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V247.Id.Id Evergreen.V247.Id.UserId
    , name : Evergreen.V247.GuildName.GuildName
    , icon : Maybe Evergreen.V247.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V247.MembersAndOwner.MembersAndOwner
            (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V247.SecretId.SecretId Evergreen.V247.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V247.Id.Id Evergreen.V247.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V247.ChannelName.ChannelName
    , description : Evergreen.V247.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V247.Message.MessageState Evergreen.V247.Id.ChannelMessageId (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId))
    , visibleMessages : Evergreen.V247.VisibleMessages.VisibleMessages Evergreen.V247.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Evergreen.V247.Thread.LastTypedAt Evergreen.V247.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) Evergreen.V247.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V247.GuildName.GuildName
    , icon : Maybe Evergreen.V247.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V247.MembersAndOwner.MembersAndOwner
            (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V247.Id.Id Evergreen.V247.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V247.Id.Id Evergreen.V247.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V247.NonemptyDict.NonemptyDict (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) Evergreen.V247.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V247.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareTurnApiToken : Maybe String
    , postmarkKey : Evergreen.V247.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V247.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V247.SessionIdHash.SessionIdHash (Evergreen.V247.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V247.ToBackendLog.ToBackendLogData
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
    , guilds : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) Evergreen.V247.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId) Evergreen.V247.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V247.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V247.SessionIdHash.SessionIdHash Evergreen.V247.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V247.TextEditor.LocalState
    , calls : Evergreen.V247.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V247.Id.Id Evergreen.V247.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V247.Id.Id Evergreen.V247.Id.UserId
    , name : Evergreen.V247.ChannelName.ChannelName
    , description : Evergreen.V247.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V247.Message.Message Evergreen.V247.Id.ChannelMessageId (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) (Evergreen.V247.Thread.LastTypedAt Evergreen.V247.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) Evergreen.V247.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V247.Id.Id Evergreen.V247.Id.UserId
    , name : Evergreen.V247.GuildName.GuildName
    , icon : Maybe Evergreen.V247.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V247.MembersAndOwner.MembersAndOwner
            (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V247.SecretId.SecretId Evergreen.V247.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V247.Id.Id Evergreen.V247.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V247.ChannelName.ChannelName
    , description : Evergreen.V247.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V247.Message.Message Evergreen.V247.Id.ChannelMessageId (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Evergreen.V247.Thread.LastTypedAt Evergreen.V247.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V247.OneToOne.OneToOne (Evergreen.V247.Discord.Id Evergreen.V247.Discord.MessageId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) Evergreen.V247.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V247.GuildName.GuildName
    , icon : Maybe Evergreen.V247.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V247.MembersAndOwner.MembersAndOwner
            (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V247.Id.Id Evergreen.V247.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V247.Id.Id Evergreen.V247.Id.CustomEmojiId)
    }
