module Evergreen.V24.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V24.ChannelName
import Evergreen.V24.Emoji
import Evergreen.V24.GuildName
import Evergreen.V24.Id
import Evergreen.V24.Image
import Evergreen.V24.Log
import Evergreen.V24.NonemptyDict
import Evergreen.V24.NonemptySet
import Evergreen.V24.RichText
import Evergreen.V24.SecretId
import Evergreen.V24.User
import List.Nonempty
import SeqDict


type alias UserTextMessageData =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V24.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V24.Emoji.Emoji (Evergreen.V24.NonemptySet.NonemptySet (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId))
    , editedAt : Maybe Effect.Time.Posix
    , repliedTo : Maybe Int
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Effect.Time.Posix (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) (SeqDict.SeqDict Evergreen.V24.Emoji.Emoji (Evergreen.V24.NonemptySet.NonemptySet (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId)))
    | DeletedMessage


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
    }


type alias LastTypedAt =
    { time : Effect.Time.Posix
    , messageIndex : Maybe Int
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
    , name : Evergreen.V24.ChannelName.ChannelName
    , messages : Array.Array Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) LastTypedAt
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
    , name : Evergreen.V24.GuildName.GuildName
    , icon : Maybe Evergreen.V24.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V24.SecretId.SecretId Evergreen.V24.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
            }
    , announcementChannel : Evergreen.V24.Id.Id Evergreen.V24.Id.ChannelId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V24.NonemptyDict.NonemptyDict (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) Evergreen.V24.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) Effect.Time.Posix
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
    , user : Evergreen.V24.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) Evergreen.V24.User.FrontendUser
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId) FrontendGuild
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V24.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
    , name : Evergreen.V24.ChannelName.ChannelName
    , messages : Array.Array Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) LastTypedAt
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
    , name : Evergreen.V24.GuildName.GuildName
    , icon : Maybe Evergreen.V24.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V24.SecretId.SecretId Evergreen.V24.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
            }
    , announcementChannel : Evergreen.V24.Id.Id Evergreen.V24.Id.ChannelId
    }
