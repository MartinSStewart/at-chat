module Evergreen.V146.Message exposing (..)

import Evergreen.V146.Emoji
import Evergreen.V146.FileStatus
import Evergreen.V146.Id
import Evergreen.V146.NonemptySet
import Evergreen.V146.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V146.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V146.Emoji.Emoji (Evergreen.V146.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V146.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.FileStatus.FileId) Evergreen.V146.FileStatus.FileData
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V146.Emoji.Emoji (Evergreen.V146.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
