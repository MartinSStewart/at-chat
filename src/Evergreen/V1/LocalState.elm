module Evergreen.V1.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V1.ChannelName
import Evergreen.V1.Emoji
import Evergreen.V1.GuildName
import Evergreen.V1.Id
import Evergreen.V1.Image
import Evergreen.V1.Log
import Evergreen.V1.NonemptyDict
import Evergreen.V1.NonemptySet
import Evergreen.V1.RichText
import Evergreen.V1.SecretId
import Evergreen.V1.User
import List.Nonempty
import SeqDict


type alias UserTextMessageData =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V1.Id.Id Evergreen.V1.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V1.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V1.Emoji.Emoji (Evergreen.V1.NonemptySet.NonemptySet (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId))
    , editedAt : Maybe Effect.Time.Posix
    , repliedTo : Maybe Int
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Effect.Time.Posix (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId) (SeqDict.SeqDict Evergreen.V1.Emoji.Emoji (Evergreen.V1.NonemptySet.NonemptySet (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId)))
    | DeletedMessage


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V1.Id.Id Evergreen.V1.Id.UserId
    }


type alias LastTypedAt =
    { time : Effect.Time.Posix
    , messageIndex : Maybe Int
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V1.Id.Id Evergreen.V1.Id.UserId
    , name : Evergreen.V1.ChannelName.ChannelName
    , messages : Array.Array Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId) LastTypedAt
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V1.Id.Id Evergreen.V1.Id.UserId
    , name : Evergreen.V1.GuildName.GuildName
    , icon : Maybe Evergreen.V1.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V1.Id.Id Evergreen.V1.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V1.SecretId.SecretId Evergreen.V1.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V1.Id.Id Evergreen.V1.Id.UserId
            }
    , announcementChannel : Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V1.NonemptyDict.NonemptyDict (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId) Evergreen.V1.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId) Effect.Time.Posix
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalState =
    { userId : Evergreen.V1.Id.Id Evergreen.V1.Id.UserId
    , adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) FrontendGuild
    , joinGuildError : Maybe JoinGuildError
    , user : Evergreen.V1.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId) Evergreen.V1.User.FrontendUser
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V1.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelArchived Archived
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V1.Id.Id Evergreen.V1.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V1.Id.Id Evergreen.V1.Id.UserId
    , name : Evergreen.V1.ChannelName.ChannelName
    , messages : Array.Array Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId) LastTypedAt
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V1.Id.Id Evergreen.V1.Id.UserId
    , name : Evergreen.V1.GuildName.GuildName
    , icon : Maybe Evergreen.V1.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V1.Id.Id Evergreen.V1.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V1.SecretId.SecretId Evergreen.V1.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V1.Id.Id Evergreen.V1.Id.UserId
            }
    , announcementChannel : Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId
    }
