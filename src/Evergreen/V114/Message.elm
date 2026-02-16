module Evergreen.V114.Message exposing (..)

import Evergreen.V114.Emoji
import Evergreen.V114.FileStatus
import Evergreen.V114.Id
import Evergreen.V114.NonemptySet
import Evergreen.V114.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V114.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V114.Emoji.Emoji (Evergreen.V114.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V114.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.FileStatus.FileId) Evergreen.V114.FileStatus.FileData
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V114.Emoji.Emoji (Evergreen.V114.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
