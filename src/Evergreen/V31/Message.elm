module Evergreen.V31.Message exposing (..)

import Evergreen.V31.Emoji
import Evergreen.V31.FileStatus
import Evergreen.V31.Id
import Evergreen.V31.NonemptySet
import Evergreen.V31.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V31.Id.Id Evergreen.V31.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V31.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V31.Emoji.Emoji (Evergreen.V31.NonemptySet.NonemptySet (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe Int
    , attachedFiles : SeqDict.SeqDict (Evergreen.V31.Id.Id Evergreen.V31.FileStatus.FileId) Evergreen.V31.FileStatus.FileData
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Time.Posix (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId) (SeqDict.SeqDict Evergreen.V31.Emoji.Emoji (Evergreen.V31.NonemptySet.NonemptySet (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId)))
    | DeletedMessage
