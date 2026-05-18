module Evergreen.V232.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V232.Call
import Evergreen.V232.ChannelDescription
import Evergreen.V232.ChannelName
import Evergreen.V232.Discord
import Evergreen.V232.DiscordUserData
import Evergreen.V232.DmChannel
import Evergreen.V232.FileStatus
import Evergreen.V232.GuildName
import Evergreen.V232.Id
import Evergreen.V232.Log
import Evergreen.V232.MembersAndOwner
import Evergreen.V232.Message
import Evergreen.V232.NonemptyDict
import Evergreen.V232.OneToOne
import Evergreen.V232.Pagination
import Evergreen.V232.Postmark
import Evergreen.V232.SecretId
import Evergreen.V232.SessionIdHash
import Evergreen.V232.Slack
import Evergreen.V232.TextEditor
import Evergreen.V232.Thread
import Evergreen.V232.ToBackendLog
import Evergreen.V232.User
import Evergreen.V232.UserSession
import Evergreen.V232.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V232.NonemptyDict.NonemptyDict
            (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V232.Message.Message Evergreen.V232.Id.ChannelMessageId (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V232.Discord.PartialUser
        , icon : Maybe Evergreen.V232.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V232.Discord.User
        , linkedTo : Evergreen.V232.Id.Id Evergreen.V232.Id.UserId
        , icon : Maybe Evergreen.V232.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V232.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V232.Discord.User
        , linkedTo : Evergreen.V232.Id.Id Evergreen.V232.Id.UserId
        , icon : Maybe Evergreen.V232.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V232.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V232.Message.Message Evergreen.V232.Id.ChannelMessageId (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V232.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V232.MembersAndOwner.MembersAndOwner
            (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V232.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V232.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V232.Id.Id Evergreen.V232.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V232.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V232.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : Maybe Evergreen.V232.Call.RoomId
    }


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V232.Id.Id Evergreen.V232.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V232.Id.Id Evergreen.V232.Id.UserId
    , name : Evergreen.V232.ChannelName.ChannelName
    , description : Evergreen.V232.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V232.Message.MessageState Evergreen.V232.Id.ChannelMessageId (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId))
    , visibleMessages : Evergreen.V232.VisibleMessages.VisibleMessages Evergreen.V232.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) (Evergreen.V232.Thread.LastTypedAt Evergreen.V232.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) Evergreen.V232.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V232.Id.Id Evergreen.V232.Id.UserId
    , name : Evergreen.V232.GuildName.GuildName
    , icon : Maybe Evergreen.V232.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V232.MembersAndOwner.MembersAndOwner
            (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V232.SecretId.SecretId Evergreen.V232.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V232.Id.Id Evergreen.V232.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V232.ChannelName.ChannelName
    , description : Evergreen.V232.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V232.Message.MessageState Evergreen.V232.Id.ChannelMessageId (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId))
    , visibleMessages : Evergreen.V232.VisibleMessages.VisibleMessages Evergreen.V232.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Evergreen.V232.Thread.LastTypedAt Evergreen.V232.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) Evergreen.V232.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V232.GuildName.GuildName
    , icon : Maybe Evergreen.V232.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V232.MembersAndOwner.MembersAndOwner
            (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V232.Id.Id Evergreen.V232.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V232.Id.Id Evergreen.V232.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V232.NonemptyDict.NonemptyDict (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) Evergreen.V232.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V232.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V232.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V232.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V232.SessionIdHash.SessionIdHash (Evergreen.V232.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V232.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) Evergreen.V232.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId) Evergreen.V232.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V232.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V232.SessionIdHash.SessionIdHash Evergreen.V232.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V232.TextEditor.LocalState
    , calls : Evergreen.V232.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V232.Id.Id Evergreen.V232.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V232.Id.Id Evergreen.V232.Id.UserId
    , name : Evergreen.V232.ChannelName.ChannelName
    , description : Evergreen.V232.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V232.Message.Message Evergreen.V232.Id.ChannelMessageId (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) (Evergreen.V232.Thread.LastTypedAt Evergreen.V232.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) Evergreen.V232.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V232.Id.Id Evergreen.V232.Id.UserId
    , name : Evergreen.V232.GuildName.GuildName
    , icon : Maybe Evergreen.V232.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V232.MembersAndOwner.MembersAndOwner
            (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V232.SecretId.SecretId Evergreen.V232.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V232.Id.Id Evergreen.V232.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V232.ChannelName.ChannelName
    , description : Evergreen.V232.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V232.Message.Message Evergreen.V232.Id.ChannelMessageId (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Evergreen.V232.Thread.LastTypedAt Evergreen.V232.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V232.OneToOne.OneToOne (Evergreen.V232.Discord.Id Evergreen.V232.Discord.MessageId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) Evergreen.V232.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V232.GuildName.GuildName
    , icon : Maybe Evergreen.V232.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V232.MembersAndOwner.MembersAndOwner
            (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V232.Id.Id Evergreen.V232.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V232.Id.Id Evergreen.V232.Id.CustomEmojiId)
    }
