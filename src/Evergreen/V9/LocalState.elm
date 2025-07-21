module Evergreen.V9.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V9.ChannelName
import Evergreen.V9.Discord.Id
import Evergreen.V9.Emoji
import Evergreen.V9.GuildName
import Evergreen.V9.Id
import Evergreen.V9.Image
import Evergreen.V9.Log
import Evergreen.V9.NonemptyDict
import Evergreen.V9.NonemptySet
import Evergreen.V9.OneToOne
import Evergreen.V9.RichText
import Evergreen.V9.SecretId
import Evergreen.V9.User
import List.Nonempty
import SeqDict


type IsEnabled
    = IsEnabled
    | IsDisabled


type alias UserTextMessageData =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V9.Id.Id Evergreen.V9.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V9.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V9.Emoji.Emoji (Evergreen.V9.NonemptySet.NonemptySet (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId))
    , editedAt : Maybe Effect.Time.Posix
    , repliedTo : Maybe Int
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Effect.Time.Posix (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) (SeqDict.SeqDict Evergreen.V9.Emoji.Emoji (Evergreen.V9.NonemptySet.NonemptySet (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId)))
    | DeletedMessage


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V9.Id.Id Evergreen.V9.Id.UserId
    }


type alias LastTypedAt =
    { time : Effect.Time.Posix
    , messageIndex : Maybe Int
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V9.Id.Id Evergreen.V9.Id.UserId
    , name : Evergreen.V9.ChannelName.ChannelName
    , messages : Array.Array Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) LastTypedAt
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V9.Id.Id Evergreen.V9.Id.UserId
    , name : Evergreen.V9.GuildName.GuildName
    , icon : Maybe Evergreen.V9.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V9.Id.Id Evergreen.V9.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V9.SecretId.SecretId Evergreen.V9.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V9.Id.Id Evergreen.V9.Id.UserId
            }
    , announcementChannel : Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V9.NonemptyDict.NonemptyDict (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) Evergreen.V9.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) Effect.Time.Posix
    , websocketEnabled : IsEnabled
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V9.Id.Id Evergreen.V9.Id.UserId
    , user : Evergreen.V9.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) Evergreen.V9.User.FrontendUser
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) FrontendGuild
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V9.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V9.Id.Id Evergreen.V9.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V9.Id.Id Evergreen.V9.Id.UserId
    , name : Evergreen.V9.ChannelName.ChannelName
    , messages : Array.Array Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) LastTypedAt
    , linkedId : Maybe (Evergreen.V9.Discord.Id.Id Evergreen.V9.Discord.Id.ChannelId)
    , linkedMessageIds : Evergreen.V9.OneToOne.OneToOne (Evergreen.V9.Discord.Id.Id Evergreen.V9.Discord.Id.MessageId) Int
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V9.Id.Id Evergreen.V9.Id.UserId
    , name : Evergreen.V9.GuildName.GuildName
    , icon : Maybe Evergreen.V9.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V9.Id.Id Evergreen.V9.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V9.SecretId.SecretId Evergreen.V9.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V9.Id.Id Evergreen.V9.Id.UserId
            }
    , announcementChannel : Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId
    }
