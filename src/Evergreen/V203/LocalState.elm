module Evergreen.V203.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V203.ChannelDescription
import Evergreen.V203.ChannelName
import Evergreen.V203.Discord
import Evergreen.V203.DiscordUserData
import Evergreen.V203.DmChannel
import Evergreen.V203.FileStatus
import Evergreen.V203.GuildName
import Evergreen.V203.Id
import Evergreen.V203.Log
import Evergreen.V203.MembersAndOwner
import Evergreen.V203.Message
import Evergreen.V203.NonemptyDict
import Evergreen.V203.OneToOne
import Evergreen.V203.Pagination
import Evergreen.V203.SecretId
import Evergreen.V203.SessionIdHash
import Evergreen.V203.Slack
import Evergreen.V203.Sticker
import Evergreen.V203.TextEditor
import Evergreen.V203.Thread
import Evergreen.V203.ToBackendLog
import Evergreen.V203.User
import Evergreen.V203.UserAgent
import Evergreen.V203.UserSession
import Evergreen.V203.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V203.NonemptyDict.NonemptyDict
            (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V203.Message.Message Evergreen.V203.Id.ChannelMessageId (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V203.Discord.PartialUser
        , icon : Maybe Evergreen.V203.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V203.Discord.User
        , linkedTo : Evergreen.V203.Id.Id Evergreen.V203.Id.UserId
        , icon : Maybe Evergreen.V203.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V203.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V203.Discord.User
        , linkedTo : Evergreen.V203.Id.Id Evergreen.V203.Id.UserId
        , icon : Maybe Evergreen.V203.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V203.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V203.Message.Message Evergreen.V203.Id.ChannelMessageId (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V203.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V203.MembersAndOwner.MembersAndOwner
            (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V203.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V203.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V203.Id.Id Evergreen.V203.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V203.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V203.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V203.Id.Id Evergreen.V203.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V203.Id.Id Evergreen.V203.Id.UserId
    , name : Evergreen.V203.ChannelName.ChannelName
    , description : Evergreen.V203.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V203.Message.MessageState Evergreen.V203.Id.ChannelMessageId (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId))
    , visibleMessages : Evergreen.V203.VisibleMessages.VisibleMessages Evergreen.V203.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) (Evergreen.V203.Thread.LastTypedAt Evergreen.V203.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) Evergreen.V203.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V203.Id.Id Evergreen.V203.Id.UserId
    , name : Evergreen.V203.GuildName.GuildName
    , icon : Maybe Evergreen.V203.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V203.MembersAndOwner.MembersAndOwner
            (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V203.SecretId.SecretId Evergreen.V203.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V203.Id.Id Evergreen.V203.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V203.ChannelName.ChannelName
    , description : Evergreen.V203.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V203.Message.MessageState Evergreen.V203.Id.ChannelMessageId (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId))
    , visibleMessages : Evergreen.V203.VisibleMessages.VisibleMessages Evergreen.V203.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Evergreen.V203.Thread.LastTypedAt Evergreen.V203.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) Evergreen.V203.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V203.GuildName.GuildName
    , icon : Maybe Evergreen.V203.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V203.MembersAndOwner.MembersAndOwner
            (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V203.Id.Id Evergreen.V203.Id.StickerId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V203.NonemptyDict.NonemptyDict (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) Evergreen.V203.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V203.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V203.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V203.SessionIdHash.SessionIdHash (Evergreen.V203.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V203.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V203.UserSession.UserSession
    , user : Evergreen.V203.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) Evergreen.V203.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) Evergreen.V203.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) Evergreen.V203.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V203.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.StickerId) Evergreen.V203.Sticker.StickerData
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) Evergreen.V203.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId) Evergreen.V203.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V203.SessionIdHash.SessionIdHash Evergreen.V203.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V203.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V203.Id.Id Evergreen.V203.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V203.Id.Id Evergreen.V203.Id.UserId
    , name : Evergreen.V203.ChannelName.ChannelName
    , description : Evergreen.V203.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V203.Message.Message Evergreen.V203.Id.ChannelMessageId (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) (Evergreen.V203.Thread.LastTypedAt Evergreen.V203.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) Evergreen.V203.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V203.Id.Id Evergreen.V203.Id.UserId
    , name : Evergreen.V203.GuildName.GuildName
    , icon : Maybe Evergreen.V203.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V203.MembersAndOwner.MembersAndOwner
            (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V203.SecretId.SecretId Evergreen.V203.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V203.Id.Id Evergreen.V203.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V203.ChannelName.ChannelName
    , description : Evergreen.V203.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V203.Message.Message Evergreen.V203.Id.ChannelMessageId (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Evergreen.V203.Thread.LastTypedAt Evergreen.V203.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V203.OneToOne.OneToOne (Evergreen.V203.Discord.Id Evergreen.V203.Discord.MessageId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) Evergreen.V203.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V203.GuildName.GuildName
    , icon : Maybe Evergreen.V203.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V203.MembersAndOwner.MembersAndOwner
            (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V203.Id.Id Evergreen.V203.Id.StickerId)
    }
