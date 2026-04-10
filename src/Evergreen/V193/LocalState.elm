module Evergreen.V193.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V193.ChannelDescription
import Evergreen.V193.ChannelName
import Evergreen.V193.Discord
import Evergreen.V193.DiscordUserData
import Evergreen.V193.DmChannel
import Evergreen.V193.FileStatus
import Evergreen.V193.GuildName
import Evergreen.V193.Id
import Evergreen.V193.Log
import Evergreen.V193.MembersAndOwner
import Evergreen.V193.Message
import Evergreen.V193.NonemptyDict
import Evergreen.V193.OneToOne
import Evergreen.V193.Pagination
import Evergreen.V193.SecretId
import Evergreen.V193.SessionIdHash
import Evergreen.V193.Slack
import Evergreen.V193.Sticker
import Evergreen.V193.TextEditor
import Evergreen.V193.Thread
import Evergreen.V193.ToBackendLog
import Evergreen.V193.User
import Evergreen.V193.UserAgent
import Evergreen.V193.UserSession
import Evergreen.V193.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V193.NonemptyDict.NonemptyDict
            (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V193.Message.Message Evergreen.V193.Id.ChannelMessageId (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V193.Discord.PartialUser
        , icon : Maybe Evergreen.V193.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V193.Discord.User
        , linkedTo : Evergreen.V193.Id.Id Evergreen.V193.Id.UserId
        , icon : Maybe Evergreen.V193.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V193.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V193.Discord.User
        , linkedTo : Evergreen.V193.Id.Id Evergreen.V193.Id.UserId
        , icon : Maybe Evergreen.V193.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V193.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V193.Message.Message Evergreen.V193.Id.ChannelMessageId (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V193.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V193.MembersAndOwner.MembersAndOwner
            (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V193.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V193.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V193.Id.Id Evergreen.V193.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V193.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V193.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V193.Id.Id Evergreen.V193.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V193.Id.Id Evergreen.V193.Id.UserId
    , name : Evergreen.V193.ChannelName.ChannelName
    , description : Evergreen.V193.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V193.Message.MessageState Evergreen.V193.Id.ChannelMessageId (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId))
    , visibleMessages : Evergreen.V193.VisibleMessages.VisibleMessages Evergreen.V193.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) (Evergreen.V193.Thread.LastTypedAt Evergreen.V193.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) Evergreen.V193.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V193.Id.Id Evergreen.V193.Id.UserId
    , name : Evergreen.V193.GuildName.GuildName
    , icon : Maybe Evergreen.V193.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V193.MembersAndOwner.MembersAndOwner
            (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V193.SecretId.SecretId Evergreen.V193.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V193.Id.Id Evergreen.V193.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V193.ChannelName.ChannelName
    , description : Evergreen.V193.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V193.Message.MessageState Evergreen.V193.Id.ChannelMessageId (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId))
    , visibleMessages : Evergreen.V193.VisibleMessages.VisibleMessages Evergreen.V193.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Evergreen.V193.Thread.LastTypedAt Evergreen.V193.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) Evergreen.V193.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V193.GuildName.GuildName
    , icon : Maybe Evergreen.V193.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V193.MembersAndOwner.MembersAndOwner
            (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V193.Id.Id Evergreen.V193.Id.StickerId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V193.NonemptyDict.NonemptyDict (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) Evergreen.V193.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V193.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V193.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V193.SessionIdHash.SessionIdHash (Evergreen.V193.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V193.ToBackendLog.ToBackendLogData
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V193.UserSession.UserSession
    , user : Evergreen.V193.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) Evergreen.V193.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) Evergreen.V193.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) Evergreen.V193.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V193.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.StickerId) Evergreen.V193.Sticker.StickerData
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) Evergreen.V193.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId) Evergreen.V193.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V193.SessionIdHash.SessionIdHash Evergreen.V193.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V193.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V193.Id.Id Evergreen.V193.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V193.Id.Id Evergreen.V193.Id.UserId
    , name : Evergreen.V193.ChannelName.ChannelName
    , description : Evergreen.V193.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V193.Message.Message Evergreen.V193.Id.ChannelMessageId (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) (Evergreen.V193.Thread.LastTypedAt Evergreen.V193.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) Evergreen.V193.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V193.Id.Id Evergreen.V193.Id.UserId
    , name : Evergreen.V193.GuildName.GuildName
    , icon : Maybe Evergreen.V193.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V193.MembersAndOwner.MembersAndOwner
            (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V193.SecretId.SecretId Evergreen.V193.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V193.Id.Id Evergreen.V193.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V193.ChannelName.ChannelName
    , description : Evergreen.V193.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V193.Message.Message Evergreen.V193.Id.ChannelMessageId (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Evergreen.V193.Thread.LastTypedAt Evergreen.V193.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V193.OneToOne.OneToOne (Evergreen.V193.Discord.Id Evergreen.V193.Discord.MessageId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) Evergreen.V193.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V193.GuildName.GuildName
    , icon : Maybe Evergreen.V193.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V193.MembersAndOwner.MembersAndOwner
            (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V193.Id.Id Evergreen.V193.Id.StickerId)
    }
