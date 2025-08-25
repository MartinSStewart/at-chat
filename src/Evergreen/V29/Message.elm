module Evergreen.V29.Message exposing (..)

import Evergreen.V29.Emoji
import Evergreen.V29.FileStatus
import Evergreen.V29.Id
import Evergreen.V29.NonemptySet
import Evergreen.V29.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V29.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V29.Emoji.Emoji (Evergreen.V29.NonemptySet.NonemptySet (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe Int
    , attachedFiles : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.FileStatus.FileId) Evergreen.V29.FileStatus.FileData
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Time.Posix (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) (SeqDict.SeqDict Evergreen.V29.Emoji.Emoji (Evergreen.V29.NonemptySet.NonemptySet (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)))
    | DeletedMessage
