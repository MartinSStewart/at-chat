module Evergreen.V33.Message exposing (..)

import Evergreen.V33.Emoji
import Evergreen.V33.FileStatus
import Evergreen.V33.Id
import Evergreen.V33.NonemptySet
import Evergreen.V33.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V33.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V33.Emoji.Emoji (Evergreen.V33.NonemptySet.NonemptySet (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe Int
    , attachedFiles : SeqDict.SeqDict (Evergreen.V33.Id.Id Evergreen.V33.FileStatus.FileId) Evergreen.V33.FileStatus.FileData
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Time.Posix (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) (SeqDict.SeqDict Evergreen.V33.Emoji.Emoji (Evergreen.V33.NonemptySet.NonemptySet (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId)))
    | DeletedMessage Time.Posix
