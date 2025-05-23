module Evergreen.V7.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V7.ChannelName
import Evergreen.V7.Emoji
import Evergreen.V7.GuildName
import Evergreen.V7.Id
import Evergreen.V7.Image
import Evergreen.V7.Log
import Evergreen.V7.NonemptyDict
import Evergreen.V7.NonemptySet
import Evergreen.V7.RichText
import Evergreen.V7.SecretId
import Evergreen.V7.User
import List.Nonempty
import SeqDict


type alias UserTextMessageData =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V7.Id.Id Evergreen.V7.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V7.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V7.Emoji.Emoji (Evergreen.V7.NonemptySet.NonemptySet (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId))
    , editedAt : Maybe Effect.Time.Posix
    , repliedTo : Maybe Int
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Effect.Time.Posix (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId) (SeqDict.SeqDict Evergreen.V7.Emoji.Emoji (Evergreen.V7.NonemptySet.NonemptySet (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId)))
    | DeletedMessage


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V7.Id.Id Evergreen.V7.Id.UserId
    }


type alias LastTypedAt =
    { time : Effect.Time.Posix
    , messageIndex : Maybe Int
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V7.Id.Id Evergreen.V7.Id.UserId
    , name : Evergreen.V7.ChannelName.ChannelName
    , messages : Array.Array Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId) LastTypedAt
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V7.Id.Id Evergreen.V7.Id.UserId
    , name : Evergreen.V7.GuildName.GuildName
    , icon : Maybe Evergreen.V7.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V7.Id.Id Evergreen.V7.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V7.SecretId.SecretId Evergreen.V7.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V7.Id.Id Evergreen.V7.Id.UserId
            }
    , announcementChannel : Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V7.NonemptyDict.NonemptyDict (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId) Evergreen.V7.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId) Effect.Time.Posix
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V7.Id.Id Evergreen.V7.Id.UserId
    , user : Evergreen.V7.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId) Evergreen.V7.User.FrontendUser
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) FrontendGuild
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V7.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelArchived Archived
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V7.Id.Id Evergreen.V7.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V7.Id.Id Evergreen.V7.Id.UserId
    , name : Evergreen.V7.ChannelName.ChannelName
    , messages : Array.Array Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId) LastTypedAt
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V7.Id.Id Evergreen.V7.Id.UserId
    , name : Evergreen.V7.GuildName.GuildName
    , icon : Maybe Evergreen.V7.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V7.Id.Id Evergreen.V7.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V7.SecretId.SecretId Evergreen.V7.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V7.Id.Id Evergreen.V7.Id.UserId
            }
    , announcementChannel : Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId
    }
