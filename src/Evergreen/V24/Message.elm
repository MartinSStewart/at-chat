module Evergreen.V24.Message exposing (..)

import Evergreen.V24.Emoji
import Evergreen.V24.FileStatus
import Evergreen.V24.Id
import Evergreen.V24.NonemptySet
import Evergreen.V24.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V24.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V24.Emoji.Emoji (Evergreen.V24.NonemptySet.NonemptySet (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe Int
    , attachedFiles : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.FileStatus.FileId) Evergreen.V24.FileStatus.FileData
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Time.Posix (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) (SeqDict.SeqDict Evergreen.V24.Emoji.Emoji (Evergreen.V24.NonemptySet.NonemptySet (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId)))
    | DeletedMessage
