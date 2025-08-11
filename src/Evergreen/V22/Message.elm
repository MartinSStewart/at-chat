module Evergreen.V22.Message exposing (..)

import Evergreen.V22.Emoji
import Evergreen.V22.FileStatus
import Evergreen.V22.Id
import Evergreen.V22.NonemptySet
import Evergreen.V22.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V22.Id.Id Evergreen.V22.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V22.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V22.Emoji.Emoji (Evergreen.V22.NonemptySet.NonemptySet (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe Int
    , attachedFiles : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.FileStatus.FileId) Evergreen.V22.FileStatus.FileData
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Time.Posix (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) (SeqDict.SeqDict Evergreen.V22.Emoji.Emoji (Evergreen.V22.NonemptySet.NonemptySet (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId)))
    | DeletedMessage
