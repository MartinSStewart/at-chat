module Evergreen.V216.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V216.ChannelDescription
import Evergreen.V216.ChannelName
import Evergreen.V216.Discord
import Evergreen.V216.DiscordUserData
import Evergreen.V216.DmChannel
import Evergreen.V216.FileStatus
import Evergreen.V216.GuildName
import Evergreen.V216.Id
import Evergreen.V216.Log
import Evergreen.V216.MembersAndOwner
import Evergreen.V216.Message
import Evergreen.V216.NonemptyDict
import Evergreen.V216.OneToOne
import Evergreen.V216.Pagination
import Evergreen.V216.Postmark
import Evergreen.V216.SecretId
import Evergreen.V216.SessionIdHash
import Evergreen.V216.Slack
import Evergreen.V216.TextEditor
import Evergreen.V216.Thread
import Evergreen.V216.ToBackendLog
import Evergreen.V216.User
import Evergreen.V216.UserSession
import Evergreen.V216.VisibleMessages
import Evergreen.V216.VoiceChat
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V216.NonemptyDict.NonemptyDict
            (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V216.Message.Message Evergreen.V216.Id.ChannelMessageId (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V216.Discord.PartialUser
        , icon : Maybe Evergreen.V216.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V216.Discord.User
        , linkedTo : Evergreen.V216.Id.Id Evergreen.V216.Id.UserId
        , icon : Maybe Evergreen.V216.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V216.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V216.Discord.User
        , linkedTo : Evergreen.V216.Id.Id Evergreen.V216.Id.UserId
        , icon : Maybe Evergreen.V216.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V216.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V216.Message.Message Evergreen.V216.Id.ChannelMessageId (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V216.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V216.MembersAndOwner.MembersAndOwner
            (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V216.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V216.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V216.Id.Id Evergreen.V216.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V216.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V216.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : Maybe Evergreen.V216.VoiceChat.RoomId
    }


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V216.Id.Id Evergreen.V216.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V216.Id.Id Evergreen.V216.Id.UserId
    , name : Evergreen.V216.ChannelName.ChannelName
    , description : Evergreen.V216.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V216.Message.MessageState Evergreen.V216.Id.ChannelMessageId (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId))
    , visibleMessages : Evergreen.V216.VisibleMessages.VisibleMessages Evergreen.V216.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) (Evergreen.V216.Thread.LastTypedAt Evergreen.V216.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) Evergreen.V216.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V216.Id.Id Evergreen.V216.Id.UserId
    , name : Evergreen.V216.GuildName.GuildName
    , icon : Maybe Evergreen.V216.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V216.MembersAndOwner.MembersAndOwner
            (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V216.SecretId.SecretId Evergreen.V216.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V216.Id.Id Evergreen.V216.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V216.ChannelName.ChannelName
    , description : Evergreen.V216.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V216.Message.MessageState Evergreen.V216.Id.ChannelMessageId (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId))
    , visibleMessages : Evergreen.V216.VisibleMessages.VisibleMessages Evergreen.V216.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Evergreen.V216.Thread.LastTypedAt Evergreen.V216.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) Evergreen.V216.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V216.GuildName.GuildName
    , icon : Maybe Evergreen.V216.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V216.MembersAndOwner.MembersAndOwner
            (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V216.Id.Id Evergreen.V216.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V216.Id.Id Evergreen.V216.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V216.NonemptyDict.NonemptyDict (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) Evergreen.V216.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V216.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V216.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V216.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V216.SessionIdHash.SessionIdHash (Evergreen.V216.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V216.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) Evergreen.V216.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId) Evergreen.V216.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : Evergreen.V216.User.LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V216.SessionIdHash.SessionIdHash Evergreen.V216.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V216.TextEditor.LocalState
    , calls : Evergreen.V216.VoiceChat.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V216.Id.Id Evergreen.V216.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V216.Id.Id Evergreen.V216.Id.UserId
    , name : Evergreen.V216.ChannelName.ChannelName
    , description : Evergreen.V216.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V216.Message.Message Evergreen.V216.Id.ChannelMessageId (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) (Evergreen.V216.Thread.LastTypedAt Evergreen.V216.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) Evergreen.V216.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V216.Id.Id Evergreen.V216.Id.UserId
    , name : Evergreen.V216.GuildName.GuildName
    , icon : Maybe Evergreen.V216.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V216.MembersAndOwner.MembersAndOwner
            (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V216.SecretId.SecretId Evergreen.V216.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V216.Id.Id Evergreen.V216.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V216.ChannelName.ChannelName
    , description : Evergreen.V216.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V216.Message.Message Evergreen.V216.Id.ChannelMessageId (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Evergreen.V216.Thread.LastTypedAt Evergreen.V216.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V216.OneToOne.OneToOne (Evergreen.V216.Discord.Id Evergreen.V216.Discord.MessageId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) Evergreen.V216.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V216.GuildName.GuildName
    , icon : Maybe Evergreen.V216.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V216.MembersAndOwner.MembersAndOwner
            (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V216.Id.Id Evergreen.V216.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V216.Id.Id Evergreen.V216.Id.CustomEmojiId)
    }
