module Evergreen.V5.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V5.ChannelName
import Evergreen.V5.Emoji
import Evergreen.V5.GuildName
import Evergreen.V5.Id
import Evergreen.V5.Image
import Evergreen.V5.Log
import Evergreen.V5.NonemptyDict
import Evergreen.V5.NonemptySet
import Evergreen.V5.RichText
import Evergreen.V5.SecretId
import Evergreen.V5.User
import List.Nonempty
import SeqDict


type alias UserTextMessageData =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V5.Id.Id Evergreen.V5.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V5.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V5.Emoji.Emoji (Evergreen.V5.NonemptySet.NonemptySet (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId))
    , editedAt : Maybe Effect.Time.Posix
    , repliedTo : Maybe Int
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Effect.Time.Posix (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId) (SeqDict.SeqDict Evergreen.V5.Emoji.Emoji (Evergreen.V5.NonemptySet.NonemptySet (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId)))
    | DeletedMessage


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V5.Id.Id Evergreen.V5.Id.UserId
    }


type alias LastTypedAt =
    { time : Effect.Time.Posix
    , messageIndex : Maybe Int
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V5.Id.Id Evergreen.V5.Id.UserId
    , name : Evergreen.V5.ChannelName.ChannelName
    , messages : Array.Array Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId) LastTypedAt
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V5.Id.Id Evergreen.V5.Id.UserId
    , name : Evergreen.V5.GuildName.GuildName
    , icon : Maybe Evergreen.V5.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V5.Id.Id Evergreen.V5.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V5.SecretId.SecretId Evergreen.V5.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V5.Id.Id Evergreen.V5.Id.UserId
            }
    , announcementChannel : Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V5.NonemptyDict.NonemptyDict (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId) Evergreen.V5.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId) Effect.Time.Posix
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V5.Id.Id Evergreen.V5.Id.UserId
    , user : Evergreen.V5.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId) Evergreen.V5.User.FrontendUser
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) FrontendGuild
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V5.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelArchived Archived
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V5.Id.Id Evergreen.V5.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V5.Id.Id Evergreen.V5.Id.UserId
    , name : Evergreen.V5.ChannelName.ChannelName
    , messages : Array.Array Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId) LastTypedAt
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V5.Id.Id Evergreen.V5.Id.UserId
    , name : Evergreen.V5.GuildName.GuildName
    , icon : Maybe Evergreen.V5.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V5.Id.Id Evergreen.V5.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V5.SecretId.SecretId Evergreen.V5.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V5.Id.Id Evergreen.V5.Id.UserId
            }
    , announcementChannel : Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId
    }
