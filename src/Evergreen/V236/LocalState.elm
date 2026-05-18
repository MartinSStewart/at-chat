module Evergreen.V236.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V236.Call
import Evergreen.V236.ChannelDescription
import Evergreen.V236.ChannelName
import Evergreen.V236.Discord
import Evergreen.V236.DiscordUserData
import Evergreen.V236.DmChannel
import Evergreen.V236.FileStatus
import Evergreen.V236.GuildName
import Evergreen.V236.Id
import Evergreen.V236.Log
import Evergreen.V236.MembersAndOwner
import Evergreen.V236.Message
import Evergreen.V236.NonemptyDict
import Evergreen.V236.OneToOne
import Evergreen.V236.Pagination
import Evergreen.V236.Postmark
import Evergreen.V236.SecretId
import Evergreen.V236.SessionIdHash
import Evergreen.V236.Slack
import Evergreen.V236.TextEditor
import Evergreen.V236.Thread
import Evergreen.V236.ToBackendLog
import Evergreen.V236.User
import Evergreen.V236.UserSession
import Evergreen.V236.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V236.NonemptyDict.NonemptyDict
            (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V236.Message.Message Evergreen.V236.Id.ChannelMessageId (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V236.Discord.PartialUser
        , icon : Maybe Evergreen.V236.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V236.Discord.User
        , linkedTo : Evergreen.V236.Id.Id Evergreen.V236.Id.UserId
        , icon : Maybe Evergreen.V236.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V236.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V236.Discord.User
        , linkedTo : Evergreen.V236.Id.Id Evergreen.V236.Id.UserId
        , icon : Maybe Evergreen.V236.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V236.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V236.Message.Message Evergreen.V236.Id.ChannelMessageId (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V236.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V236.MembersAndOwner.MembersAndOwner
            (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V236.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V236.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V236.Id.Id Evergreen.V236.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V236.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V236.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : Maybe Evergreen.V236.Call.RoomId
    }


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V236.Id.Id Evergreen.V236.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V236.Id.Id Evergreen.V236.Id.UserId
    , name : Evergreen.V236.ChannelName.ChannelName
    , description : Evergreen.V236.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V236.Message.MessageState Evergreen.V236.Id.ChannelMessageId (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId))
    , visibleMessages : Evergreen.V236.VisibleMessages.VisibleMessages Evergreen.V236.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) (Evergreen.V236.Thread.LastTypedAt Evergreen.V236.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) Evergreen.V236.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V236.Id.Id Evergreen.V236.Id.UserId
    , name : Evergreen.V236.GuildName.GuildName
    , icon : Maybe Evergreen.V236.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V236.MembersAndOwner.MembersAndOwner
            (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V236.SecretId.SecretId Evergreen.V236.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V236.Id.Id Evergreen.V236.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V236.ChannelName.ChannelName
    , description : Evergreen.V236.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V236.Message.MessageState Evergreen.V236.Id.ChannelMessageId (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId))
    , visibleMessages : Evergreen.V236.VisibleMessages.VisibleMessages Evergreen.V236.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Evergreen.V236.Thread.LastTypedAt Evergreen.V236.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) Evergreen.V236.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V236.GuildName.GuildName
    , icon : Maybe Evergreen.V236.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V236.MembersAndOwner.MembersAndOwner
            (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V236.Id.Id Evergreen.V236.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V236.Id.Id Evergreen.V236.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V236.NonemptyDict.NonemptyDict (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) Evergreen.V236.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V236.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V236.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V236.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V236.SessionIdHash.SessionIdHash (Evergreen.V236.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V236.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) Evergreen.V236.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId) Evergreen.V236.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V236.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V236.SessionIdHash.SessionIdHash Evergreen.V236.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V236.TextEditor.LocalState
    , calls : Evergreen.V236.Call.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V236.Id.Id Evergreen.V236.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V236.Id.Id Evergreen.V236.Id.UserId
    , name : Evergreen.V236.ChannelName.ChannelName
    , description : Evergreen.V236.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V236.Message.Message Evergreen.V236.Id.ChannelMessageId (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) (Evergreen.V236.Thread.LastTypedAt Evergreen.V236.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) Evergreen.V236.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V236.Id.Id Evergreen.V236.Id.UserId
    , name : Evergreen.V236.GuildName.GuildName
    , icon : Maybe Evergreen.V236.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V236.MembersAndOwner.MembersAndOwner
            (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V236.SecretId.SecretId Evergreen.V236.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V236.Id.Id Evergreen.V236.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V236.ChannelName.ChannelName
    , description : Evergreen.V236.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V236.Message.Message Evergreen.V236.Id.ChannelMessageId (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Evergreen.V236.Thread.LastTypedAt Evergreen.V236.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V236.OneToOne.OneToOne (Evergreen.V236.Discord.Id Evergreen.V236.Discord.MessageId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) Evergreen.V236.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V236.GuildName.GuildName
    , icon : Maybe Evergreen.V236.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V236.MembersAndOwner.MembersAndOwner
            (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V236.Id.Id Evergreen.V236.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V236.Id.Id Evergreen.V236.Id.CustomEmojiId)
    }
