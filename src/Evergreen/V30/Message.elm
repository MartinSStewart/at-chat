module Evergreen.V30.Message exposing (..)

import Evergreen.V30.Emoji
import Evergreen.V30.FileStatus
import Evergreen.V30.Id
import Evergreen.V30.NonemptySet
import Evergreen.V30.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V30.Id.Id Evergreen.V30.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V30.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V30.Emoji.Emoji (Evergreen.V30.NonemptySet.NonemptySet (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe Int
    , attachedFiles : SeqDict.SeqDict (Evergreen.V30.Id.Id Evergreen.V30.FileStatus.FileId) Evergreen.V30.FileStatus.FileData
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Time.Posix (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) (SeqDict.SeqDict Evergreen.V30.Emoji.Emoji (Evergreen.V30.NonemptySet.NonemptySet (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)))
    | DeletedMessage
