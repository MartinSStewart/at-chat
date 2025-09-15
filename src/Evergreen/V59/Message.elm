module Evergreen.V59.Message exposing (..)

import Evergreen.V59.Emoji
import Evergreen.V59.FileStatus
import Evergreen.V59.Id
import Evergreen.V59.NonemptySet
import Evergreen.V59.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V59.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V59.Emoji.Emoji (Evergreen.V59.NonemptySet.NonemptySet (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V59.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.FileStatus.FileId) Evergreen.V59.FileStatus.FileData
    }


type Message messageId
    = UserTextMessage (UserTextMessageData messageId)
    | UserJoinedMessage Time.Posix (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) (SeqDict.SeqDict Evergreen.V59.Emoji.Emoji (Evergreen.V59.NonemptySet.NonemptySet (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId)))
    | DeletedMessage Time.Posix


type MessageState messageId
    = MessageLoaded (Message messageId)
    | MessageUnloaded
