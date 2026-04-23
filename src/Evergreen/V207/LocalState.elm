module Evergreen.V207.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V207.ChannelDescription
import Evergreen.V207.ChannelName
import Evergreen.V207.Discord
import Evergreen.V207.DiscordUserData
import Evergreen.V207.DmChannel
import Evergreen.V207.FileStatus
import Evergreen.V207.GuildName
import Evergreen.V207.Id
import Evergreen.V207.Log
import Evergreen.V207.MembersAndOwner
import Evergreen.V207.Message
import Evergreen.V207.NonemptyDict
import Evergreen.V207.OneToOne
import Evergreen.V207.Pagination
import Evergreen.V207.Postmark
import Evergreen.V207.SecretId
import Evergreen.V207.SessionIdHash
import Evergreen.V207.Slack
import Evergreen.V207.Sticker
import Evergreen.V207.TextEditor
import Evergreen.V207.Thread
import Evergreen.V207.ToBackendLog
import Evergreen.V207.User
import Evergreen.V207.UserAgent
import Evergreen.V207.UserSession
import Evergreen.V207.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V207.NonemptyDict.NonemptyDict
            (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V207.Message.Message Evergreen.V207.Id.ChannelMessageId (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V207.Discord.PartialUser
        , icon : Maybe Evergreen.V207.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V207.Discord.User
        , linkedTo : Evergreen.V207.Id.Id Evergreen.V207.Id.UserId
        , icon : Maybe Evergreen.V207.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V207.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V207.Discord.User
        , linkedTo : Evergreen.V207.Id.Id Evergreen.V207.Id.UserId
        , icon : Maybe Evergreen.V207.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V207.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V207.Message.Message Evergreen.V207.Id.ChannelMessageId (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V207.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V207.MembersAndOwner.MembersAndOwner
            (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V207.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V207.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V207.Id.Id Evergreen.V207.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V207.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V207.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V207.Id.Id Evergreen.V207.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V207.Id.Id Evergreen.V207.Id.UserId
    , name : Evergreen.V207.ChannelName.ChannelName
    , description : Evergreen.V207.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V207.Message.MessageState Evergreen.V207.Id.ChannelMessageId (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId))
    , visibleMessages : Evergreen.V207.VisibleMessages.VisibleMessages Evergreen.V207.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) (Evergreen.V207.Thread.LastTypedAt Evergreen.V207.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) Evergreen.V207.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V207.Id.Id Evergreen.V207.Id.UserId
    , name : Evergreen.V207.GuildName.GuildName
    , icon : Maybe Evergreen.V207.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V207.MembersAndOwner.MembersAndOwner
            (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V207.SecretId.SecretId Evergreen.V207.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V207.Id.Id Evergreen.V207.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V207.ChannelName.ChannelName
    , description : Evergreen.V207.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V207.Message.MessageState Evergreen.V207.Id.ChannelMessageId (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId))
    , visibleMessages : Evergreen.V207.VisibleMessages.VisibleMessages Evergreen.V207.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Evergreen.V207.Thread.LastTypedAt Evergreen.V207.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) Evergreen.V207.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V207.GuildName.GuildName
    , icon : Maybe Evergreen.V207.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V207.MembersAndOwner.MembersAndOwner
            (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V207.Id.Id Evergreen.V207.Id.StickerId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V207.NonemptyDict.NonemptyDict (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) Evergreen.V207.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V207.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V207.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V207.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V207.SessionIdHash.SessionIdHash (Evergreen.V207.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V207.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V207.UserSession.UserSession
    , user : Evergreen.V207.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) Evergreen.V207.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) Evergreen.V207.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) Evergreen.V207.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V207.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.StickerId) Evergreen.V207.Sticker.StickerData
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) Evergreen.V207.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId) Evergreen.V207.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V207.SessionIdHash.SessionIdHash Evergreen.V207.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V207.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V207.Id.Id Evergreen.V207.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V207.Id.Id Evergreen.V207.Id.UserId
    , name : Evergreen.V207.ChannelName.ChannelName
    , description : Evergreen.V207.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V207.Message.Message Evergreen.V207.Id.ChannelMessageId (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) (Evergreen.V207.Thread.LastTypedAt Evergreen.V207.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) Evergreen.V207.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V207.Id.Id Evergreen.V207.Id.UserId
    , name : Evergreen.V207.GuildName.GuildName
    , icon : Maybe Evergreen.V207.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V207.MembersAndOwner.MembersAndOwner
            (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V207.SecretId.SecretId Evergreen.V207.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V207.Id.Id Evergreen.V207.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V207.ChannelName.ChannelName
    , description : Evergreen.V207.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V207.Message.Message Evergreen.V207.Id.ChannelMessageId (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Evergreen.V207.Thread.LastTypedAt Evergreen.V207.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V207.OneToOne.OneToOne (Evergreen.V207.Discord.Id Evergreen.V207.Discord.MessageId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) Evergreen.V207.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V207.GuildName.GuildName
    , icon : Maybe Evergreen.V207.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V207.MembersAndOwner.MembersAndOwner
            (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V207.Id.Id Evergreen.V207.Id.StickerId)
    }
