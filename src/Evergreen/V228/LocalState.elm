module Evergreen.V228.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V228.Call
import Evergreen.V228.ChannelDescription
import Evergreen.V228.ChannelName
import Evergreen.V228.Discord
import Evergreen.V228.DiscordUserData
import Evergreen.V228.DmChannel
import Evergreen.V228.FileStatus
import Evergreen.V228.GuildName
import Evergreen.V228.Id
import Evergreen.V228.Log
import Evergreen.V228.MembersAndOwner
import Evergreen.V228.Message
import Evergreen.V228.NonemptyDict
import Evergreen.V228.OneToOne
import Evergreen.V228.Pagination
import Evergreen.V228.Postmark
import Evergreen.V228.SecretId
import Evergreen.V228.SessionIdHash
import Evergreen.V228.Slack
import Evergreen.V228.TextEditor
import Evergreen.V228.Thread
import Evergreen.V228.ToBackendLog
import Evergreen.V228.User
import Evergreen.V228.UserSession
import Evergreen.V228.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V228.NonemptyDict.NonemptyDict
            (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V228.Message.Message Evergreen.V228.Id.ChannelMessageId (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V228.Discord.PartialUser
        , icon : Maybe Evergreen.V228.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V228.Discord.User
        , linkedTo : Evergreen.V228.Id.Id Evergreen.V228.Id.UserId
        , icon : Maybe Evergreen.V228.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V228.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V228.Discord.User
        , linkedTo : Evergreen.V228.Id.Id Evergreen.V228.Id.UserId
        , icon : Maybe Evergreen.V228.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V228.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V228.Message.Message Evergreen.V228.Id.ChannelMessageId (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V228.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V228.MembersAndOwner.MembersAndOwner
            (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V228.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V228.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V228.Id.Id Evergreen.V228.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V228.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V228.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : Maybe Evergreen.V228.Call.RoomId
    }


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V228.Id.Id Evergreen.V228.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V228.Id.Id Evergreen.V228.Id.UserId
    , name : Evergreen.V228.ChannelName.ChannelName
    , description : Evergreen.V228.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V228.Message.MessageState Evergreen.V228.Id.ChannelMessageId (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId))
    , visibleMessages : Evergreen.V228.VisibleMessages.VisibleMessages Evergreen.V228.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) (Evergreen.V228.Thread.LastTypedAt Evergreen.V228.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) Evergreen.V228.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V228.Id.Id Evergreen.V228.Id.UserId
    , name : Evergreen.V228.GuildName.GuildName
    , icon : Maybe Evergreen.V228.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V228.MembersAndOwner.MembersAndOwner
            (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V228.SecretId.SecretId Evergreen.V228.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V228.Id.Id Evergreen.V228.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V228.ChannelName.ChannelName
    , description : Evergreen.V228.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V228.Message.MessageState Evergreen.V228.Id.ChannelMessageId (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId))
    , visibleMessages : Evergreen.V228.VisibleMessages.VisibleMessages Evergreen.V228.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Evergreen.V228.Thread.LastTypedAt Evergreen.V228.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) Evergreen.V228.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V228.GuildName.GuildName
    , icon : Maybe Evergreen.V228.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V228.MembersAndOwner.MembersAndOwner
            (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V228.Id.Id Evergreen.V228.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V228.Id.Id Evergreen.V228.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V228.NonemptyDict.NonemptyDict (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) Evergreen.V228.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V228.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V228.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V228.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V228.SessionIdHash.SessionIdHash (Evergreen.V228.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V228.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) Evergreen.V228.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId) Evergreen.V228.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V228.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V228.SessionIdHash.SessionIdHash Evergreen.V228.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V228.TextEditor.LocalState
    , calls : Evergreen.V228.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V228.Id.Id Evergreen.V228.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V228.Id.Id Evergreen.V228.Id.UserId
    , name : Evergreen.V228.ChannelName.ChannelName
    , description : Evergreen.V228.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V228.Message.Message Evergreen.V228.Id.ChannelMessageId (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) (Evergreen.V228.Thread.LastTypedAt Evergreen.V228.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) Evergreen.V228.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V228.Id.Id Evergreen.V228.Id.UserId
    , name : Evergreen.V228.GuildName.GuildName
    , icon : Maybe Evergreen.V228.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V228.MembersAndOwner.MembersAndOwner
            (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V228.SecretId.SecretId Evergreen.V228.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V228.Id.Id Evergreen.V228.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V228.ChannelName.ChannelName
    , description : Evergreen.V228.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V228.Message.Message Evergreen.V228.Id.ChannelMessageId (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Evergreen.V228.Thread.LastTypedAt Evergreen.V228.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V228.OneToOne.OneToOne (Evergreen.V228.Discord.Id Evergreen.V228.Discord.MessageId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) Evergreen.V228.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V228.GuildName.GuildName
    , icon : Maybe Evergreen.V228.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V228.MembersAndOwner.MembersAndOwner
            (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V228.Id.Id Evergreen.V228.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V228.Id.Id Evergreen.V228.Id.CustomEmojiId)
    }
