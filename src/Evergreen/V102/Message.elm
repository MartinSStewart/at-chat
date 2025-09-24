module Evergreen.V102.Message exposing (..)

import Evergreen.V102.Emoji
import Evergreen.V102.FileStatus
import Evergreen.V102.Id
import Evergreen.V102.NonemptySet
import Evergreen.V102.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V102.Id.Id Evergreen.V102.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V102.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V102.Emoji.Emoji (Evergreen.V102.NonemptySet.NonemptySet (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V102.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.FileStatus.FileId) Evergreen.V102.FileStatus.FileData
    }


type Message messageId
    = UserTextMessage (UserTextMessageData messageId)
    | UserJoinedMessage Time.Posix (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) (SeqDict.SeqDict Evergreen.V102.Emoji.Emoji (Evergreen.V102.NonemptySet.NonemptySet (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId)))
    | DeletedMessage Time.Posix


type MessageState messageId
    = MessageLoaded (Message messageId)
    | MessageUnloaded
