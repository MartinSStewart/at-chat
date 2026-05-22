module Evergreen.V242.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V242.Call
import Evergreen.V242.ChannelDescription
import Evergreen.V242.ChannelName
import Evergreen.V242.Discord
import Evergreen.V242.DiscordUserData
import Evergreen.V242.DmChannel
import Evergreen.V242.FileStatus
import Evergreen.V242.GuildName
import Evergreen.V242.Id
import Evergreen.V242.Log
import Evergreen.V242.MembersAndOwner
import Evergreen.V242.Message
import Evergreen.V242.NonemptyDict
import Evergreen.V242.OneToOne
import Evergreen.V242.Pagination
import Evergreen.V242.Postmark
import Evergreen.V242.SecretId
import Evergreen.V242.SessionIdHash
import Evergreen.V242.Slack
import Evergreen.V242.TextEditor
import Evergreen.V242.Thread
import Evergreen.V242.ToBackendLog
import Evergreen.V242.User
import Evergreen.V242.UserSession
import Evergreen.V242.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V242.NonemptyDict.NonemptyDict
            (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V242.Message.Message Evergreen.V242.Id.ChannelMessageId (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V242.Discord.PartialUser
        , icon : Maybe Evergreen.V242.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V242.Discord.User
        , linkedTo : Evergreen.V242.Id.Id Evergreen.V242.Id.UserId
        , icon : Maybe Evergreen.V242.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V242.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V242.Discord.User
        , linkedTo : Evergreen.V242.Id.Id Evergreen.V242.Id.UserId
        , icon : Maybe Evergreen.V242.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V242.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V242.Message.Message Evergreen.V242.Id.ChannelMessageId (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V242.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V242.MembersAndOwner.MembersAndOwner
            (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V242.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V242.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V242.Id.Id Evergreen.V242.Id.UserId
    }


type alias AdminData_DeletedGuild =
    { name : Evergreen.V242.GuildName.GuildName
    , owner : Evergreen.V242.Id.Id Evergreen.V242.Id.UserId
    , memberCount : Int
    , deletedAt : Effect.Time.Posix
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V242.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V242.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : Maybe Evergreen.V242.Call.RoomId
    }


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V242.Id.Id Evergreen.V242.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V242.Id.Id Evergreen.V242.Id.UserId
    , name : Evergreen.V242.ChannelName.ChannelName
    , description : Evergreen.V242.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V242.Message.MessageState Evergreen.V242.Id.ChannelMessageId (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId))
    , visibleMessages : Evergreen.V242.VisibleMessages.VisibleMessages Evergreen.V242.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) (Evergreen.V242.Thread.LastTypedAt Evergreen.V242.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) Evergreen.V242.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V242.Id.Id Evergreen.V242.Id.UserId
    , name : Evergreen.V242.GuildName.GuildName
    , icon : Maybe Evergreen.V242.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V242.MembersAndOwner.MembersAndOwner
            (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V242.SecretId.SecretId Evergreen.V242.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V242.Id.Id Evergreen.V242.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V242.ChannelName.ChannelName
    , description : Evergreen.V242.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V242.Message.MessageState Evergreen.V242.Id.ChannelMessageId (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId))
    , visibleMessages : Evergreen.V242.VisibleMessages.VisibleMessages Evergreen.V242.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Evergreen.V242.Thread.LastTypedAt Evergreen.V242.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) Evergreen.V242.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V242.GuildName.GuildName
    , icon : Maybe Evergreen.V242.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V242.MembersAndOwner.MembersAndOwner
            (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V242.Id.Id Evergreen.V242.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V242.Id.Id Evergreen.V242.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V242.NonemptyDict.NonemptyDict (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) Evergreen.V242.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V242.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareTurnApiToken : Maybe String
    , postmarkKey : Evergreen.V242.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V242.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V242.SessionIdHash.SessionIdHash (Evergreen.V242.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V242.ToBackendLog.ToBackendLogData
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
    , guilds : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) Evergreen.V242.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId) Evergreen.V242.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V242.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V242.SessionIdHash.SessionIdHash Evergreen.V242.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V242.TextEditor.LocalState
    , calls : Evergreen.V242.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V242.Id.Id Evergreen.V242.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V242.Id.Id Evergreen.V242.Id.UserId
    , name : Evergreen.V242.ChannelName.ChannelName
    , description : Evergreen.V242.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V242.Message.Message Evergreen.V242.Id.ChannelMessageId (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) (Evergreen.V242.Thread.LastTypedAt Evergreen.V242.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) Evergreen.V242.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V242.Id.Id Evergreen.V242.Id.UserId
    , name : Evergreen.V242.GuildName.GuildName
    , icon : Maybe Evergreen.V242.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V242.MembersAndOwner.MembersAndOwner
            (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V242.SecretId.SecretId Evergreen.V242.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V242.Id.Id Evergreen.V242.Id.UserId
            }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild
    , deletedAt : Effect.Time.Posix
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V242.ChannelName.ChannelName
    , description : Evergreen.V242.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V242.Message.Message Evergreen.V242.Id.ChannelMessageId (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Evergreen.V242.Thread.LastTypedAt Evergreen.V242.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V242.OneToOne.OneToOne (Evergreen.V242.Discord.Id Evergreen.V242.Discord.MessageId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) Evergreen.V242.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V242.GuildName.GuildName
    , icon : Maybe Evergreen.V242.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V242.MembersAndOwner.MembersAndOwner
            (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V242.Id.Id Evergreen.V242.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V242.Id.Id Evergreen.V242.Id.CustomEmojiId)
    }
