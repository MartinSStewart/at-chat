module Evergreen.V32.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V32.ChannelName
import Evergreen.V32.Emoji
import Evergreen.V32.GuildName
import Evergreen.V32.Id
import Evergreen.V32.Image
import Evergreen.V32.Log
import Evergreen.V32.NonemptyDict
import Evergreen.V32.NonemptySet
import Evergreen.V32.RichText
import Evergreen.V32.SecretId
import Evergreen.V32.User
import List.Nonempty
import SeqDict


type alias UserTextMessageData =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V32.Id.Id Evergreen.V32.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V32.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V32.Emoji.Emoji (Evergreen.V32.NonemptySet.NonemptySet (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId))
    , editedAt : Maybe Effect.Time.Posix
    , repliedTo : Maybe Int
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Effect.Time.Posix (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId) (SeqDict.SeqDict Evergreen.V32.Emoji.Emoji (Evergreen.V32.NonemptySet.NonemptySet (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId)))
    | DeletedMessage


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V32.Id.Id Evergreen.V32.Id.UserId
    }


type alias LastTypedAt =
    { time : Effect.Time.Posix
    , messageIndex : Maybe Int
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V32.Id.Id Evergreen.V32.Id.UserId
    , name : Evergreen.V32.ChannelName.ChannelName
    , messages : Array.Array Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId) LastTypedAt
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V32.Id.Id Evergreen.V32.Id.UserId
    , name : Evergreen.V32.GuildName.GuildName
    , icon : Maybe Evergreen.V32.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V32.Id.Id Evergreen.V32.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V32.SecretId.SecretId Evergreen.V32.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V32.Id.Id Evergreen.V32.Id.UserId
            }
    , announcementChannel : Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V32.NonemptyDict.NonemptyDict (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId) Evergreen.V32.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId) Effect.Time.Posix
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V32.Id.Id Evergreen.V32.Id.UserId
    , user : Evergreen.V32.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId) Evergreen.V32.User.FrontendUser
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) FrontendGuild
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V32.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V32.Id.Id Evergreen.V32.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V32.Id.Id Evergreen.V32.Id.UserId
    , name : Evergreen.V32.ChannelName.ChannelName
    , messages : Array.Array Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId) LastTypedAt
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V32.Id.Id Evergreen.V32.Id.UserId
    , name : Evergreen.V32.GuildName.GuildName
    , icon : Maybe Evergreen.V32.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V32.Id.Id Evergreen.V32.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V32.SecretId.SecretId Evergreen.V32.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V32.Id.Id Evergreen.V32.Id.UserId
            }
    , announcementChannel : Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId
    }
