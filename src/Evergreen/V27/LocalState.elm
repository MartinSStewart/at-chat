module Evergreen.V27.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V27.ChannelName
import Evergreen.V27.Emoji
import Evergreen.V27.GuildName
import Evergreen.V27.Id
import Evergreen.V27.Image
import Evergreen.V27.Log
import Evergreen.V27.NonemptyDict
import Evergreen.V27.NonemptySet
import Evergreen.V27.RichText
import Evergreen.V27.SecretId
import Evergreen.V27.User
import List.Nonempty
import SeqDict


type alias UserTextMessageData =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V27.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V27.Emoji.Emoji (Evergreen.V27.NonemptySet.NonemptySet (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId))
    , editedAt : Maybe Effect.Time.Posix
    , repliedTo : Maybe Int
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Effect.Time.Posix (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) (SeqDict.SeqDict Evergreen.V27.Emoji.Emoji (Evergreen.V27.NonemptySet.NonemptySet (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)))
    | DeletedMessage


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
    }


type alias LastTypedAt =
    { time : Effect.Time.Posix
    , messageIndex : Maybe Int
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
    , name : Evergreen.V27.ChannelName.ChannelName
    , messages : Array.Array Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) LastTypedAt
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
    , name : Evergreen.V27.GuildName.GuildName
    , icon : Maybe Evergreen.V27.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V27.SecretId.SecretId Evergreen.V27.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
            }
    , announcementChannel : Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V27.NonemptyDict.NonemptyDict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Effect.Time.Posix
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
    , user : Evergreen.V27.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.User.FrontendUser
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) FrontendGuild
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V27.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
    , name : Evergreen.V27.ChannelName.ChannelName
    , messages : Array.Array Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) LastTypedAt
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
    , name : Evergreen.V27.GuildName.GuildName
    , icon : Maybe Evergreen.V27.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V27.SecretId.SecretId Evergreen.V27.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
            }
    , announcementChannel : Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId
    }
