module Evergreen.V26.Message exposing (..)

import Evergreen.V26.Emoji
import Evergreen.V26.FileStatus
import Evergreen.V26.Id
import Evergreen.V26.NonemptySet
import Evergreen.V26.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V26.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V26.Emoji.Emoji (Evergreen.V26.NonemptySet.NonemptySet (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe Int
    , attachedFiles : SeqDict.SeqDict (Evergreen.V26.Id.Id Evergreen.V26.FileStatus.FileId) Evergreen.V26.FileStatus.FileData
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Time.Posix (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) (SeqDict.SeqDict Evergreen.V26.Emoji.Emoji (Evergreen.V26.NonemptySet.NonemptySet (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId)))
    | DeletedMessage
