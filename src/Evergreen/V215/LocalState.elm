module Evergreen.V215.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V215.ChannelDescription
import Evergreen.V215.ChannelName
import Evergreen.V215.Discord
import Evergreen.V215.DiscordUserData
import Evergreen.V215.DmChannel
import Evergreen.V215.FileStatus
import Evergreen.V215.GuildName
import Evergreen.V215.Id
import Evergreen.V215.Log
import Evergreen.V215.MembersAndOwner
import Evergreen.V215.Message
import Evergreen.V215.NonemptyDict
import Evergreen.V215.OneToOne
import Evergreen.V215.Pagination
import Evergreen.V215.Postmark
import Evergreen.V215.SecretId
import Evergreen.V215.SessionIdHash
import Evergreen.V215.Slack
import Evergreen.V215.TextEditor
import Evergreen.V215.Thread
import Evergreen.V215.ToBackendLog
import Evergreen.V215.User
import Evergreen.V215.UserSession
import Evergreen.V215.VisibleMessages
import Evergreen.V215.VoiceChat
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V215.NonemptyDict.NonemptyDict
            (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V215.Message.Message Evergreen.V215.Id.ChannelMessageId (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V215.Discord.PartialUser
        , icon : Maybe Evergreen.V215.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V215.Discord.User
        , linkedTo : Evergreen.V215.Id.Id Evergreen.V215.Id.UserId
        , icon : Maybe Evergreen.V215.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V215.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V215.Discord.User
        , linkedTo : Evergreen.V215.Id.Id Evergreen.V215.Id.UserId
        , icon : Maybe Evergreen.V215.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V215.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V215.Message.Message Evergreen.V215.Id.ChannelMessageId (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V215.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V215.MembersAndOwner.MembersAndOwner
            (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V215.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V215.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V215.Id.Id Evergreen.V215.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V215.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V215.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : Maybe Evergreen.V215.VoiceChat.RoomId
    }


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V215.Id.Id Evergreen.V215.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V215.Id.Id Evergreen.V215.Id.UserId
    , name : Evergreen.V215.ChannelName.ChannelName
    , description : Evergreen.V215.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V215.Message.MessageState Evergreen.V215.Id.ChannelMessageId (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId))
    , visibleMessages : Evergreen.V215.VisibleMessages.VisibleMessages Evergreen.V215.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) (Evergreen.V215.Thread.LastTypedAt Evergreen.V215.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) Evergreen.V215.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V215.Id.Id Evergreen.V215.Id.UserId
    , name : Evergreen.V215.GuildName.GuildName
    , icon : Maybe Evergreen.V215.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V215.MembersAndOwner.MembersAndOwner
            (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V215.SecretId.SecretId Evergreen.V215.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V215.Id.Id Evergreen.V215.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V215.ChannelName.ChannelName
    , description : Evergreen.V215.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V215.Message.MessageState Evergreen.V215.Id.ChannelMessageId (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId))
    , visibleMessages : Evergreen.V215.VisibleMessages.VisibleMessages Evergreen.V215.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Evergreen.V215.Thread.LastTypedAt Evergreen.V215.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) Evergreen.V215.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V215.GuildName.GuildName
    , icon : Maybe Evergreen.V215.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V215.MembersAndOwner.MembersAndOwner
            (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V215.Id.Id Evergreen.V215.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V215.Id.Id Evergreen.V215.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V215.NonemptyDict.NonemptyDict (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) Evergreen.V215.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V215.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V215.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V215.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V215.SessionIdHash.SessionIdHash (Evergreen.V215.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V215.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) Evergreen.V215.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId) Evergreen.V215.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V215.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V215.SessionIdHash.SessionIdHash Evergreen.V215.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V215.TextEditor.LocalState
    , calls : Evergreen.V215.VoiceChat.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V215.Id.Id Evergreen.V215.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V215.Id.Id Evergreen.V215.Id.UserId
    , name : Evergreen.V215.ChannelName.ChannelName
    , description : Evergreen.V215.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V215.Message.Message Evergreen.V215.Id.ChannelMessageId (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) (Evergreen.V215.Thread.LastTypedAt Evergreen.V215.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) Evergreen.V215.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V215.Id.Id Evergreen.V215.Id.UserId
    , name : Evergreen.V215.GuildName.GuildName
    , icon : Maybe Evergreen.V215.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V215.MembersAndOwner.MembersAndOwner
            (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V215.SecretId.SecretId Evergreen.V215.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V215.Id.Id Evergreen.V215.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V215.ChannelName.ChannelName
    , description : Evergreen.V215.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V215.Message.Message Evergreen.V215.Id.ChannelMessageId (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Evergreen.V215.Thread.LastTypedAt Evergreen.V215.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V215.OneToOne.OneToOne (Evergreen.V215.Discord.Id Evergreen.V215.Discord.MessageId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) Evergreen.V215.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V215.GuildName.GuildName
    , icon : Maybe Evergreen.V215.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V215.MembersAndOwner.MembersAndOwner
            (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V215.Id.Id Evergreen.V215.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V215.Id.Id Evergreen.V215.Id.CustomEmojiId)
    }
