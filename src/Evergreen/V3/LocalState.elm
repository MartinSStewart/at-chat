module Evergreen.V3.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V3.ChannelName
import Evergreen.V3.Discord.Id
import Evergreen.V3.Emoji
import Evergreen.V3.GuildName
import Evergreen.V3.Id
import Evergreen.V3.Image
import Evergreen.V3.Log
import Evergreen.V3.NonemptyDict
import Evergreen.V3.NonemptySet
import Evergreen.V3.OneToOne
import Evergreen.V3.RichText
import Evergreen.V3.SecretId
import Evergreen.V3.User
import List.Nonempty
import SeqDict


type IsEnabled
    = IsEnabled
    | IsDisabled


type alias UserTextMessageData =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V3.Id.Id Evergreen.V3.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V3.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V3.Emoji.Emoji (Evergreen.V3.NonemptySet.NonemptySet (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId))
    , editedAt : Maybe Effect.Time.Posix
    , repliedTo : Maybe Int
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Effect.Time.Posix (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId) (SeqDict.SeqDict Evergreen.V3.Emoji.Emoji (Evergreen.V3.NonemptySet.NonemptySet (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId)))
    | DeletedMessage


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V3.Id.Id Evergreen.V3.Id.UserId
    }


type alias LastTypedAt =
    { time : Effect.Time.Posix
    , messageIndex : Maybe Int
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V3.Id.Id Evergreen.V3.Id.UserId
    , name : Evergreen.V3.ChannelName.ChannelName
    , messages : Array.Array Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId) LastTypedAt
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V3.Id.Id Evergreen.V3.Id.UserId
    , name : Evergreen.V3.GuildName.GuildName
    , icon : Maybe Evergreen.V3.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V3.Id.Id Evergreen.V3.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V3.SecretId.SecretId Evergreen.V3.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V3.Id.Id Evergreen.V3.Id.UserId
            }
    , announcementChannel : Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V3.NonemptyDict.NonemptyDict (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId) Evergreen.V3.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId) Effect.Time.Posix
    , websocketEnabled : IsEnabled
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V3.Id.Id Evergreen.V3.Id.UserId
    , user : Evergreen.V3.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId) Evergreen.V3.User.FrontendUser
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) FrontendGuild
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V3.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V3.Id.Id Evergreen.V3.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V3.Id.Id Evergreen.V3.Id.UserId
    , name : Evergreen.V3.ChannelName.ChannelName
    , messages : Array.Array Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId) LastTypedAt
    , linkedId : Maybe (Evergreen.V3.Discord.Id.Id Evergreen.V3.Discord.Id.ChannelId)
    , linkedMessageIds : Evergreen.V3.OneToOne.OneToOne (Evergreen.V3.Discord.Id.Id Evergreen.V3.Discord.Id.MessageId) Int
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V3.Id.Id Evergreen.V3.Id.UserId
    , name : Evergreen.V3.GuildName.GuildName
    , icon : Maybe Evergreen.V3.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V3.Id.Id Evergreen.V3.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V3.SecretId.SecretId Evergreen.V3.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V3.Id.Id Evergreen.V3.Id.UserId
            }
    , announcementChannel : Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId
    }
