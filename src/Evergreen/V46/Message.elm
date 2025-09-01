module Evergreen.V46.Message exposing (..)

import Evergreen.V46.Emoji
import Evergreen.V46.FileStatus
import Evergreen.V46.Id
import Evergreen.V46.NonemptySet
import Evergreen.V46.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V46.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V46.Emoji.Emoji (Evergreen.V46.NonemptySet.NonemptySet (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V46.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.FileStatus.FileId) Evergreen.V46.FileStatus.FileData
    }


type Message messageId
    = UserTextMessage (UserTextMessageData messageId)
    | UserJoinedMessage Time.Posix (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) (SeqDict.SeqDict Evergreen.V46.Emoji.Emoji (Evergreen.V46.NonemptySet.NonemptySet (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId)))
    | DeletedMessage Time.Posix
