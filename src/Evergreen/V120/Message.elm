module Evergreen.V120.Message exposing (..)

import Evergreen.V120.Emoji
import Evergreen.V120.FileStatus
import Evergreen.V120.Id
import Evergreen.V120.NonemptySet
import Evergreen.V120.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V120.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V120.Emoji.Emoji (Evergreen.V120.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V120.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.FileStatus.FileId) Evergreen.V120.FileStatus.FileData
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V120.Emoji.Emoji (Evergreen.V120.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
