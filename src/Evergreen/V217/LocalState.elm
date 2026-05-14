module Evergreen.V217.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V217.ChannelDescription
import Evergreen.V217.ChannelName
import Evergreen.V217.Discord
import Evergreen.V217.DiscordUserData
import Evergreen.V217.DmChannel
import Evergreen.V217.FileStatus
import Evergreen.V217.GuildName
import Evergreen.V217.Id
import Evergreen.V217.Log
import Evergreen.V217.MembersAndOwner
import Evergreen.V217.Message
import Evergreen.V217.NonemptyDict
import Evergreen.V217.OneToOne
import Evergreen.V217.Pagination
import Evergreen.V217.Postmark
import Evergreen.V217.SecretId
import Evergreen.V217.SessionIdHash
import Evergreen.V217.Slack
import Evergreen.V217.TextEditor
import Evergreen.V217.Thread
import Evergreen.V217.ToBackendLog
import Evergreen.V217.User
import Evergreen.V217.UserSession
import Evergreen.V217.VisibleMessages
import Evergreen.V217.VoiceChat
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V217.NonemptyDict.NonemptyDict
            (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V217.Message.Message Evergreen.V217.Id.ChannelMessageId (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V217.Discord.PartialUser
        , icon : Maybe Evergreen.V217.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V217.Discord.User
        , linkedTo : Evergreen.V217.Id.Id Evergreen.V217.Id.UserId
        , icon : Maybe Evergreen.V217.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V217.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V217.Discord.User
        , linkedTo : Evergreen.V217.Id.Id Evergreen.V217.Id.UserId
        , icon : Maybe Evergreen.V217.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V217.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V217.Message.Message Evergreen.V217.Id.ChannelMessageId (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V217.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V217.MembersAndOwner.MembersAndOwner
            (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V217.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V217.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V217.Id.Id Evergreen.V217.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V217.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V217.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : Maybe Evergreen.V217.VoiceChat.RoomId
    }


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V217.Id.Id Evergreen.V217.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V217.Id.Id Evergreen.V217.Id.UserId
    , name : Evergreen.V217.ChannelName.ChannelName
    , description : Evergreen.V217.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V217.Message.MessageState Evergreen.V217.Id.ChannelMessageId (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId))
    , visibleMessages : Evergreen.V217.VisibleMessages.VisibleMessages Evergreen.V217.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) (Evergreen.V217.Thread.LastTypedAt Evergreen.V217.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) Evergreen.V217.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V217.Id.Id Evergreen.V217.Id.UserId
    , name : Evergreen.V217.GuildName.GuildName
    , icon : Maybe Evergreen.V217.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V217.MembersAndOwner.MembersAndOwner
            (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V217.SecretId.SecretId Evergreen.V217.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V217.Id.Id Evergreen.V217.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V217.ChannelName.ChannelName
    , description : Evergreen.V217.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V217.Message.MessageState Evergreen.V217.Id.ChannelMessageId (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId))
    , visibleMessages : Evergreen.V217.VisibleMessages.VisibleMessages Evergreen.V217.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Evergreen.V217.Thread.LastTypedAt Evergreen.V217.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) Evergreen.V217.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V217.GuildName.GuildName
    , icon : Maybe Evergreen.V217.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V217.MembersAndOwner.MembersAndOwner
            (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V217.Id.Id Evergreen.V217.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V217.Id.Id Evergreen.V217.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V217.NonemptyDict.NonemptyDict (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) Evergreen.V217.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V217.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V217.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V217.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V217.SessionIdHash.SessionIdHash (Evergreen.V217.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V217.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) Evergreen.V217.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId) Evergreen.V217.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V217.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V217.SessionIdHash.SessionIdHash Evergreen.V217.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V217.TextEditor.LocalState
    , calls : Evergreen.V217.VoiceChat.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V217.Id.Id Evergreen.V217.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V217.Id.Id Evergreen.V217.Id.UserId
    , name : Evergreen.V217.ChannelName.ChannelName
    , description : Evergreen.V217.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V217.Message.Message Evergreen.V217.Id.ChannelMessageId (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) (Evergreen.V217.Thread.LastTypedAt Evergreen.V217.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) Evergreen.V217.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V217.Id.Id Evergreen.V217.Id.UserId
    , name : Evergreen.V217.GuildName.GuildName
    , icon : Maybe Evergreen.V217.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V217.MembersAndOwner.MembersAndOwner
            (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V217.SecretId.SecretId Evergreen.V217.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V217.Id.Id Evergreen.V217.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V217.ChannelName.ChannelName
    , description : Evergreen.V217.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V217.Message.Message Evergreen.V217.Id.ChannelMessageId (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Evergreen.V217.Thread.LastTypedAt Evergreen.V217.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V217.OneToOne.OneToOne (Evergreen.V217.Discord.Id Evergreen.V217.Discord.MessageId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) Evergreen.V217.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V217.GuildName.GuildName
    , icon : Maybe Evergreen.V217.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V217.MembersAndOwner.MembersAndOwner
            (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V217.Id.Id Evergreen.V217.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V217.Id.Id Evergreen.V217.Id.CustomEmojiId)
    }
