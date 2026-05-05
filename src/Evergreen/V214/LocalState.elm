module Evergreen.V214.LocalState exposing (..)

import Array
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V214.ChannelDescription
import Evergreen.V214.ChannelName
import Evergreen.V214.CustomEmoji
import Evergreen.V214.Discord
import Evergreen.V214.DiscordUserData
import Evergreen.V214.DmChannel
import Evergreen.V214.FileStatus
import Evergreen.V214.GuildName
import Evergreen.V214.Id
import Evergreen.V214.Log
import Evergreen.V214.MembersAndOwner
import Evergreen.V214.Message
import Evergreen.V214.NonemptyDict
import Evergreen.V214.OneToOne
import Evergreen.V214.Pagination
import Evergreen.V214.Postmark
import Evergreen.V214.SecretId
import Evergreen.V214.SessionIdHash
import Evergreen.V214.Slack
import Evergreen.V214.Sticker
import Evergreen.V214.TextEditor
import Evergreen.V214.Thread
import Evergreen.V214.ToBackendLog
import Evergreen.V214.User
import Evergreen.V214.UserAgent
import Evergreen.V214.UserSession
import Evergreen.V214.VisibleMessages
import Evergreen.V214.VoiceChat
import SeqDict
import SeqSet


type PrivateVapidKey
    = PrivateVapidKey String


type alias AdminData_DiscordDmChannel =
    { members :
        Evergreen.V214.NonemptyDict.NonemptyDict
            (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId)
            { messagesSent : Int
            }
    , messageCount : Int
    , firstMessage : Maybe (Evergreen.V214.Message.Message Evergreen.V214.Id.ChannelMessageId (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId))
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin
        { user : Evergreen.V214.Discord.PartialUser
        , icon : Maybe Evergreen.V214.FileStatus.FileHash
        }
    | FullData_ForAdmin
        { user : Evergreen.V214.Discord.User
        , linkedTo : Evergreen.V214.Id.Id Evergreen.V214.Id.UserId
        , icon : Maybe Evergreen.V214.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        , isLoadingData : Evergreen.V214.DiscordUserData.DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Evergreen.V214.Discord.User
        , linkedTo : Evergreen.V214.Id.Id Evergreen.V214.Id.UserId
        , icon : Maybe Evergreen.V214.FileStatus.FileHash
        , linkedAt : Effect.Time.Posix
        }


type alias AdminData_DiscordChannel =
    { name : Evergreen.V214.ChannelName.ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Evergreen.V214.Message.Message Evergreen.V214.Id.ChannelMessageId (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId))
    }


type alias AdminData_DiscordGuild =
    { name : Evergreen.V214.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V214.Discord.Id Evergreen.V214.Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        Evergreen.V214.MembersAndOwner.MembersAndOwner
            (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    }


type alias AdminData_GuildChannel =
    { name : Evergreen.V214.ChannelName.ChannelName
    , messageCount : Int
    }


type alias AdminData_Guild =
    { name : Evergreen.V214.GuildName.GuildName
    , channels : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Evergreen.V214.Id.Id Evergreen.V214.Id.UserId
    }


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Evergreen.V214.Discord.HttpError
    | LoadingDiscordChannelAttachments Effect.Time.Posix messages


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Effect.Time.Posix (Evergreen.V214.Discord.Id Evergreen.V214.Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V214.Discord.Id Evergreen.V214.Discord.GuildId) (Evergreen.V214.Discord.Id Evergreen.V214.Discord.ChannelId) (LoadingDiscordChannelStep messages)


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V214.Log.Log
    , isHidden : Bool
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : Maybe Evergreen.V214.VoiceChat.RoomId
    }


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V214.Id.Id Evergreen.V214.Id.UserId
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V214.Id.Id Evergreen.V214.Id.UserId
    , name : Evergreen.V214.ChannelName.ChannelName
    , description : Evergreen.V214.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V214.Message.MessageState Evergreen.V214.Id.ChannelMessageId (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId))
    , visibleMessages : Evergreen.V214.VisibleMessages.VisibleMessages Evergreen.V214.Id.ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId) (Evergreen.V214.Thread.LastTypedAt Evergreen.V214.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelMessageId) Evergreen.V214.Thread.FrontendThread
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V214.Id.Id Evergreen.V214.Id.UserId
    , name : Evergreen.V214.GuildName.GuildName
    , icon : Maybe Evergreen.V214.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelId) FrontendChannel
    , membersAndOwner :
        Evergreen.V214.MembersAndOwner.MembersAndOwner
            (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V214.SecretId.SecretId Evergreen.V214.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V214.Id.Id Evergreen.V214.Id.UserId
            }
    }


type alias DiscordFrontendChannel =
    { name : Evergreen.V214.ChannelName.ChannelName
    , description : Evergreen.V214.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V214.Message.MessageState Evergreen.V214.Id.ChannelMessageId (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId))
    , visibleMessages : Evergreen.V214.VisibleMessages.VisibleMessages Evergreen.V214.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId) (Evergreen.V214.Thread.LastTypedAt Evergreen.V214.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelMessageId) Evergreen.V214.Thread.DiscordFrontendThread
    }


type alias DiscordFrontendGuild =
    { name : Evergreen.V214.GuildName.GuildName
    , icon : Maybe Evergreen.V214.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V214.Discord.Id Evergreen.V214.Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner :
        Evergreen.V214.MembersAndOwner.MembersAndOwner
            (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V214.Id.Id Evergreen.V214.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V214.Id.Id Evergreen.V214.Id.CustomEmojiId)
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Effect.Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Effect.Http.Error


type alias AdminData =
    { users : Evergreen.V214.NonemptyDict.NonemptyDict (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId) Evergreen.V214.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId) Effect.Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V214.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Evergreen.V214.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V214.Discord.Id Evergreen.V214.Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V214.Discord.Id Evergreen.V214.Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V214.Pagination.Pagination LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V214.SessionIdHash.SessionIdHash (Evergreen.V214.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V214.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LocalUser =
    { session : Evergreen.V214.UserSession.UserSession
    , user : Evergreen.V214.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId) Evergreen.V214.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId) Evergreen.V214.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId) Evergreen.V214.User.DiscordFrontendCurrentUser
    , timezone : Effect.Time.Zone
    , userAgent : Evergreen.V214.UserAgent.UserAgent
    , stickers : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.StickerId) Evergreen.V214.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.CustomEmojiId) Evergreen.V214.CustomEmoji.CustomEmojiData
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.GuildId) FrontendGuild
    , discordGuilds : SeqDict.SeqDict (Evergreen.V214.Discord.Id Evergreen.V214.Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId) Evergreen.V214.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V214.Discord.Id Evergreen.V214.Discord.PrivateChannelId) Evergreen.V214.DmChannel.DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict.SeqDict Evergreen.V214.SessionIdHash.SessionIdHash Evergreen.V214.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V214.TextEditor.LocalState
    , calls : Evergreen.V214.VoiceChat.Local
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V214.Id.Id Evergreen.V214.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V214.Id.Id Evergreen.V214.Id.UserId
    , name : Evergreen.V214.ChannelName.ChannelName
    , description : Evergreen.V214.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V214.Message.Message Evergreen.V214.Id.ChannelMessageId (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId) (Evergreen.V214.Thread.LastTypedAt Evergreen.V214.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelMessageId) Evergreen.V214.Thread.BackendThread
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V214.Id.Id Evergreen.V214.Id.UserId
    , name : Evergreen.V214.GuildName.GuildName
    , icon : Maybe Evergreen.V214.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelId) BackendChannel
    , membersAndOwner :
        Evergreen.V214.MembersAndOwner.MembersAndOwner
            (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , invites :
        SeqDict.SeqDict
            (Evergreen.V214.SecretId.SecretId Evergreen.V214.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V214.Id.Id Evergreen.V214.Id.UserId
            }
    }


type alias DiscordBackendChannel =
    { name : Evergreen.V214.ChannelName.ChannelName
    , description : Evergreen.V214.ChannelDescription.ChannelDescription
    , messages : Array.Array (Evergreen.V214.Message.Message Evergreen.V214.Id.ChannelMessageId (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId) (Evergreen.V214.Thread.LastTypedAt Evergreen.V214.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V214.OneToOne.OneToOne (Evergreen.V214.Discord.Id Evergreen.V214.Discord.MessageId) (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelMessageId) Evergreen.V214.Thread.DiscordBackendThread
    }


type alias DiscordBackendGuild =
    { name : Evergreen.V214.GuildName.GuildName
    , icon : Maybe Evergreen.V214.FileStatus.FileHash
    , channels : SeqDict.SeqDict (Evergreen.V214.Discord.Id Evergreen.V214.Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner :
        Evergreen.V214.MembersAndOwner.MembersAndOwner
            (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
    , stickers : SeqSet.SeqSet (Evergreen.V214.Id.Id Evergreen.V214.Id.StickerId)
    , customEmojis : SeqSet.SeqSet (Evergreen.V214.Id.Id Evergreen.V214.Id.CustomEmojiId)
    }
