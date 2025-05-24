module Evergreen.V12.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V12.ChannelName
import Evergreen.V12.Emoji
import Evergreen.V12.GuildName
import Evergreen.V12.Id
import Evergreen.V12.Image
import Evergreen.V12.Log
import Evergreen.V12.NonemptyDict
import Evergreen.V12.NonemptySet
import Evergreen.V12.RichText
import Evergreen.V12.SecretId
import Evergreen.V12.User
import List.Nonempty
import SeqDict


type alias UserTextMessageData =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V12.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V12.Emoji.Emoji (Evergreen.V12.NonemptySet.NonemptySet (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId))
    , editedAt : Maybe Effect.Time.Posix
    , repliedTo : Maybe Int
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Effect.Time.Posix (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) (SeqDict.SeqDict Evergreen.V12.Emoji.Emoji (Evergreen.V12.NonemptySet.NonemptySet (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId)))
    | DeletedMessage


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
    }


type alias LastTypedAt =
    { time : Effect.Time.Posix
    , messageIndex : Maybe Int
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
    , name : Evergreen.V12.ChannelName.ChannelName
    , messages : Array.Array Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) LastTypedAt
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
    , name : Evergreen.V12.GuildName.GuildName
    , icon : Maybe Evergreen.V12.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V12.SecretId.SecretId Evergreen.V12.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
            }
    , announcementChannel : Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V12.NonemptyDict.NonemptyDict (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) Evergreen.V12.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) Effect.Time.Posix
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
    , user : Evergreen.V12.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) Evergreen.V12.User.FrontendUser
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) FrontendGuild
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V12.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelArchived Archived
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
    , name : Evergreen.V12.ChannelName.ChannelName
    , messages : Array.Array Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) LastTypedAt
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
    , name : Evergreen.V12.GuildName.GuildName
    , icon : Maybe Evergreen.V12.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V12.SecretId.SecretId Evergreen.V12.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
            }
    , announcementChannel : Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId
    }
