module Evergreen.V199.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V199.ChannelDescription
import Evergreen.V199.ChannelName
import Evergreen.V199.Discord
import Evergreen.V199.DiscordUserData
import Evergreen.V199.DmChannel
import Evergreen.V199.FileStatus
import Evergreen.V199.GuildName
import Evergreen.V199.Id
import Evergreen.V199.Log
import Evergreen.V199.MembersAndOwner
import Evergreen.V199.Message
import Evergreen.V199.NonemptyDict
import Evergreen.V199.OneToOne
import Evergreen.V199.Pagination
import Evergreen.V199.SecretId
import Evergreen.V199.SessionIdHash
import Evergreen.V199.Slack
import Evergreen.V199.Sticker
import Evergreen.V199.TextEditor
import Evergreen.V199.Thread
import Evergreen.V199.ToBackendLog
import Evergreen.V199.User
import Evergreen.V199.UserAgent
import Evergreen.V199.UserSession
import Evergreen.V199.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V199.NonemptyDict.NonemptyDict
            (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V199.Message.Message Evergreen.V199.Id.ChannelMessageId (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V199.Discord.PartialUser
        , icon : Maybe Evergreen.V199.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V199.Discord.User
        , linkedTo : Evergreen.V199.Id.Id Evergreen.V199.Id.UserId
        , icon : Maybe Evergreen.V199.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V199.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V199.Discord.User
        , linkedTo : Evergreen.V199.Id.Id Evergreen.V199.Id.UserId
        , icon : Maybe Evergreen.V199.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V199.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V199.Message.Message Evergreen.V199.Id.ChannelMessageId (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V199.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V199.MembersAndOwner.MembersAndOwner
            (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V199.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V199.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V199.Id.Id Evergreen.V199.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V199.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V199.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V199.Id.Id Evergreen.V199.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V199.Id.Id Evergreen.V199.Id.UserId
    , name : Evergreen.V199.ChannelName.ChannelName
    , description : Evergreen.V199.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V199.Message.MessageState Evergreen.V199.Id.ChannelMessageId (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId))
    , visibleMessages : Evergreen.V199.VisibleMessages.VisibleMessages Evergreen.V199.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) (Evergreen.V199.Thread.LastTypedAt Evergreen.V199.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) Evergreen.V199.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V199.Id.Id Evergreen.V199.Id.UserId
    , name : Evergreen.V199.GuildName.GuildName
    , icon : Maybe Evergreen.V199.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V199.MembersAndOwner.MembersAndOwner
            (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V199.SecretId.SecretId Evergreen.V199.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V199.Id.Id Evergreen.V199.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V199.ChannelName.ChannelName
    , description : Evergreen.V199.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V199.Message.MessageState Evergreen.V199.Id.ChannelMessageId (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId))
    , visibleMessages : Evergreen.V199.VisibleMessages.VisibleMessages Evergreen.V199.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Evergreen.V199.Thread.LastTypedAt Evergreen.V199.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) Evergreen.V199.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V199.GuildName.GuildName
    , icon : Maybe Evergreen.V199.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V199.MembersAndOwner.MembersAndOwner
            (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V199.Id.Id Evergreen.V199.Id.StickerId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V199.NonemptyDict.NonemptyDict (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) Evergreen.V199.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V199.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V199.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V199.SessionIdHash.SessionIdHash (Evergreen.V199.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V199.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V199.UserSession.UserSession
    , user : Evergreen.V199.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) Evergreen.V199.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) Evergreen.V199.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) Evergreen.V199.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V199.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.StickerId) Evergreen.V199.Sticker.StickerData
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) Evergreen.V199.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId) Evergreen.V199.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V199.SessionIdHash.SessionIdHash Evergreen.V199.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V199.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V199.Id.Id Evergreen.V199.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V199.Id.Id Evergreen.V199.Id.UserId
    , name : Evergreen.V199.ChannelName.ChannelName
    , description : Evergreen.V199.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V199.Message.Message Evergreen.V199.Id.ChannelMessageId (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) (Evergreen.V199.Thread.LastTypedAt Evergreen.V199.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) Evergreen.V199.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V199.Id.Id Evergreen.V199.Id.UserId
    , name : Evergreen.V199.GuildName.GuildName
    , icon : Maybe Evergreen.V199.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V199.MembersAndOwner.MembersAndOwner
            (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V199.SecretId.SecretId Evergreen.V199.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V199.Id.Id Evergreen.V199.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V199.ChannelName.ChannelName
    , description : Evergreen.V199.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V199.Message.Message Evergreen.V199.Id.ChannelMessageId (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Evergreen.V199.Thread.LastTypedAt Evergreen.V199.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V199.OneToOne.OneToOne (Evergreen.V199.Discord.Id Evergreen.V199.Discord.MessageId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) Evergreen.V199.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V199.GuildName.GuildName
    , icon : Maybe Evergreen.V199.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V199.MembersAndOwner.MembersAndOwner
            (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V199.Id.Id Evergreen.V199.Id.StickerId)
    }
