module Evergreen.V239.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V239.Call
import Evergreen.V239.ChannelDescription
import Evergreen.V239.ChannelName
import Evergreen.V239.Discord
import Evergreen.V239.DiscordUserData
import Evergreen.V239.DmChannel
import Evergreen.V239.FileStatus
import Evergreen.V239.GuildName
import Evergreen.V239.Id
import Evergreen.V239.Log
import Evergreen.V239.MembersAndOwner
import Evergreen.V239.Message
import Evergreen.V239.NonemptyDict
import Evergreen.V239.OneToOne
import Evergreen.V239.Pagination
import Evergreen.V239.Postmark
import Evergreen.V239.SecretId
import Evergreen.V239.SessionIdHash
import Evergreen.V239.Slack
import Evergreen.V239.TextEditor
import Evergreen.V239.Thread
import Evergreen.V239.ToBackendLog
import Evergreen.V239.User
import Evergreen.V239.UserSession
import Evergreen.V239.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V239.NonemptyDict.NonemptyDict
            (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V239.Message.Message Evergreen.V239.Id.ChannelMessageId (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V239.Discord.PartialUser
        , icon : Maybe Evergreen.V239.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V239.Discord.User
        , linkedTo : Evergreen.V239.Id.Id Evergreen.V239.Id.UserId
        , icon : Maybe Evergreen.V239.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V239.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V239.Discord.User
        , linkedTo : Evergreen.V239.Id.Id Evergreen.V239.Id.UserId
        , icon : Maybe Evergreen.V239.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V239.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V239.Message.Message Evergreen.V239.Id.ChannelMessageId (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V239.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V239.MembersAndOwner.MembersAndOwner
            (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V239.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V239.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V239.Id.Id Evergreen.V239.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V239.GuildName.GuildName
    , owner : Evergreen.V239.Id.Id Evergreen.V239.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V239.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V239.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : Maybe Evergreen.V239.Call.RoomId
    }


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V239.Id.Id Evergreen.V239.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V239.Id.Id Evergreen.V239.Id.UserId
    , name : Evergreen.V239.ChannelName.ChannelName
    , description : Evergreen.V239.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V239.Message.MessageState Evergreen.V239.Id.ChannelMessageId (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId))
    , visibleMessages : Evergreen.V239.VisibleMessages.VisibleMessages Evergreen.V239.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) (Evergreen.V239.Thread.LastTypedAt Evergreen.V239.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) Evergreen.V239.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V239.Id.Id Evergreen.V239.Id.UserId
    , name : Evergreen.V239.GuildName.GuildName
    , icon : Maybe Evergreen.V239.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V239.MembersAndOwner.MembersAndOwner
            (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V239.SecretId.SecretId Evergreen.V239.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V239.Id.Id Evergreen.V239.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V239.ChannelName.ChannelName
    , description : Evergreen.V239.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V239.Message.MessageState Evergreen.V239.Id.ChannelMessageId (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId))
    , visibleMessages : Evergreen.V239.VisibleMessages.VisibleMessages Evergreen.V239.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Evergreen.V239.Thread.LastTypedAt Evergreen.V239.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) Evergreen.V239.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V239.GuildName.GuildName
    , icon : Maybe Evergreen.V239.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V239.MembersAndOwner.MembersAndOwner
            (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V239.Id.Id Evergreen.V239.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V239.Id.Id Evergreen.V239.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V239.NonemptyDict.NonemptyDict (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) Evergreen.V239.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V239.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V239.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V239.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V239.SessionIdHash.SessionIdHash (Evergreen.V239.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V239.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) Evergreen.V239.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId) Evergreen.V239.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V239.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V239.SessionIdHash.SessionIdHash Evergreen.V239.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V239.TextEditor.LocalState
    , calls : Evergreen.V239.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V239.Id.Id Evergreen.V239.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V239.Id.Id Evergreen.V239.Id.UserId
    , name : Evergreen.V239.ChannelName.ChannelName
    , description : Evergreen.V239.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V239.Message.Message Evergreen.V239.Id.ChannelMessageId (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) (Evergreen.V239.Thread.LastTypedAt Evergreen.V239.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) Evergreen.V239.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V239.Id.Id Evergreen.V239.Id.UserId
    , name : Evergreen.V239.GuildName.GuildName
    , icon : Maybe Evergreen.V239.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V239.MembersAndOwner.MembersAndOwner
            (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V239.SecretId.SecretId Evergreen.V239.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V239.Id.Id Evergreen.V239.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V239.ChannelName.ChannelName
    , description : Evergreen.V239.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V239.Message.Message Evergreen.V239.Id.ChannelMessageId (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Evergreen.V239.Thread.LastTypedAt Evergreen.V239.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V239.OneToOne.OneToOne (Evergreen.V239.Discord.Id Evergreen.V239.Discord.MessageId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) Evergreen.V239.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V239.GuildName.GuildName
    , icon : Maybe Evergreen.V239.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V239.MembersAndOwner.MembersAndOwner
            (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V239.Id.Id Evergreen.V239.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V239.Id.Id Evergreen.V239.Id.CustomEmojiId)
    }
