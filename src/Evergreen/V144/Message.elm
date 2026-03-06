module Evergreen.V144.Message exposing (..)

import Evergreen.V144.Emoji
import Evergreen.V144.FileStatus
import Evergreen.V144.Id
import Evergreen.V144.NonemptySet
import Evergreen.V144.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V144.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V144.Emoji.Emoji (Evergreen.V144.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V144.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.FileStatus.FileId) Evergreen.V144.FileStatus.FileData
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V144.Emoji.Emoji (Evergreen.V144.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
