module Evergreen.V94.Message exposing (..)

import Evergreen.V94.Emoji
import Evergreen.V94.FileStatus
import Evergreen.V94.Id
import Evergreen.V94.NonemptySet
import Evergreen.V94.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V94.Id.Id Evergreen.V94.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V94.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V94.Emoji.Emoji (Evergreen.V94.NonemptySet.NonemptySet (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V94.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.FileStatus.FileId) Evergreen.V94.FileStatus.FileData
    }


type Message messageId
    = UserTextMessage (UserTextMessageData messageId)
    | UserJoinedMessage Time.Posix (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) (SeqDict.SeqDict Evergreen.V94.Emoji.Emoji (Evergreen.V94.NonemptySet.NonemptySet (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId)))
    | DeletedMessage Time.Posix


type MessageState messageId
    = MessageLoaded (Message messageId)
    | MessageUnloaded
