module Evergreen.V147.Message exposing (..)

import Evergreen.V147.Emoji
import Evergreen.V147.FileStatus
import Evergreen.V147.Id
import Evergreen.V147.NonemptySet
import Evergreen.V147.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V147.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V147.Emoji.Emoji (Evergreen.V147.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V147.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.FileStatus.FileId) Evergreen.V147.FileStatus.FileData
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V147.Emoji.Emoji (Evergreen.V147.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
