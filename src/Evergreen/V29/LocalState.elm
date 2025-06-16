module Evergreen.V29.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V29.ChannelName
import Evergreen.V29.Emoji
import Evergreen.V29.GuildName
import Evergreen.V29.Id
import Evergreen.V29.Image
import Evergreen.V29.Log
import Evergreen.V29.NonemptyDict
import Evergreen.V29.NonemptySet
import Evergreen.V29.RichText
import Evergreen.V29.SecretId
import Evergreen.V29.User
import List.Nonempty
import SeqDict


type alias UserTextMessageData =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V29.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V29.Emoji.Emoji (Evergreen.V29.NonemptySet.NonemptySet (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId))
    , editedAt : Maybe Effect.Time.Posix
    , repliedTo : Maybe Int
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Effect.Time.Posix (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) (SeqDict.SeqDict Evergreen.V29.Emoji.Emoji (Evergreen.V29.NonemptySet.NonemptySet (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)))
    | DeletedMessage


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    }


type alias LastTypedAt =
    { time : Effect.Time.Posix
    , messageIndex : Maybe Int
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    , name : Evergreen.V29.ChannelName.ChannelName
    , messages : Array.Array Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) LastTypedAt
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    , name : Evergreen.V29.GuildName.GuildName
    , icon : Maybe Evergreen.V29.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V29.SecretId.SecretId Evergreen.V29.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
            }
    , announcementChannel : Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V29.NonemptyDict.NonemptyDict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Effect.Time.Posix
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    , user : Evergreen.V29.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.User.FrontendUser
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) FrontendGuild
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V29.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    , name : Evergreen.V29.ChannelName.ChannelName
    , messages : Array.Array Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) LastTypedAt
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    , name : Evergreen.V29.GuildName.GuildName
    , icon : Maybe Evergreen.V29.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V29.SecretId.SecretId Evergreen.V29.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
            }
    , announcementChannel : Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId
    }
