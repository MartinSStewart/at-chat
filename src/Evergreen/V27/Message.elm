module Evergreen.V27.Message exposing (..)

import Evergreen.V27.Emoji
import Evergreen.V27.FileStatus
import Evergreen.V27.Id
import Evergreen.V27.NonemptySet
import Evergreen.V27.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V27.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V27.Emoji.Emoji (Evergreen.V27.NonemptySet.NonemptySet (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe Int
    , attachedFiles : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.FileStatus.FileId) Evergreen.V27.FileStatus.FileData
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Time.Posix (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) (SeqDict.SeqDict Evergreen.V27.Emoji.Emoji (Evergreen.V27.NonemptySet.NonemptySet (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)))
    | DeletedMessage
