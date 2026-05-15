module Evergreen.V223.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V223.ChannelDescription
import Evergreen.V223.ChannelName
import Evergreen.V223.Discord
import Evergreen.V223.DiscordUserData
import Evergreen.V223.DmChannel
import Evergreen.V223.FileStatus
import Evergreen.V223.GuildName
import Evergreen.V223.Id
import Evergreen.V223.Log
import Evergreen.V223.MembersAndOwner
import Evergreen.V223.Message
import Evergreen.V223.NonemptyDict
import Evergreen.V223.OneToOne
import Evergreen.V223.Pagination
import Evergreen.V223.Postmark
import Evergreen.V223.SecretId
import Evergreen.V223.SessionIdHash
import Evergreen.V223.Slack
import Evergreen.V223.TextEditor
import Evergreen.V223.Thread
import Evergreen.V223.ToBackendLog
import Evergreen.V223.User
import Evergreen.V223.UserSession
import Evergreen.V223.VisibleMessages
import Evergreen.V223.VoiceChat
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V223.NonemptyDict.NonemptyDict
            (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V223.Message.Message Evergreen.V223.Id.ChannelMessageId (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V223.Discord.PartialUser
        , icon : Maybe Evergreen.V223.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V223.Discord.User
        , linkedTo : Evergreen.V223.Id.Id Evergreen.V223.Id.UserId
        , icon : Maybe Evergreen.V223.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V223.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V223.Discord.User
        , linkedTo : Evergreen.V223.Id.Id Evergreen.V223.Id.UserId
        , icon : Maybe Evergreen.V223.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V223.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V223.Message.Message Evergreen.V223.Id.ChannelMessageId (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V223.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V223.Discord.Id Evergreen.V223.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V223.MembersAndOwner.MembersAndOwner
            (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V223.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V223.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V223.Id.Id Evergreen.V223.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V223.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V223.Discord.Id Evergreen.V223.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V223.Discord.Id Evergreen.V223.Discord.GuildId) (Evergreen.V223.Discord.Id Evergreen.V223.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V223.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : Maybe Evergreen.V223.VoiceChat.RoomId
    }


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V223.Id.Id Evergreen.V223.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V223.Id.Id Evergreen.V223.Id.UserId
    , name : Evergreen.V223.ChannelName.ChannelName
    , description : Evergreen.V223.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V223.Message.MessageState Evergreen.V223.Id.ChannelMessageId (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId))
    , visibleMessages : Evergreen.V223.VisibleMessages.VisibleMessages Evergreen.V223.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId) (Evergreen.V223.Thread.LastTypedAt Evergreen.V223.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelMessageId) Evergreen.V223.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V223.Id.Id Evergreen.V223.Id.UserId
    , name : Evergreen.V223.GuildName.GuildName
    , icon : Maybe Evergreen.V223.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V223.MembersAndOwner.MembersAndOwner
            (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V223.SecretId.SecretId Evergreen.V223.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V223.Id.Id Evergreen.V223.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V223.ChannelName.ChannelName
    , description : Evergreen.V223.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V223.Message.MessageState Evergreen.V223.Id.ChannelMessageId (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId))
    , visibleMessages : Evergreen.V223.VisibleMessages.VisibleMessages Evergreen.V223.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId) (Evergreen.V223.Thread.LastTypedAt Evergreen.V223.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelMessageId) Evergreen.V223.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V223.GuildName.GuildName
    , icon : Maybe Evergreen.V223.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V223.Discord.Id Evergreen.V223.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V223.MembersAndOwner.MembersAndOwner
            (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V223.Id.Id Evergreen.V223.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V223.Id.Id Evergreen.V223.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V223.NonemptyDict.NonemptyDict (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId) Evergreen.V223.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V223.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V223.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V223.Discord.Id Evergreen.V223.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V223.Discord.Id Evergreen.V223.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V223.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V223.SessionIdHash.SessionIdHash (Evergreen.V223.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V223.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V223.Discord.Id Evergreen.V223.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId) Evergreen.V223.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V223.Discord.Id Evergreen.V223.Discord.PrivateChannelId) Evergreen.V223.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V223.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V223.SessionIdHash.SessionIdHash Evergreen.V223.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V223.TextEditor.LocalState
    , calls : Evergreen.V223.VoiceChat.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V223.Id.Id Evergreen.V223.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V223.Id.Id Evergreen.V223.Id.UserId
    , name : Evergreen.V223.ChannelName.ChannelName
    , description : Evergreen.V223.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V223.Message.Message Evergreen.V223.Id.ChannelMessageId (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId) (Evergreen.V223.Thread.LastTypedAt Evergreen.V223.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelMessageId) Evergreen.V223.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V223.Id.Id Evergreen.V223.Id.UserId
    , name : Evergreen.V223.GuildName.GuildName
    , icon : Maybe Evergreen.V223.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V223.MembersAndOwner.MembersAndOwner
            (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V223.SecretId.SecretId Evergreen.V223.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V223.Id.Id Evergreen.V223.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V223.ChannelName.ChannelName
    , description : Evergreen.V223.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V223.Message.Message Evergreen.V223.Id.ChannelMessageId (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId) (Evergreen.V223.Thread.LastTypedAt Evergreen.V223.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V223.OneToOne.OneToOne (Evergreen.V223.Discord.Id Evergreen.V223.Discord.MessageId) (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelMessageId) Evergreen.V223.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V223.GuildName.GuildName
    , icon : Maybe Evergreen.V223.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V223.Discord.Id Evergreen.V223.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V223.MembersAndOwner.MembersAndOwner
            (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V223.Id.Id Evergreen.V223.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V223.Id.Id Evergreen.V223.Id.CustomEmojiId)
    }
