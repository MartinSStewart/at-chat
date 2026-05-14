module Evergreen.V218.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V218.ChannelDescription
import Evergreen.V218.ChannelName
import Evergreen.V218.Discord
import Evergreen.V218.DiscordUserData
import Evergreen.V218.DmChannel
import Evergreen.V218.FileStatus
import Evergreen.V218.GuildName
import Evergreen.V218.Id
import Evergreen.V218.Log
import Evergreen.V218.MembersAndOwner
import Evergreen.V218.Message
import Evergreen.V218.NonemptyDict
import Evergreen.V218.OneToOne
import Evergreen.V218.Pagination
import Evergreen.V218.Postmark
import Evergreen.V218.SecretId
import Evergreen.V218.SessionIdHash
import Evergreen.V218.Slack
import Evergreen.V218.TextEditor
import Evergreen.V218.Thread
import Evergreen.V218.ToBackendLog
import Evergreen.V218.User
import Evergreen.V218.UserSession
import Evergreen.V218.VisibleMessages
import Evergreen.V218.VoiceChat
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V218.NonemptyDict.NonemptyDict
            (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V218.Message.Message Evergreen.V218.Id.ChannelMessageId (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V218.Discord.PartialUser
        , icon : Maybe Evergreen.V218.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V218.Discord.User
        , linkedTo : Evergreen.V218.Id.Id Evergreen.V218.Id.UserId
        , icon : Maybe Evergreen.V218.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V218.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V218.Discord.User
        , linkedTo : Evergreen.V218.Id.Id Evergreen.V218.Id.UserId
        , icon : Maybe Evergreen.V218.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V218.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V218.Message.Message Evergreen.V218.Id.ChannelMessageId (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V218.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V218.MembersAndOwner.MembersAndOwner
            (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V218.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V218.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V218.Id.Id Evergreen.V218.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V218.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V218.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : Maybe Evergreen.V218.VoiceChat.RoomId
    }


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V218.Id.Id Evergreen.V218.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V218.Id.Id Evergreen.V218.Id.UserId
    , name : Evergreen.V218.ChannelName.ChannelName
    , description : Evergreen.V218.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V218.Message.MessageState Evergreen.V218.Id.ChannelMessageId (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId))
    , visibleMessages : Evergreen.V218.VisibleMessages.VisibleMessages Evergreen.V218.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) (Evergreen.V218.Thread.LastTypedAt Evergreen.V218.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) Evergreen.V218.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V218.Id.Id Evergreen.V218.Id.UserId
    , name : Evergreen.V218.GuildName.GuildName
    , icon : Maybe Evergreen.V218.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V218.MembersAndOwner.MembersAndOwner
            (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V218.SecretId.SecretId Evergreen.V218.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V218.Id.Id Evergreen.V218.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V218.ChannelName.ChannelName
    , description : Evergreen.V218.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V218.Message.MessageState Evergreen.V218.Id.ChannelMessageId (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId))
    , visibleMessages : Evergreen.V218.VisibleMessages.VisibleMessages Evergreen.V218.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Evergreen.V218.Thread.LastTypedAt Evergreen.V218.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) Evergreen.V218.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V218.GuildName.GuildName
    , icon : Maybe Evergreen.V218.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V218.MembersAndOwner.MembersAndOwner
            (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V218.Id.Id Evergreen.V218.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V218.Id.Id Evergreen.V218.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V218.NonemptyDict.NonemptyDict (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) Evergreen.V218.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V218.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V218.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V218.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V218.SessionIdHash.SessionIdHash (Evergreen.V218.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V218.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) Evergreen.V218.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId) Evergreen.V218.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V218.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V218.SessionIdHash.SessionIdHash Evergreen.V218.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V218.TextEditor.LocalState
    , calls : Evergreen.V218.VoiceChat.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V218.Id.Id Evergreen.V218.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V218.Id.Id Evergreen.V218.Id.UserId
    , name : Evergreen.V218.ChannelName.ChannelName
    , description : Evergreen.V218.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V218.Message.Message Evergreen.V218.Id.ChannelMessageId (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) (Evergreen.V218.Thread.LastTypedAt Evergreen.V218.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) Evergreen.V218.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V218.Id.Id Evergreen.V218.Id.UserId
    , name : Evergreen.V218.GuildName.GuildName
    , icon : Maybe Evergreen.V218.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V218.MembersAndOwner.MembersAndOwner
            (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V218.SecretId.SecretId Evergreen.V218.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V218.Id.Id Evergreen.V218.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V218.ChannelName.ChannelName
    , description : Evergreen.V218.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V218.Message.Message Evergreen.V218.Id.ChannelMessageId (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Evergreen.V218.Thread.LastTypedAt Evergreen.V218.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V218.OneToOne.OneToOne (Evergreen.V218.Discord.Id Evergreen.V218.Discord.MessageId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) Evergreen.V218.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V218.GuildName.GuildName
    , icon : Maybe Evergreen.V218.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V218.MembersAndOwner.MembersAndOwner
            (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V218.Id.Id Evergreen.V218.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V218.Id.Id Evergreen.V218.Id.CustomEmojiId)
    }
