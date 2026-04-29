module Evergreen.V210.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V210.ChannelDescription
import Evergreen.V210.ChannelName
import Evergreen.V210.CustomEmoji
import Evergreen.V210.Discord
import Evergreen.V210.DiscordUserData
import Evergreen.V210.DmChannel
import Evergreen.V210.FileStatus
import Evergreen.V210.GuildName
import Evergreen.V210.Id
import Evergreen.V210.Log
import Evergreen.V210.MembersAndOwner
import Evergreen.V210.Message
import Evergreen.V210.NonemptyDict
import Evergreen.V210.OneToOne
import Evergreen.V210.Pagination
import Evergreen.V210.Postmark
import Evergreen.V210.SecretId
import Evergreen.V210.SessionIdHash
import Evergreen.V210.Slack
import Evergreen.V210.Sticker
import Evergreen.V210.TextEditor
import Evergreen.V210.Thread
import Evergreen.V210.ToBackendLog
import Evergreen.V210.User
import Evergreen.V210.UserAgent
import Evergreen.V210.UserSession
import Evergreen.V210.VisibleMessages
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V210.NonemptyDict.NonemptyDict
            (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V210.Message.Message Evergreen.V210.Id.ChannelMessageId (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V210.Discord.PartialUser
        , icon : Maybe Evergreen.V210.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V210.Discord.User
        , linkedTo : Evergreen.V210.Id.Id Evergreen.V210.Id.UserId
        , icon : Maybe Evergreen.V210.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V210.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V210.Discord.User
        , linkedTo : Evergreen.V210.Id.Id Evergreen.V210.Id.UserId
        , icon : Maybe Evergreen.V210.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V210.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V210.Message.Message Evergreen.V210.Id.ChannelMessageId (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V210.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V210.MembersAndOwner.MembersAndOwner
            (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V210.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V210.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V210.Id.Id Evergreen.V210.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V210.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V210.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V210.Id.Id Evergreen.V210.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V210.Id.Id Evergreen.V210.Id.UserId
    , name : Evergreen.V210.ChannelName.ChannelName
    , description : Evergreen.V210.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V210.Message.MessageState Evergreen.V210.Id.ChannelMessageId (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId))
    , visibleMessages : Evergreen.V210.VisibleMessages.VisibleMessages Evergreen.V210.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) (Evergreen.V210.Thread.LastTypedAt Evergreen.V210.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) Evergreen.V210.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V210.Id.Id Evergreen.V210.Id.UserId
    , name : Evergreen.V210.GuildName.GuildName
    , icon : Maybe Evergreen.V210.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V210.MembersAndOwner.MembersAndOwner
            (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V210.SecretId.SecretId Evergreen.V210.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V210.Id.Id Evergreen.V210.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V210.ChannelName.ChannelName
    , description : Evergreen.V210.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V210.Message.MessageState Evergreen.V210.Id.ChannelMessageId (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId))
    , visibleMessages : Evergreen.V210.VisibleMessages.VisibleMessages Evergreen.V210.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Evergreen.V210.Thread.LastTypedAt Evergreen.V210.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) Evergreen.V210.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V210.GuildName.GuildName
    , icon : Maybe Evergreen.V210.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V210.MembersAndOwner.MembersAndOwner
            (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V210.Id.Id Evergreen.V210.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V210.Id.Id Evergreen.V210.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V210.NonemptyDict.NonemptyDict (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) Evergreen.V210.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V210.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V210.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V210.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V210.SessionIdHash.SessionIdHash (Evergreen.V210.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V210.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V210.UserSession.UserSession
    , user : Evergreen.V210.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) Evergreen.V210.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) Evergreen.V210.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) Evergreen.V210.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V210.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.StickerId) Evergreen.V210.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.CustomEmojiId) Evergreen.V210.CustomEmoji.CustomEmojiData
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) Evergreen.V210.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId) Evergreen.V210.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V210.SessionIdHash.SessionIdHash Evergreen.V210.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V210.TextEditor.LocalState
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V210.Id.Id Evergreen.V210.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V210.Id.Id Evergreen.V210.Id.UserId
    , name : Evergreen.V210.ChannelName.ChannelName
    , description : Evergreen.V210.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V210.Message.Message Evergreen.V210.Id.ChannelMessageId (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) (Evergreen.V210.Thread.LastTypedAt Evergreen.V210.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) Evergreen.V210.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V210.Id.Id Evergreen.V210.Id.UserId
    , name : Evergreen.V210.GuildName.GuildName
    , icon : Maybe Evergreen.V210.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V210.MembersAndOwner.MembersAndOwner
            (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V210.SecretId.SecretId Evergreen.V210.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V210.Id.Id Evergreen.V210.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V210.ChannelName.ChannelName
    , description : Evergreen.V210.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V210.Message.Message Evergreen.V210.Id.ChannelMessageId (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Evergreen.V210.Thread.LastTypedAt Evergreen.V210.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V210.OneToOne.OneToOne (Evergreen.V210.Discord.Id Evergreen.V210.Discord.MessageId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) Evergreen.V210.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V210.GuildName.GuildName
    , icon : Maybe Evergreen.V210.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V210.MembersAndOwner.MembersAndOwner
            (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V210.Id.Id Evergreen.V210.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V210.Id.Id Evergreen.V210.Id.CustomEmojiId)
    }
