module Evergreen.V243.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V243.Call
import Evergreen.V243.ChannelDescription
import Evergreen.V243.ChannelName
import Evergreen.V243.Discord
import Evergreen.V243.DiscordUserData
import Evergreen.V243.DmChannel
import Evergreen.V243.FileStatus
import Evergreen.V243.GuildName
import Evergreen.V243.Id
import Evergreen.V243.Log
import Evergreen.V243.MembersAndOwner
import Evergreen.V243.Message
import Evergreen.V243.NonemptyDict
import Evergreen.V243.OneToOne
import Evergreen.V243.Pagination
import Evergreen.V243.Postmark
import Evergreen.V243.SecretId
import Evergreen.V243.SessionIdHash
import Evergreen.V243.Slack
import Evergreen.V243.TextEditor
import Evergreen.V243.Thread
import Evergreen.V243.ToBackendLog
import Evergreen.V243.User
import Evergreen.V243.UserSession
import Evergreen.V243.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V243.NonemptyDict.NonemptyDict
            (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V243.Message.Message Evergreen.V243.Id.ChannelMessageId (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V243.Discord.PartialUser
        , icon : Maybe Evergreen.V243.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V243.Discord.User
        , linkedTo : Evergreen.V243.Id.Id Evergreen.V243.Id.UserId
        , icon : Maybe Evergreen.V243.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V243.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V243.Discord.User
        , linkedTo : Evergreen.V243.Id.Id Evergreen.V243.Id.UserId
        , icon : Maybe Evergreen.V243.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V243.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V243.Message.Message Evergreen.V243.Id.ChannelMessageId (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V243.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V243.MembersAndOwner.MembersAndOwner
            (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V243.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V243.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V243.Id.Id Evergreen.V243.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V243.GuildName.GuildName
    , owner : Evergreen.V243.Id.Id Evergreen.V243.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V243.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V243.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : Maybe Evergreen.V243.Call.RoomId
    }


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V243.Id.Id Evergreen.V243.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V243.Id.Id Evergreen.V243.Id.UserId
    , name : Evergreen.V243.ChannelName.ChannelName
    , description : Evergreen.V243.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V243.Message.MessageState Evergreen.V243.Id.ChannelMessageId (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId))
    , visibleMessages : Evergreen.V243.VisibleMessages.VisibleMessages Evergreen.V243.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) (Evergreen.V243.Thread.LastTypedAt Evergreen.V243.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) Evergreen.V243.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V243.Id.Id Evergreen.V243.Id.UserId
    , name : Evergreen.V243.GuildName.GuildName
    , icon : Maybe Evergreen.V243.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V243.MembersAndOwner.MembersAndOwner
            (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V243.SecretId.SecretId Evergreen.V243.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V243.Id.Id Evergreen.V243.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V243.ChannelName.ChannelName
    , description : Evergreen.V243.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V243.Message.MessageState Evergreen.V243.Id.ChannelMessageId (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId))
    , visibleMessages : Evergreen.V243.VisibleMessages.VisibleMessages Evergreen.V243.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Evergreen.V243.Thread.LastTypedAt Evergreen.V243.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) Evergreen.V243.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V243.GuildName.GuildName
    , icon : Maybe Evergreen.V243.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V243.MembersAndOwner.MembersAndOwner
            (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V243.Id.Id Evergreen.V243.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V243.Id.Id Evergreen.V243.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V243.NonemptyDict.NonemptyDict (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) Evergreen.V243.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V243.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareTurnApiToken : Maybe String
    , postmarkKey : Evergreen.V243.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V243.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V243.SessionIdHash.SessionIdHash (Evergreen.V243.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V243.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketDisconnects : Array.Array Effect.Time.Posix
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) Evergreen.V243.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId) Evergreen.V243.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V243.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V243.SessionIdHash.SessionIdHash Evergreen.V243.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V243.TextEditor.LocalState
    , calls : Evergreen.V243.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V243.Id.Id Evergreen.V243.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V243.Id.Id Evergreen.V243.Id.UserId
    , name : Evergreen.V243.ChannelName.ChannelName
    , description : Evergreen.V243.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V243.Message.Message Evergreen.V243.Id.ChannelMessageId (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) (Evergreen.V243.Thread.LastTypedAt Evergreen.V243.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) Evergreen.V243.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V243.Id.Id Evergreen.V243.Id.UserId
    , name : Evergreen.V243.GuildName.GuildName
    , icon : Maybe Evergreen.V243.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V243.MembersAndOwner.MembersAndOwner
            (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V243.SecretId.SecretId Evergreen.V243.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V243.Id.Id Evergreen.V243.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V243.ChannelName.ChannelName
    , description : Evergreen.V243.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V243.Message.Message Evergreen.V243.Id.ChannelMessageId (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Evergreen.V243.Thread.LastTypedAt Evergreen.V243.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V243.OneToOne.OneToOne (Evergreen.V243.Discord.Id Evergreen.V243.Discord.MessageId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) Evergreen.V243.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V243.GuildName.GuildName
    , icon : Maybe Evergreen.V243.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V243.MembersAndOwner.MembersAndOwner
            (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V243.Id.Id Evergreen.V243.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V243.Id.Id Evergreen.V243.Id.CustomEmojiId)
    }
