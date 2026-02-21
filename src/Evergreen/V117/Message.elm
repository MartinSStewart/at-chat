module Evergreen.V117.Message exposing (..)

import Evergreen.V117.Emoji
import Evergreen.V117.FileStatus
import Evergreen.V117.Id
import Evergreen.V117.NonemptySet
import Evergreen.V117.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V117.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V117.Emoji.Emoji (Evergreen.V117.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V117.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.FileStatus.FileId) Evergreen.V117.FileStatus.FileData
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V117.Emoji.Emoji (Evergreen.V117.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
