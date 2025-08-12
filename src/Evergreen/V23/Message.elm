module Evergreen.V23.Message exposing (..)

import Evergreen.V23.Emoji
import Evergreen.V23.FileStatus
import Evergreen.V23.Id
import Evergreen.V23.NonemptySet
import Evergreen.V23.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V23.Id.Id Evergreen.V23.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V23.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V23.Emoji.Emoji (Evergreen.V23.NonemptySet.NonemptySet (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe Int
    , attachedFiles : SeqDict.SeqDict (Evergreen.V23.Id.Id Evergreen.V23.FileStatus.FileId) Evergreen.V23.FileStatus.FileData
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Time.Posix (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) (SeqDict.SeqDict Evergreen.V23.Emoji.Emoji (Evergreen.V23.NonemptySet.NonemptySet (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId)))
    | DeletedMessage
