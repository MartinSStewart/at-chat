module Evergreen.V22.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V22.ChannelName
import Evergreen.V22.Emoji
import Evergreen.V22.GuildName
import Evergreen.V22.Id
import Evergreen.V22.Image
import Evergreen.V22.Log
import Evergreen.V22.NonemptyDict
import Evergreen.V22.NonemptySet
import Evergreen.V22.RichText
import Evergreen.V22.SecretId
import Evergreen.V22.User
import List.Nonempty
import SeqDict


type alias UserTextMessageData =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V22.Id.Id Evergreen.V22.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V22.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V22.Emoji.Emoji (Evergreen.V22.NonemptySet.NonemptySet (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId))
    , editedAt : Maybe Effect.Time.Posix
    , repliedTo : Maybe Int
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Effect.Time.Posix (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) (SeqDict.SeqDict Evergreen.V22.Emoji.Emoji (Evergreen.V22.NonemptySet.NonemptySet (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId)))
    | DeletedMessage


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V22.Id.Id Evergreen.V22.Id.UserId
    }


type alias LastTypedAt =
    { time : Effect.Time.Posix
    , messageIndex : Maybe Int
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V22.Id.Id Evergreen.V22.Id.UserId
    , name : Evergreen.V22.ChannelName.ChannelName
    , messages : Array.Array Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) LastTypedAt
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V22.Id.Id Evergreen.V22.Id.UserId
    , name : Evergreen.V22.GuildName.GuildName
    , icon : Maybe Evergreen.V22.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V22.Id.Id Evergreen.V22.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V22.SecretId.SecretId Evergreen.V22.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V22.Id.Id Evergreen.V22.Id.UserId
            }
    , announcementChannel : Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V22.NonemptyDict.NonemptyDict (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) Evergreen.V22.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) Effect.Time.Posix
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V22.Id.Id Evergreen.V22.Id.UserId
    , user : Evergreen.V22.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) Evergreen.V22.User.FrontendUser
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) FrontendGuild
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V22.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V22.Id.Id Evergreen.V22.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V22.Id.Id Evergreen.V22.Id.UserId
    , name : Evergreen.V22.ChannelName.ChannelName
    , messages : Array.Array Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) LastTypedAt
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V22.Id.Id Evergreen.V22.Id.UserId
    , name : Evergreen.V22.GuildName.GuildName
    , icon : Maybe Evergreen.V22.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V22.Id.Id Evergreen.V22.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V22.SecretId.SecretId Evergreen.V22.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V22.Id.Id Evergreen.V22.Id.UserId
            }
    , announcementChannel : Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId
    }
