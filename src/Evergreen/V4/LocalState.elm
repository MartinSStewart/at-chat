module Evergreen.V4.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V4.ChannelName
import Evergreen.V4.Emoji
import Evergreen.V4.GuildName
import Evergreen.V4.Id
import Evergreen.V4.Image
import Evergreen.V4.Log
import Evergreen.V4.NonemptyDict
import Evergreen.V4.NonemptySet
import Evergreen.V4.RichText
import Evergreen.V4.SecretId
import Evergreen.V4.User
import List.Nonempty
import SeqDict


type alias UserTextMessageData =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V4.Id.Id Evergreen.V4.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V4.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V4.Emoji.Emoji (Evergreen.V4.NonemptySet.NonemptySet (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId))
    , editedAt : Maybe Effect.Time.Posix
    , repliedTo : Maybe Int
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Effect.Time.Posix (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId) (SeqDict.SeqDict Evergreen.V4.Emoji.Emoji (Evergreen.V4.NonemptySet.NonemptySet (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId)))
    | DeletedMessage


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V4.Id.Id Evergreen.V4.Id.UserId
    }


type alias LastTypedAt =
    { time : Effect.Time.Posix
    , messageIndex : Maybe Int
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V4.Id.Id Evergreen.V4.Id.UserId
    , name : Evergreen.V4.ChannelName.ChannelName
    , messages : Array.Array Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId) LastTypedAt
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V4.Id.Id Evergreen.V4.Id.UserId
    , name : Evergreen.V4.GuildName.GuildName
    , icon : Maybe Evergreen.V4.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V4.Id.Id Evergreen.V4.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V4.SecretId.SecretId Evergreen.V4.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V4.Id.Id Evergreen.V4.Id.UserId
            }
    , announcementChannel : Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V4.NonemptyDict.NonemptyDict (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId) Evergreen.V4.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId) Effect.Time.Posix
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V4.Id.Id Evergreen.V4.Id.UserId
    , user : Evergreen.V4.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId) Evergreen.V4.User.FrontendUser
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) FrontendGuild
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V4.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelArchived Archived
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V4.Id.Id Evergreen.V4.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V4.Id.Id Evergreen.V4.Id.UserId
    , name : Evergreen.V4.ChannelName.ChannelName
    , messages : Array.Array Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId) LastTypedAt
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V4.Id.Id Evergreen.V4.Id.UserId
    , name : Evergreen.V4.GuildName.GuildName
    , icon : Maybe Evergreen.V4.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V4.Id.Id Evergreen.V4.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V4.SecretId.SecretId Evergreen.V4.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V4.Id.Id Evergreen.V4.Id.UserId
            }
    , announcementChannel : Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId
    }
