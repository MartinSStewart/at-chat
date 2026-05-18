module Evergreen.V229.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V229.Call
import Evergreen.V229.ChannelDescription
import Evergreen.V229.ChannelName
import Evergreen.V229.Discord
import Evergreen.V229.DiscordUserData
import Evergreen.V229.DmChannel
import Evergreen.V229.FileStatus
import Evergreen.V229.GuildName
import Evergreen.V229.Id
import Evergreen.V229.Log
import Evergreen.V229.MembersAndOwner
import Evergreen.V229.Message
import Evergreen.V229.NonemptyDict
import Evergreen.V229.OneToOne
import Evergreen.V229.Pagination
import Evergreen.V229.Postmark
import Evergreen.V229.SecretId
import Evergreen.V229.SessionIdHash
import Evergreen.V229.Slack
import Evergreen.V229.TextEditor
import Evergreen.V229.Thread
import Evergreen.V229.ToBackendLog
import Evergreen.V229.User
import Evergreen.V229.UserSession
import Evergreen.V229.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V229.NonemptyDict.NonemptyDict
            (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V229.Message.Message Evergreen.V229.Id.ChannelMessageId (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V229.Discord.PartialUser
        , icon : Maybe Evergreen.V229.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V229.Discord.User
        , linkedTo : Evergreen.V229.Id.Id Evergreen.V229.Id.UserId
        , icon : Maybe Evergreen.V229.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V229.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V229.Discord.User
        , linkedTo : Evergreen.V229.Id.Id Evergreen.V229.Id.UserId
        , icon : Maybe Evergreen.V229.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V229.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V229.Message.Message Evergreen.V229.Id.ChannelMessageId (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V229.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V229.MembersAndOwner.MembersAndOwner
            (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V229.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V229.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V229.Id.Id Evergreen.V229.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V229.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V229.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : Maybe Evergreen.V229.Call.RoomId
    }


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V229.Id.Id Evergreen.V229.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V229.Id.Id Evergreen.V229.Id.UserId
    , name : Evergreen.V229.ChannelName.ChannelName
    , description : Evergreen.V229.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V229.Message.MessageState Evergreen.V229.Id.ChannelMessageId (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId))
    , visibleMessages : Evergreen.V229.VisibleMessages.VisibleMessages Evergreen.V229.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) (Evergreen.V229.Thread.LastTypedAt Evergreen.V229.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) Evergreen.V229.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V229.Id.Id Evergreen.V229.Id.UserId
    , name : Evergreen.V229.GuildName.GuildName
    , icon : Maybe Evergreen.V229.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V229.MembersAndOwner.MembersAndOwner
            (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V229.SecretId.SecretId Evergreen.V229.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V229.Id.Id Evergreen.V229.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V229.ChannelName.ChannelName
    , description : Evergreen.V229.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V229.Message.MessageState Evergreen.V229.Id.ChannelMessageId (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId))
    , visibleMessages : Evergreen.V229.VisibleMessages.VisibleMessages Evergreen.V229.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Evergreen.V229.Thread.LastTypedAt Evergreen.V229.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) Evergreen.V229.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V229.GuildName.GuildName
    , icon : Maybe Evergreen.V229.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V229.MembersAndOwner.MembersAndOwner
            (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V229.Id.Id Evergreen.V229.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V229.Id.Id Evergreen.V229.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V229.NonemptyDict.NonemptyDict (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) Evergreen.V229.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V229.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V229.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V229.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V229.SessionIdHash.SessionIdHash (Evergreen.V229.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V229.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) Evergreen.V229.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId) Evergreen.V229.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V229.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V229.SessionIdHash.SessionIdHash Evergreen.V229.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V229.TextEditor.LocalState
    , calls : Evergreen.V229.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V229.Id.Id Evergreen.V229.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V229.Id.Id Evergreen.V229.Id.UserId
    , name : Evergreen.V229.ChannelName.ChannelName
    , description : Evergreen.V229.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V229.Message.Message Evergreen.V229.Id.ChannelMessageId (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) (Evergreen.V229.Thread.LastTypedAt Evergreen.V229.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) Evergreen.V229.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V229.Id.Id Evergreen.V229.Id.UserId
    , name : Evergreen.V229.GuildName.GuildName
    , icon : Maybe Evergreen.V229.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V229.MembersAndOwner.MembersAndOwner
            (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V229.SecretId.SecretId Evergreen.V229.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V229.Id.Id Evergreen.V229.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V229.ChannelName.ChannelName
    , description : Evergreen.V229.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V229.Message.Message Evergreen.V229.Id.ChannelMessageId (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Evergreen.V229.Thread.LastTypedAt Evergreen.V229.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V229.OneToOne.OneToOne (Evergreen.V229.Discord.Id Evergreen.V229.Discord.MessageId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) Evergreen.V229.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V229.GuildName.GuildName
    , icon : Maybe Evergreen.V229.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V229.MembersAndOwner.MembersAndOwner
            (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V229.Id.Id Evergreen.V229.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V229.Id.Id Evergreen.V229.Id.CustomEmojiId)
    }
