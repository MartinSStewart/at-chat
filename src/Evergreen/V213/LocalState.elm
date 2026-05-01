module Evergreen.V213.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V213.ChannelDescription
import Evergreen.V213.ChannelName
import Evergreen.V213.CustomEmoji
import Evergreen.V213.Discord
import Evergreen.V213.DiscordUserData
import Evergreen.V213.DmChannel
import Evergreen.V213.FileStatus
import Evergreen.V213.GuildName
import Evergreen.V213.Id
import Evergreen.V213.Log
import Evergreen.V213.MembersAndOwner
import Evergreen.V213.Message
import Evergreen.V213.NonemptyDict
import Evergreen.V213.OneToOne
import Evergreen.V213.Pagination
import Evergreen.V213.Postmark
import Evergreen.V213.SecretId
import Evergreen.V213.SessionIdHash
import Evergreen.V213.Slack
import Evergreen.V213.Sticker
import Evergreen.V213.TextEditor
import Evergreen.V213.Thread
import Evergreen.V213.ToBackendLog
import Evergreen.V213.User
import Evergreen.V213.UserAgent
import Evergreen.V213.UserSession
import Evergreen.V213.VisibleMessages
import Evergreen.V213.VoiceChat
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V213.NonemptyDict.NonemptyDict
            (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V213.Message.Message Evergreen.V213.Id.ChannelMessageId (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V213.Discord.PartialUser
        , icon : Maybe Evergreen.V213.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V213.Discord.User
        , linkedTo : Evergreen.V213.Id.Id Evergreen.V213.Id.UserId
        , icon : Maybe Evergreen.V213.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V213.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V213.Discord.User
        , linkedTo : Evergreen.V213.Id.Id Evergreen.V213.Id.UserId
        , icon : Maybe Evergreen.V213.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V213.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V213.Message.Message Evergreen.V213.Id.ChannelMessageId (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V213.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V213.MembersAndOwner.MembersAndOwner
            (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V213.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V213.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V213.Id.Id Evergreen.V213.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V213.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V213.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : Maybe Evergreen.V213.VoiceChat.RoomId
    }


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V213.Id.Id Evergreen.V213.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V213.Id.Id Evergreen.V213.Id.UserId
    , name : Evergreen.V213.ChannelName.ChannelName
    , description : Evergreen.V213.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V213.Message.MessageState Evergreen.V213.Id.ChannelMessageId (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId))
    , visibleMessages : Evergreen.V213.VisibleMessages.VisibleMessages Evergreen.V213.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) (Evergreen.V213.Thread.LastTypedAt Evergreen.V213.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) Evergreen.V213.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V213.Id.Id Evergreen.V213.Id.UserId
    , name : Evergreen.V213.GuildName.GuildName
    , icon : Maybe Evergreen.V213.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V213.MembersAndOwner.MembersAndOwner
            (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V213.SecretId.SecretId Evergreen.V213.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V213.Id.Id Evergreen.V213.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V213.ChannelName.ChannelName
    , description : Evergreen.V213.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V213.Message.MessageState Evergreen.V213.Id.ChannelMessageId (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId))
    , visibleMessages : Evergreen.V213.VisibleMessages.VisibleMessages Evergreen.V213.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (Evergreen.V213.Thread.LastTypedAt Evergreen.V213.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) Evergreen.V213.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V213.GuildName.GuildName
    , icon : Maybe Evergreen.V213.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V213.MembersAndOwner.MembersAndOwner
            (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V213.Id.Id Evergreen.V213.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V213.Id.Id Evergreen.V213.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V213.NonemptyDict.NonemptyDict (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) Evergreen.V213.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V213.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V213.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V213.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V213.SessionIdHash.SessionIdHash (Evergreen.V213.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V213.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V213.UserSession.UserSession
    , user : Evergreen.V213.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) Evergreen.V213.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) Evergreen.V213.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) Evergreen.V213.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V213.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.StickerId) Evergreen.V213.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.CustomEmojiId) Evergreen.V213.CustomEmoji.CustomEmojiData
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) Evergreen.V213.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId) Evergreen.V213.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V213.SessionIdHash.SessionIdHash Evergreen.V213.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V213.TextEditor.LocalState
    , calls : Evergreen.V213.VoiceChat.Model
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V213.Id.Id Evergreen.V213.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V213.Id.Id Evergreen.V213.Id.UserId
    , name : Evergreen.V213.ChannelName.ChannelName
    , description : Evergreen.V213.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V213.Message.Message Evergreen.V213.Id.ChannelMessageId (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) (Evergreen.V213.Thread.LastTypedAt Evergreen.V213.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) Evergreen.V213.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V213.Id.Id Evergreen.V213.Id.UserId
    , name : Evergreen.V213.GuildName.GuildName
    , icon : Maybe Evergreen.V213.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V213.MembersAndOwner.MembersAndOwner
            (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V213.SecretId.SecretId Evergreen.V213.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V213.Id.Id Evergreen.V213.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V213.ChannelName.ChannelName
    , description : Evergreen.V213.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V213.Message.Message Evergreen.V213.Id.ChannelMessageId (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (Evergreen.V213.Thread.LastTypedAt Evergreen.V213.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V213.OneToOne.OneToOne (Evergreen.V213.Discord.Id Evergreen.V213.Discord.MessageId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) Evergreen.V213.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V213.GuildName.GuildName
    , icon : Maybe Evergreen.V213.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V213.MembersAndOwner.MembersAndOwner
            (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V213.Id.Id Evergreen.V213.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V213.Id.Id Evergreen.V213.Id.CustomEmojiId)
    }
