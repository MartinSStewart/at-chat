module Evergreen.V14.LocalState exposing (..)

import Array
import Effect.Time
import Evergreen.V14.ChannelName
import Evergreen.V14.Discord.Id
import Evergreen.V14.Emoji
import Evergreen.V14.GuildName
import Evergreen.V14.Id
import Evergreen.V14.Image
import Evergreen.V14.Log
import Evergreen.V14.NonemptyDict
import Evergreen.V14.NonemptySet
import Evergreen.V14.OneToOne
import Evergreen.V14.RichText
import Evergreen.V14.SecretId
import Evergreen.V14.User
import List.Nonempty
import SeqDict


type IsEnabled
    = IsEnabled
    | IsDisabled


type alias UserTextMessageData =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V14.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V14.Emoji.Emoji (Evergreen.V14.NonemptySet.NonemptySet (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId))
    , editedAt : Maybe Effect.Time.Posix
    , repliedTo : Maybe Int
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Effect.Time.Posix (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId) (SeqDict.SeqDict Evergreen.V14.Emoji.Emoji (Evergreen.V14.NonemptySet.NonemptySet (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId)))
    | DeletedMessage


type alias Archived =
    { archivedAt : Effect.Time.Posix
    , archivedBy : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
    }


type alias LastTypedAt =
    { time : Effect.Time.Posix
    , messageIndex : Maybe Int
    }


type alias FrontendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
    , name : Evergreen.V14.ChannelName.ChannelName
    , messages : Array.Array Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId) LastTypedAt
    , linkedMessageIds : Evergreen.V14.OneToOne.OneToOne (Evergreen.V14.Discord.Id.Id Evergreen.V14.Discord.Id.MessageId) Int
    }


type alias FrontendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
    , name : Evergreen.V14.GuildName.GuildName
    , icon : Maybe Evergreen.V14.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId) FrontendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V14.SecretId.SecretId Evergreen.V14.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
            }
    , announcementChannel : Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias AdminData =
    { users : Evergreen.V14.NonemptyDict.NonemptyDict (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId) Evergreen.V14.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId) Effect.Time.Posix
    , websocketEnabled : IsEnabled
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LocalUser =
    { userId : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
    , user : Evergreen.V14.User.BackendUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId) Evergreen.V14.User.FrontendUser
    }


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict.SeqDict (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) FrontendGuild
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    }


type alias LogWithTime =
    { time : Effect.Time.Posix
    , log : Evergreen.V14.Log.Log
    }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted
        { deletedAt : Effect.Time.Posix
        , deletedBy : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
        }


type alias BackendChannel =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
    , name : Evergreen.V14.ChannelName.ChannelName
    , messages : Array.Array Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId) LastTypedAt
    , linkedId : Maybe (Evergreen.V14.Discord.Id.Id Evergreen.V14.Discord.Id.ChannelId)
    , linkedMessageIds : Evergreen.V14.OneToOne.OneToOne (Evergreen.V14.Discord.Id.Id Evergreen.V14.Discord.Id.MessageId) Int
    }


type alias BackendGuild =
    { createdAt : Effect.Time.Posix
    , createdBy : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
    , name : Evergreen.V14.GuildName.GuildName
    , icon : Maybe Evergreen.V14.Image.Image
    , channels : SeqDict.SeqDict (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId) BackendChannel
    , members :
        SeqDict.SeqDict
            (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId)
            { joinedAt : Effect.Time.Posix
            }
    , owner : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
    , invites :
        SeqDict.SeqDict
            (Evergreen.V14.SecretId.SecretId Evergreen.V14.Id.InviteLinkId)
            { createdAt : Effect.Time.Posix
            , createdBy : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
            }
    , announcementChannel : Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId
    }
