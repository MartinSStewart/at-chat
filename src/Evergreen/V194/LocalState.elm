module Evergreen.V194.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V194.ChannelDescription
import Evergreen.V194.ChannelName
import Evergreen.V194.Discord
import Evergreen.V194.DiscordUserData
import Evergreen.V194.DmChannel
import Evergreen.V194.FileStatus
import Evergreen.V194.GuildName
import Evergreen.V194.Id
import Evergreen.V194.Log
import Evergreen.V194.MembersAndOwner
import Evergreen.V194.Message
import Evergreen.V194.NonemptyDict
import Evergreen.V194.OneToOne
import Evergreen.V194.Pagination
import Evergreen.V194.SecretId
import Evergreen.V194.SessionIdHash
import Evergreen.V194.Slack
import Evergreen.V194.Sticker
import Evergreen.V194.TextEditor
import Evergreen.V194.Thread
import Evergreen.V194.ToBackendLog
import Evergreen.V194.User
import Evergreen.V194.UserAgent
import Evergreen.V194.UserSession
import Evergreen.V194.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V194.NonemptyDict.NonemptyDict
            (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V194.Message.Message Evergreen.V194.Id.ChannelMessageId (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V194.Discord.PartialUser
        , icon : Maybe Evergreen.V194.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V194.Discord.User
        , linkedTo : Evergreen.V194.Id.Id Evergreen.V194.Id.UserId
        , icon : Maybe Evergreen.V194.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V194.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V194.Discord.User
        , linkedTo : Evergreen.V194.Id.Id Evergreen.V194.Id.UserId
        , icon : Maybe Evergreen.V194.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V194.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V194.Message.Message Evergreen.V194.Id.ChannelMessageId (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V194.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V194.MembersAndOwner.MembersAndOwner
            (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V194.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V194.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V194.Id.Id Evergreen.V194.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V194.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V194.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V194.Id.Id Evergreen.V194.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V194.Id.Id Evergreen.V194.Id.UserId
    , name : Evergreen.V194.ChannelName.ChannelName
    , description : Evergreen.V194.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V194.Message.MessageState Evergreen.V194.Id.ChannelMessageId (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId))
    , visibleMessages : Evergreen.V194.VisibleMessages.VisibleMessages Evergreen.V194.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) (Evergreen.V194.Thread.LastTypedAt Evergreen.V194.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) Evergreen.V194.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V194.Id.Id Evergreen.V194.Id.UserId
    , name : Evergreen.V194.GuildName.GuildName
    , icon : Maybe Evergreen.V194.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V194.MembersAndOwner.MembersAndOwner
            (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V194.SecretId.SecretId Evergreen.V194.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V194.Id.Id Evergreen.V194.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V194.ChannelName.ChannelName
    , description : Evergreen.V194.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V194.Message.MessageState Evergreen.V194.Id.ChannelMessageId (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId))
    , visibleMessages : Evergreen.V194.VisibleMessages.VisibleMessages Evergreen.V194.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Evergreen.V194.Thread.LastTypedAt Evergreen.V194.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) Evergreen.V194.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V194.GuildName.GuildName
    , icon : Maybe Evergreen.V194.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V194.MembersAndOwner.MembersAndOwner
            (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V194.Id.Id Evergreen.V194.Id.StickerId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V194.NonemptyDict.NonemptyDict (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) Evergreen.V194.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V194.Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V194.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V194.SessionIdHash.SessionIdHash (Evergreen.V194.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V194.ToBackendLog.ToBackendLogData
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V194.UserSession.UserSession
    , user : Evergreen.V194.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) Evergreen.V194.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) Evergreen.V194.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) Evergreen.V194.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V194.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.StickerId) Evergreen.V194.Sticker.StickerData
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) Evergreen.V194.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId) Evergreen.V194.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V194.SessionIdHash.SessionIdHash Evergreen.V194.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V194.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V194.Id.Id Evergreen.V194.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V194.Id.Id Evergreen.V194.Id.UserId
    , name : Evergreen.V194.ChannelName.ChannelName
    , description : Evergreen.V194.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V194.Message.Message Evergreen.V194.Id.ChannelMessageId (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) (Evergreen.V194.Thread.LastTypedAt Evergreen.V194.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) Evergreen.V194.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V194.Id.Id Evergreen.V194.Id.UserId
    , name : Evergreen.V194.GuildName.GuildName
    , icon : Maybe Evergreen.V194.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V194.MembersAndOwner.MembersAndOwner
            (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V194.SecretId.SecretId Evergreen.V194.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V194.Id.Id Evergreen.V194.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V194.ChannelName.ChannelName
    , description : Evergreen.V194.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V194.Message.Message Evergreen.V194.Id.ChannelMessageId (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Evergreen.V194.Thread.LastTypedAt Evergreen.V194.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V194.OneToOne.OneToOne (Evergreen.V194.Discord.Id Evergreen.V194.Discord.MessageId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) Evergreen.V194.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V194.GuildName.GuildName
    , icon : Maybe Evergreen.V194.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V194.MembersAndOwner.MembersAndOwner
            (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V194.Id.Id Evergreen.V194.Id.StickerId)
    }
