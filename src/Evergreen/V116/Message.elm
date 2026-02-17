module Evergreen.V116.Message exposing (..)

import Evergreen.V116.Emoji
import Evergreen.V116.FileStatus
import Evergreen.V116.Id
import Evergreen.V116.NonemptySet
import Evergreen.V116.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V116.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V116.Emoji.Emoji (Evergreen.V116.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V116.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.FileStatus.FileId) Evergreen.V116.FileStatus.FileData
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V116.Emoji.Emoji (Evergreen.V116.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
