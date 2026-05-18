module Evergreen.V238.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V238.Call
import Evergreen.V238.ChannelDescription
import Evergreen.V238.ChannelName
import Evergreen.V238.Discord
import Evergreen.V238.DiscordUserData
import Evergreen.V238.DmChannel
import Evergreen.V238.FileStatus
import Evergreen.V238.GuildName
import Evergreen.V238.Id
import Evergreen.V238.Log
import Evergreen.V238.MembersAndOwner
import Evergreen.V238.Message
import Evergreen.V238.NonemptyDict
import Evergreen.V238.OneToOne
import Evergreen.V238.Pagination
import Evergreen.V238.Postmark
import Evergreen.V238.SecretId
import Evergreen.V238.SessionIdHash
import Evergreen.V238.Slack
import Evergreen.V238.TextEditor
import Evergreen.V238.Thread
import Evergreen.V238.ToBackendLog
import Evergreen.V238.User
import Evergreen.V238.UserSession
import Evergreen.V238.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V238.NonemptyDict.NonemptyDict
            (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V238.Message.Message Evergreen.V238.Id.ChannelMessageId (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V238.Discord.PartialUser
        , icon : Maybe Evergreen.V238.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V238.Discord.User
        , linkedTo : Evergreen.V238.Id.Id Evergreen.V238.Id.UserId
        , icon : Maybe Evergreen.V238.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V238.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V238.Discord.User
        , linkedTo : Evergreen.V238.Id.Id Evergreen.V238.Id.UserId
        , icon : Maybe Evergreen.V238.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V238.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V238.Message.Message Evergreen.V238.Id.ChannelMessageId (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V238.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V238.MembersAndOwner.MembersAndOwner
            (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V238.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V238.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V238.Id.Id Evergreen.V238.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V238.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V238.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : Maybe Evergreen.V238.Call.RoomId
    }


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V238.Id.Id Evergreen.V238.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V238.Id.Id Evergreen.V238.Id.UserId
    , name : Evergreen.V238.ChannelName.ChannelName
    , description : Evergreen.V238.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V238.Message.MessageState Evergreen.V238.Id.ChannelMessageId (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId))
    , visibleMessages : Evergreen.V238.VisibleMessages.VisibleMessages Evergreen.V238.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) (Evergreen.V238.Thread.LastTypedAt Evergreen.V238.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) Evergreen.V238.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V238.Id.Id Evergreen.V238.Id.UserId
    , name : Evergreen.V238.GuildName.GuildName
    , icon : Maybe Evergreen.V238.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V238.MembersAndOwner.MembersAndOwner
            (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V238.SecretId.SecretId Evergreen.V238.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V238.Id.Id Evergreen.V238.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V238.ChannelName.ChannelName
    , description : Evergreen.V238.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V238.Message.MessageState Evergreen.V238.Id.ChannelMessageId (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId))
    , visibleMessages : Evergreen.V238.VisibleMessages.VisibleMessages Evergreen.V238.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Evergreen.V238.Thread.LastTypedAt Evergreen.V238.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) Evergreen.V238.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V238.GuildName.GuildName
    , icon : Maybe Evergreen.V238.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V238.MembersAndOwner.MembersAndOwner
            (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V238.Id.Id Evergreen.V238.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V238.Id.Id Evergreen.V238.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V238.NonemptyDict.NonemptyDict (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) Evergreen.V238.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V238.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V238.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V238.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V238.SessionIdHash.SessionIdHash (Evergreen.V238.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V238.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) Evergreen.V238.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId) Evergreen.V238.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V238.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V238.SessionIdHash.SessionIdHash Evergreen.V238.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V238.TextEditor.LocalState
    , calls : Evergreen.V238.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V238.Id.Id Evergreen.V238.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V238.Id.Id Evergreen.V238.Id.UserId
    , name : Evergreen.V238.ChannelName.ChannelName
    , description : Evergreen.V238.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V238.Message.Message Evergreen.V238.Id.ChannelMessageId (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) (Evergreen.V238.Thread.LastTypedAt Evergreen.V238.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) Evergreen.V238.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V238.Id.Id Evergreen.V238.Id.UserId
    , name : Evergreen.V238.GuildName.GuildName
    , icon : Maybe Evergreen.V238.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V238.MembersAndOwner.MembersAndOwner
            (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V238.SecretId.SecretId Evergreen.V238.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V238.Id.Id Evergreen.V238.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V238.ChannelName.ChannelName
    , description : Evergreen.V238.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V238.Message.Message Evergreen.V238.Id.ChannelMessageId (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Evergreen.V238.Thread.LastTypedAt Evergreen.V238.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V238.OneToOne.OneToOne (Evergreen.V238.Discord.Id Evergreen.V238.Discord.MessageId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) Evergreen.V238.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V238.GuildName.GuildName
    , icon : Maybe Evergreen.V238.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V238.MembersAndOwner.MembersAndOwner
            (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V238.Id.Id Evergreen.V238.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V238.Id.Id Evergreen.V238.Id.CustomEmojiId)
    }
