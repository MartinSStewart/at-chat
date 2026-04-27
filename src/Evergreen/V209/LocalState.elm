module Evergreen.V209.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V209.ChannelDescription
import Evergreen.V209.ChannelName
import Evergreen.V209.Discord
import Evergreen.V209.DiscordUserData
import Evergreen.V209.DmChannel
import Evergreen.V209.FileStatus
import Evergreen.V209.GuildName
import Evergreen.V209.Id
import Evergreen.V209.Log
import Evergreen.V209.MembersAndOwner
import Evergreen.V209.Message
import Evergreen.V209.NonemptyDict
import Evergreen.V209.OneToOne
import Evergreen.V209.Pagination
import Evergreen.V209.Postmark
import Evergreen.V209.SecretId
import Evergreen.V209.SessionIdHash
import Evergreen.V209.Slack
import Evergreen.V209.Sticker
import Evergreen.V209.TextEditor
import Evergreen.V209.Thread
import Evergreen.V209.ToBackendLog
import Evergreen.V209.User
import Evergreen.V209.UserAgent
import Evergreen.V209.UserSession
import Evergreen.V209.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V209.NonemptyDict.NonemptyDict
            (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V209.Message.Message Evergreen.V209.Id.ChannelMessageId (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V209.Discord.PartialUser
        , icon : Maybe Evergreen.V209.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V209.Discord.User
        , linkedTo : Evergreen.V209.Id.Id Evergreen.V209.Id.UserId
        , icon : Maybe Evergreen.V209.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V209.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V209.Discord.User
        , linkedTo : Evergreen.V209.Id.Id Evergreen.V209.Id.UserId
        , icon : Maybe Evergreen.V209.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V209.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V209.Message.Message Evergreen.V209.Id.ChannelMessageId (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V209.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V209.MembersAndOwner.MembersAndOwner
            (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V209.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V209.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V209.Id.Id Evergreen.V209.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V209.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V209.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V209.Id.Id Evergreen.V209.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V209.Id.Id Evergreen.V209.Id.UserId
    , name : Evergreen.V209.ChannelName.ChannelName
    , description : Evergreen.V209.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V209.Message.MessageState Evergreen.V209.Id.ChannelMessageId (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId))
    , visibleMessages : Evergreen.V209.VisibleMessages.VisibleMessages Evergreen.V209.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) (Evergreen.V209.Thread.LastTypedAt Evergreen.V209.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) Evergreen.V209.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V209.Id.Id Evergreen.V209.Id.UserId
    , name : Evergreen.V209.GuildName.GuildName
    , icon : Maybe Evergreen.V209.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V209.MembersAndOwner.MembersAndOwner
            (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V209.SecretId.SecretId Evergreen.V209.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V209.Id.Id Evergreen.V209.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V209.ChannelName.ChannelName
    , description : Evergreen.V209.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V209.Message.MessageState Evergreen.V209.Id.ChannelMessageId (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId))
    , visibleMessages : Evergreen.V209.VisibleMessages.VisibleMessages Evergreen.V209.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Evergreen.V209.Thread.LastTypedAt Evergreen.V209.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) Evergreen.V209.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V209.GuildName.GuildName
    , icon : Maybe Evergreen.V209.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V209.MembersAndOwner.MembersAndOwner
            (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V209.Id.Id Evergreen.V209.Id.StickerId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V209.NonemptyDict.NonemptyDict (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) Evergreen.V209.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V209.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V209.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V209.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V209.SessionIdHash.SessionIdHash (Evergreen.V209.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V209.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V209.UserSession.UserSession
    , user : Evergreen.V209.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) Evergreen.V209.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) Evergreen.V209.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) Evergreen.V209.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V209.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.StickerId) Evergreen.V209.Sticker.StickerData
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) Evergreen.V209.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId) Evergreen.V209.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V209.SessionIdHash.SessionIdHash Evergreen.V209.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V209.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V209.Id.Id Evergreen.V209.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V209.Id.Id Evergreen.V209.Id.UserId
    , name : Evergreen.V209.ChannelName.ChannelName
    , description : Evergreen.V209.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V209.Message.Message Evergreen.V209.Id.ChannelMessageId (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) (Evergreen.V209.Thread.LastTypedAt Evergreen.V209.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) Evergreen.V209.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V209.Id.Id Evergreen.V209.Id.UserId
    , name : Evergreen.V209.GuildName.GuildName
    , icon : Maybe Evergreen.V209.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V209.MembersAndOwner.MembersAndOwner
            (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V209.SecretId.SecretId Evergreen.V209.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V209.Id.Id Evergreen.V209.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V209.ChannelName.ChannelName
    , description : Evergreen.V209.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V209.Message.Message Evergreen.V209.Id.ChannelMessageId (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Evergreen.V209.Thread.LastTypedAt Evergreen.V209.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V209.OneToOne.OneToOne (Evergreen.V209.Discord.Id Evergreen.V209.Discord.MessageId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) Evergreen.V209.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V209.GuildName.GuildName
    , icon : Maybe Evergreen.V209.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V209.MembersAndOwner.MembersAndOwner
            (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V209.Id.Id Evergreen.V209.Id.StickerId)
    }
