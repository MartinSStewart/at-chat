module Evergreen.V77.Message exposing (..)

import Evergreen.V77.Emoji
import Evergreen.V77.FileStatus
import Evergreen.V77.Id
import Evergreen.V77.NonemptySet
import Evergreen.V77.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V77.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V77.Emoji.Emoji (Evergreen.V77.NonemptySet.NonemptySet (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V77.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.FileStatus.FileId) Evergreen.V77.FileStatus.FileData
    }


type Message messageId
    = UserTextMessage (UserTextMessageData messageId)
    | UserJoinedMessage Time.Posix (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) (SeqDict.SeqDict Evergreen.V77.Emoji.Emoji (Evergreen.V77.NonemptySet.NonemptySet (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId)))
    | DeletedMessage Time.Posix


type MessageState messageId
    = MessageLoaded (Message messageId)
    | MessageUnloaded
