module Evergreen.V93.Message exposing (..)

import Evergreen.V93.Emoji
import Evergreen.V93.FileStatus
import Evergreen.V93.Id
import Evergreen.V93.NonemptySet
import Evergreen.V93.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V93.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V93.Emoji.Emoji (Evergreen.V93.NonemptySet.NonemptySet (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V93.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.FileStatus.FileId) Evergreen.V93.FileStatus.FileData
    }


type Message messageId
    = UserTextMessage (UserTextMessageData messageId)
    | UserJoinedMessage Time.Posix (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) (SeqDict.SeqDict Evergreen.V93.Emoji.Emoji (Evergreen.V93.NonemptySet.NonemptySet (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId)))
    | DeletedMessage Time.Posix


type MessageState messageId
    = MessageLoaded (Message messageId)
    | MessageUnloaded
