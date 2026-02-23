module Evergreen.V119.Message exposing (..)

import Evergreen.V119.Emoji
import Evergreen.V119.FileStatus
import Evergreen.V119.Id
import Evergreen.V119.NonemptySet
import Evergreen.V119.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V119.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V119.Emoji.Emoji (Evergreen.V119.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V119.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.FileStatus.FileId) Evergreen.V119.FileStatus.FileData
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V119.Emoji.Emoji (Evergreen.V119.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
