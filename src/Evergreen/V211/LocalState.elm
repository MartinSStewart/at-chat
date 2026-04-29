module Evergreen.V211.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V211.ChannelDescription
import Evergreen.V211.ChannelName
import Evergreen.V211.CustomEmoji
import Evergreen.V211.Discord
import Evergreen.V211.DiscordUserData
import Evergreen.V211.DmChannel
import Evergreen.V211.FileStatus
import Evergreen.V211.GuildName
import Evergreen.V211.Id
import Evergreen.V211.Log
import Evergreen.V211.MembersAndOwner
import Evergreen.V211.Message
import Evergreen.V211.NonemptyDict
import Evergreen.V211.OneToOne
import Evergreen.V211.Pagination
import Evergreen.V211.Postmark
import Evergreen.V211.SecretId
import Evergreen.V211.SessionIdHash
import Evergreen.V211.Slack
import Evergreen.V211.Sticker
import Evergreen.V211.TextEditor
import Evergreen.V211.Thread
import Evergreen.V211.ToBackendLog
import Evergreen.V211.User
import Evergreen.V211.UserAgent
import Evergreen.V211.UserSession
import Evergreen.V211.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V211.NonemptyDict.NonemptyDict
            (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V211.Message.Message Evergreen.V211.Id.ChannelMessageId (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V211.Discord.PartialUser
        , icon : Maybe Evergreen.V211.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V211.Discord.User
        , linkedTo : Evergreen.V211.Id.Id Evergreen.V211.Id.UserId
        , icon : Maybe Evergreen.V211.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V211.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V211.Discord.User
        , linkedTo : Evergreen.V211.Id.Id Evergreen.V211.Id.UserId
        , icon : Maybe Evergreen.V211.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V211.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V211.Message.Message Evergreen.V211.Id.ChannelMessageId (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V211.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V211.Discord.Id Evergreen.V211.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V211.MembersAndOwner.MembersAndOwner
            (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V211.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V211.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V211.Id.Id Evergreen.V211.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V211.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V211.Discord.Id Evergreen.V211.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V211.Discord.Id Evergreen.V211.Discord.GuildId) (Evergreen.V211.Discord.Id Evergreen.V211.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V211.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V211.Id.Id Evergreen.V211.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V211.Id.Id Evergreen.V211.Id.UserId
    , name : Evergreen.V211.ChannelName.ChannelName
    , description : Evergreen.V211.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V211.Message.MessageState Evergreen.V211.Id.ChannelMessageId (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId))
    , visibleMessages : Evergreen.V211.VisibleMessages.VisibleMessages Evergreen.V211.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId) (Evergreen.V211.Thread.LastTypedAt Evergreen.V211.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelMessageId) Evergreen.V211.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V211.Id.Id Evergreen.V211.Id.UserId
    , name : Evergreen.V211.GuildName.GuildName
    , icon : Maybe Evergreen.V211.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V211.MembersAndOwner.MembersAndOwner
            (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V211.SecretId.SecretId Evergreen.V211.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V211.Id.Id Evergreen.V211.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V211.ChannelName.ChannelName
    , description : Evergreen.V211.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V211.Message.MessageState Evergreen.V211.Id.ChannelMessageId (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId))
    , visibleMessages : Evergreen.V211.VisibleMessages.VisibleMessages Evergreen.V211.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId) (Evergreen.V211.Thread.LastTypedAt Evergreen.V211.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelMessageId) Evergreen.V211.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V211.GuildName.GuildName
    , icon : Maybe Evergreen.V211.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V211.Discord.Id Evergreen.V211.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V211.MembersAndOwner.MembersAndOwner
            (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V211.Id.Id Evergreen.V211.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V211.Id.Id Evergreen.V211.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V211.NonemptyDict.NonemptyDict (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId) Evergreen.V211.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V211.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V211.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V211.Discord.Id Evergreen.V211.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V211.Discord.Id Evergreen.V211.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V211.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V211.SessionIdHash.SessionIdHash (Evergreen.V211.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V211.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V211.UserSession.UserSession
    , user : Evergreen.V211.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId) Evergreen.V211.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId) Evergreen.V211.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId) Evergreen.V211.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V211.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.StickerId) Evergreen.V211.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.CustomEmojiId) Evergreen.V211.CustomEmoji.CustomEmojiData
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V211.Discord.Id Evergreen.V211.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId) Evergreen.V211.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V211.Discord.Id Evergreen.V211.Discord.PrivateChannelId) Evergreen.V211.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V211.SessionIdHash.SessionIdHash Evergreen.V211.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V211.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V211.Id.Id Evergreen.V211.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V211.Id.Id Evergreen.V211.Id.UserId
    , name : Evergreen.V211.ChannelName.ChannelName
    , description : Evergreen.V211.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V211.Message.Message Evergreen.V211.Id.ChannelMessageId (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId) (Evergreen.V211.Thread.LastTypedAt Evergreen.V211.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelMessageId) Evergreen.V211.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V211.Id.Id Evergreen.V211.Id.UserId
    , name : Evergreen.V211.GuildName.GuildName
    , icon : Maybe Evergreen.V211.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V211.MembersAndOwner.MembersAndOwner
            (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V211.SecretId.SecretId Evergreen.V211.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V211.Id.Id Evergreen.V211.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V211.ChannelName.ChannelName
    , description : Evergreen.V211.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V211.Message.Message Evergreen.V211.Id.ChannelMessageId (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId) (Evergreen.V211.Thread.LastTypedAt Evergreen.V211.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V211.OneToOne.OneToOne (Evergreen.V211.Discord.Id Evergreen.V211.Discord.MessageId) (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelMessageId) Evergreen.V211.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V211.GuildName.GuildName
    , icon : Maybe Evergreen.V211.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V211.Discord.Id Evergreen.V211.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V211.MembersAndOwner.MembersAndOwner
            (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V211.Id.Id Evergreen.V211.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V211.Id.Id Evergreen.V211.Id.CustomEmojiId)
    }
