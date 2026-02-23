module Evergreen.V118.Message exposing (..)

import Evergreen.V118.Emoji
import Evergreen.V118.FileStatus
import Evergreen.V118.Id
import Evergreen.V118.NonemptySet
import Evergreen.V118.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V118.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V118.Emoji.Emoji (Evergreen.V118.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V118.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.FileStatus.FileId) Evergreen.V118.FileStatus.FileData
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V118.Emoji.Emoji (Evergreen.V118.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
