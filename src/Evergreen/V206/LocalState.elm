module Evergreen.V206.LocalState exposing (..)

import Array
import Effect.Lamdera
import Effect.Time
import Evergreen.V206.ChannelDescription
import Evergreen.V206.ChannelName
import Evergreen.V206.Discord
import Evergreen.V206.DiscordUserData
import Evergreen.V206.DmChannel
import Evergreen.V206.FileStatus
import Evergreen.V206.GuildName
import Evergreen.V206.Id
import Evergreen.V206.Log
import Evergreen.V206.MembersAndOwner
import Evergreen.V206.Message
import Evergreen.V206.NonemptyDict
import Evergreen.V206.OneToOne
import Evergreen.V206.Pagination
import Evergreen.V206.Postmark
import Evergreen.V206.SecretId
import Evergreen.V206.SessionIdHash
import Evergreen.V206.Slack
import Evergreen.V206.Sticker
import Evergreen.V206.TextEditor
import Evergreen.V206.Thread
import Evergreen.V206.ToBackendLog
import Evergreen.V206.User
import Evergreen.V206.UserAgent
import Evergreen.V206.UserSession
import Evergreen.V206.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V206.NonemptyDict.NonemptyDict
            (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V206.Message.Message Evergreen.V206.Id.ChannelMessageId (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V206.Discord.PartialUser
        , icon : Maybe Evergreen.V206.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V206.Discord.User
        , linkedTo : Evergreen.V206.Id.Id Evergreen.V206.Id.UserId
        , icon : Maybe Evergreen.V206.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V206.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V206.Discord.User
        , linkedTo : Evergreen.V206.Id.Id Evergreen.V206.Id.UserId
        , icon : Maybe Evergreen.V206.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V206.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V206.Message.Message Evergreen.V206.Id.ChannelMessageId (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V206.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V206.MembersAndOwner.MembersAndOwner
            (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V206.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V206.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V206.Id.Id Evergreen.V206.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V206.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V206.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V206.Id.Id Evergreen.V206.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V206.Id.Id Evergreen.V206.Id.UserId
    , name : Evergreen.V206.ChannelName.ChannelName
    , description : Evergreen.V206.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V206.Message.MessageState Evergreen.V206.Id.ChannelMessageId (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId))
    , visibleMessages : Evergreen.V206.VisibleMessages.VisibleMessages Evergreen.V206.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) (Evergreen.V206.Thread.LastTypedAt Evergreen.V206.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) Evergreen.V206.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V206.Id.Id Evergreen.V206.Id.UserId
    , name : Evergreen.V206.GuildName.GuildName
    , icon : Maybe Evergreen.V206.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V206.MembersAndOwner.MembersAndOwner
            (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V206.SecretId.SecretId Evergreen.V206.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V206.Id.Id Evergreen.V206.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V206.ChannelName.ChannelName
    , description : Evergreen.V206.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V206.Message.MessageState Evergreen.V206.Id.ChannelMessageId (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId))
    , visibleMessages : Evergreen.V206.VisibleMessages.VisibleMessages Evergreen.V206.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Evergreen.V206.Thread.LastTypedAt Evergreen.V206.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) Evergreen.V206.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V206.GuildName.GuildName
    , icon : Maybe Evergreen.V206.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V206.MembersAndOwner.MembersAndOwner
            (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V206.Id.Id Evergreen.V206.Id.StickerId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V206.NonemptyDict.NonemptyDict (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) Evergreen.V206.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V206.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V206.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V206.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V206.SessionIdHash.SessionIdHash (Evergreen.V206.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V206.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V206.UserSession.UserSession
    , user : Evergreen.V206.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) Evergreen.V206.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) Evergreen.V206.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) Evergreen.V206.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V206.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.StickerId) Evergreen.V206.Sticker.StickerData
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) Evergreen.V206.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId) Evergreen.V206.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V206.SessionIdHash.SessionIdHash Evergreen.V206.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V206.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V206.Id.Id Evergreen.V206.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V206.Id.Id Evergreen.V206.Id.UserId
    , name : Evergreen.V206.ChannelName.ChannelName
    , description : Evergreen.V206.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V206.Message.Message Evergreen.V206.Id.ChannelMessageId (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) (Evergreen.V206.Thread.LastTypedAt Evergreen.V206.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) Evergreen.V206.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V206.Id.Id Evergreen.V206.Id.UserId
    , name : Evergreen.V206.GuildName.GuildName
    , icon : Maybe Evergreen.V206.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V206.MembersAndOwner.MembersAndOwner
            (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V206.SecretId.SecretId Evergreen.V206.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V206.Id.Id Evergreen.V206.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V206.ChannelName.ChannelName
    , description : Evergreen.V206.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V206.Message.Message Evergreen.V206.Id.ChannelMessageId (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Evergreen.V206.Thread.LastTypedAt Evergreen.V206.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V206.OneToOne.OneToOne (Evergreen.V206.Discord.Id Evergreen.V206.Discord.MessageId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) Evergreen.V206.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V206.GuildName.GuildName
    , icon : Maybe Evergreen.V206.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V206.MembersAndOwner.MembersAndOwner
            (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V206.Id.Id Evergreen.V206.Id.StickerId)
    }
