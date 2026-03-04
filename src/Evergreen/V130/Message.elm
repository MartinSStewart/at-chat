module Evergreen.V130.Message exposing (..)

import Evergreen.V130.Emoji
import Evergreen.V130.FileStatus
import Evergreen.V130.Id
import Evergreen.V130.NonemptySet
import Evergreen.V130.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V130.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V130.Emoji.Emoji (Evergreen.V130.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V130.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.FileStatus.FileId) Evergreen.V130.FileStatus.FileData
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V130.Emoji.Emoji (Evergreen.V130.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
