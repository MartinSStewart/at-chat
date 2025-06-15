module Evergreen.V25.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V25.ChannelName
import Evergreen.V25.Emoji
import Evergreen.V25.GuildName
import Evergreen.V25.Id
import Evergreen.V25.Image
import Evergreen.V25.Log
import Evergreen.V25.NonemptyDict
import Evergreen.V25.NonemptySet
import Evergreen.V25.RichText
import Evergreen.V25.SecretId
import Evergreen.V25.User
import List.Nonempty
import SeqDict


type alias UserTextMessageData =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V25.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V25.Emoji.Emoji (Evergreen.V25.NonemptySet.NonemptySet (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId))
    , editedAt : Maybe Effect.Time.Posix
    , repliedTo : Maybe Int
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Effect.Time.Posix (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) (SeqDict.SeqDict Evergreen.V25.Emoji.Emoji (Evergreen.V25.NonemptySet.NonemptySet (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId)))
    | DeletedMessage


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
    }


type alias LastTypedAt =
    { time : Effect.Time.Posix
    , messageIndex : Maybe Int
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
    , name : Evergreen.V25.ChannelName.ChannelName
    , messages : Array.Array Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) LastTypedAt
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
    , name : Evergreen.V25.GuildName.GuildName
    , icon : Maybe Evergreen.V25.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V25.SecretId.SecretId Evergreen.V25.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
            }
    , announcementChannel : Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V25.NonemptyDict.NonemptyDict (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) Evergreen.V25.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) Effect.Time.Posix
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
    , user : Evergreen.V25.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) Evergreen.V25.User.FrontendUser
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) FrontendGuild
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V25.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
    , name : Evergreen.V25.ChannelName.ChannelName
    , messages : Array.Array Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) LastTypedAt
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
    , name : Evergreen.V25.GuildName.GuildName
    , icon : Maybe Evergreen.V25.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V25.SecretId.SecretId Evergreen.V25.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
            }
    , announcementChannel : Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId
    }
