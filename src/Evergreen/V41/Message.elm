module Evergreen.V41.Message exposing (..)

import Evergreen.V41.Emoji
import Evergreen.V41.FileStatus
import Evergreen.V41.Id
import Evergreen.V41.NonemptySet
import Evergreen.V41.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V41.Id.Id Evergreen.V41.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V41.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V41.Emoji.Emoji (Evergreen.V41.NonemptySet.NonemptySet (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.FileStatus.FileId) Evergreen.V41.FileStatus.FileData
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Time.Posix (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) (SeqDict.SeqDict Evergreen.V41.Emoji.Emoji (Evergreen.V41.NonemptySet.NonemptySet (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId)))
    | DeletedMessage Time.Posix
